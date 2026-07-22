//
//  MainTabView.swift
//  Fieldnote
//
//  Root shell with a custom glass-capsule tab bar (FieldTabBar). The Capture FAB
//  jumps straight to the camera — the old take-photo/choose-library chooser screen
//  is retired; library + manual entry live in the FAB's long-press menu.
//

import SwiftUI
import PhotosUI

struct MainTabView: View {
    @Environment(\.appStore) private var store
    @Environment(\.subscriptionStore) private var subscriptionStore

    @State private var viewModel = CaptureViewModel()
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var capturedImage: UIImage?
    @State private var postCameraAction: PostCameraAction?
    @State private var tabBar = TabBarVisibility()
    @State private var journalPath = NavigationPath()
    @State private var explorePath = NavigationPath()
    @State private var mapPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    @State private var tabBarClearance: CGFloat = 84
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Follow-up chosen inside the camera (library / manual entry) — run after
    /// the full-screen cover finishes dismissing so the next presentation lands.
    private enum PostCameraAction {
        case library
        case manualEntry
    }
    @Namespace private var tabNamespace

    var body: some View {
        if let appStore = store {
            content(appStore)
        } else {
            ContentUnavailableView(
                "Unable to Load",
                systemImage: "exclamationmark.triangle",
                description: Text("Please restart the app.")
            )
        }
    }

    // MARK: - Shell

    private func content(_ appStore: AppStore) -> some View {
        ZStack(alignment: .bottom) {
            tabContent(appStore)

            // The visible bar remains an overlay, while each active root screen
            // receives an equal measured inset inside its NavigationStack below.
            // That makes ScrollView's maximum offset include the full floating bar.
            if shouldShowTabBar(appStore) {
                fieldTabBar(appStore)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        guard abs(height - tabBarClearance) > 0.5 else { return }
                        tabBarClearance = height
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
            .animation(
                reduceMotion ? nil : .snappy(duration: 0.34),
                value: shouldShowTabBar(appStore)
            )
            .onChange(of: appStore.selectedTab) { _, newTab in
                if newTab == .capture { handleCaptureSelection(appStore) }
            }
            .onChange(of: capturedImage) { _, image in
                if let image {
                    Task { await viewModel.handleCapturedImage(image, subscriptionStore: subscriptionStore) }
                }
            }
            .onChange(of: viewModel.selectedItem) { _, _ in
                Task { await viewModel.loadPhoto(subscriptionStore: subscriptionStore) }
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: runPostCameraAction) {
                FieldCameraView(
                    onUsePhoto: { capturedImage = $0 },
                    onPickLibrary: { postCameraAction = .library },
                    onManualEntry: { postCameraAction = .manualEntry }
                )
            }
            .photosPicker(
                isPresented: $showLibrary,
                selection: $viewModel.selectedItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .sheet(item: $viewModel.destination) { destination in
                switch destination {
                case .review(let mode):
                    CaptureReviewSheet(viewModel: viewModel, store: appStore, captureMode: mode)
                        .environment(\.appStore, store)
                case .paywall:
                    PaywallView()
                        .environment(\.subscriptionStore, subscriptionStore)
                }
            }
            .onChange(of: viewModel.destination?.id) { oldID, newID in
                guard newID == nil else { return }
                if oldID == "review" {
                    capturedImage = nil
                } else if oldID == "paywall", subscriptionStore.canUseAIIdentification {
                    Task { await viewModel.retryPendingIdentification(subscriptionStore: subscriptionStore) }
                }
            }
    }

    private func fieldTabBar(_ appStore: AppStore) -> some View {
        FieldTabBar(
            selection: Binding(
                get: { appStore.selectedTab },
                set: { appStore.selectedTab = $0 }
            ),
            collapsed: tabBar.collapsed,
            onCapture: { startCamera() },
            onCaptureLibrary: { showLibrary = true },
            onManualEntry: { viewModel.startManualEntry() },
            namespace: tabNamespace
        )
        .padding(.horizontal, FieldSpace.md)
        .padding(.bottom, FieldSpace.sm)
        // Nudge the bar down toward the bottom edge — floating a full safe-area
        // inset above the home indicator read as too high. `offset` moves it
        // visually without changing the measured height used for content
        // clearance (see `onGeometryChange` in `content`).
        .offset(y: tabBarLowering)
        // Keep the bar pinned under the keyboard without disabling keyboard
        // avoidance for tab content.
        .ignoresSafeArea(.keyboard)
    }

    /// How far to drop the floating tab bar toward the bottom edge, past the
    /// bottom safe-area inset, while keeping clearance for the home indicator.
    private let tabBarLowering: CGFloat = 24

    // MARK: - Tab content (state-preserving)

    @ViewBuilder
    private func tabContent(_ appStore: AppStore) -> some View {
        ZStack {
            tabStack(appStore, .journal, path: $journalPath) { JournalView() }
            tabStack(appStore, .explore, path: $explorePath) { ExploreView() }
            // The map stays full-bleed under the floating bar by design.
            // (Plant destination is registered inside LocationMapView itself.)
            tabStack(appStore, .map, path: $mapPath) {
                LocationMapView()
            }
            tabStack(appStore, .profile, path: $profilePath) { ProfileView() }
        }
        .environment(tabBar)
    }

    @ViewBuilder
    private func tabStack<C: View>(
        _ appStore: AppStore,
        _ tab: AppTab,
        path: Binding<NavigationPath>,
        @ViewBuilder _ content: () -> C
    ) -> some View {
        // `.capture` is an action, not a rendered tab — keep Journal visible under it.
        let active = appStore.selectedTab == tab
            || (tab == .journal && appStore.selectedTab == .capture)
        NavigationStack(path: path) {
            content()
                // This inset belongs to the actual root screen, not the outer
                // stack-of-stacks shell. Its clear region becomes real scroll
                // extent, so the final control can move above the floating bar.
                .safeAreaInset(edge: .bottom, spacing: FieldSpace.sm) {
                    Color.clear
                        .frame(height: active && shouldShowTabBar(appStore) ? tabBarClearance : 0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
        }
            .collapsesTabBarOnScroll()
            .opacity(active ? 1 : 0)
            .allowsHitTesting(active)
            .zIndex(active ? 1 : 0)
    }

    private func shouldShowTabBar(_ appStore: AppStore) -> Bool {
        guard !tabBar.suppressed else { return false }

        switch appStore.selectedTab {
        case .journal, .capture:
            return journalPath.isEmpty
        case .explore:
            return explorePath.isEmpty
        case .map:
            return mapPath.isEmpty
        case .profile:
            return profilePath.isEmpty
        }
    }

    // MARK: - Capture

    private func startCamera() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showCamera = true
    }

    private func runPostCameraAction() {
        guard let action = postCameraAction else { return }
        postCameraAction = nil
        switch action {
        case .library:
            showLibrary = true
        case .manualEntry:
            viewModel.startManualEntry()
        }
    }

    /// Handles `selectedTab == .capture` set by empty-state buttons (and the
    /// DEBUG SEED_REVIEW launch hook). Capture is an action, so bounce back to Journal.
    private func handleCaptureSelection(_ appStore: AppStore) {
        #if DEBUG
        if presentDebugReviewIfRequested() {
            appStore.selectedTab = .journal
            return
        }
        #endif
        appStore.selectedTab = .journal
        startCamera()
    }

    // MARK: - DEBUG review hook

    #if DEBUG
    /// Presents the review sheet on launch when `SEED_REVIEW=ai|manual` is set
    /// (used for screenshots). Returns true if it handled the request.
    @discardableResult
    private func presentDebugReviewIfRequested() -> Bool {
        guard viewModel.destination == nil,
              let mode = ProcessInfo.processInfo.environment["SEED_REVIEW"] else { return false }
        switch mode {
        case "ai":
            viewModel.destination = .review(.mlIdentification(
                result: PlantIdentificationResult(
                    commonName: "Red Maple", scientificName: "Acer rubrum",
                    family: "Sapindaceae", confidence: 0.92
                ),
                image: debugSampleImage()
            ))
            return true
        case "manual":
            viewModel.destination = .review(.manualEntry)
            return true
        default:
            return false
        }
    }

    private func debugSampleImage() -> UIImage {
        let size = CGSize(width: 800, height: 800)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [
                UIColor(red: 0.30, green: 0.46, blue: 0.32, alpha: 1).cgColor,
                UIColor(red: 0.12, green: 0.20, blue: 0.13, alpha: 1).cgColor
            ]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray, locations: [0, 1]
            ) else { return }
            ctx.cgContext.drawLinearGradient(
                gradient, start: .zero,
                end: CGPoint(x: size.width, y: size.height), options: []
            )
        }
    }
    #endif
}
