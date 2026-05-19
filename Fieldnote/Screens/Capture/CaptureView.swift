//
//  CaptureView.swift
//  Fieldnote
//
//  Capture screen with animated shutter camera button
//

import SwiftUI
import PhotosUI
import SwiftData

@MainActor
struct CaptureView: View {
    @Environment(\.appStore) private var store
    @Environment(\.subscriptionStore) private var subscriptionStore
    @State private var viewModel: CaptureViewModel
    
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var shutterExpanding = false

    init() {
        _viewModel = State(initialValue: CaptureViewModel())
    }

    init(viewModel: CaptureViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let appStore = store {
                captureContent(appStore: appStore)
            } else {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app.")
                )
            }
        }
        .navigationTitle("Capture")
        .onChange(of: viewModel.selectedItem) { _, _ in
            Task {
                await viewModel.loadPhoto(subscriptionStore: subscriptionStore)
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                Task {
                    await viewModel.handleCapturedImage(image, subscriptionStore: subscriptionStore)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            showCamera = false
            shutterExpanding = false
        } content: {
            CameraView(capturedImage: $capturedImage)
                .environment(\.appStore, store)
                .ignoresSafeArea()
        }
        .sheet(item: $viewModel.destination) { destination in
            switch destination {
            case .review(let mode):
                if let appStore = store {
                    CaptureReviewSheet(
                        viewModel: viewModel,
                        store: appStore,
                        captureMode: mode
                    )
                    .environment(\.appStore, store)
                }
            case .paywall:
                PaywallView()
                    .environment(\.subscriptionStore, subscriptionStore)
            }
        }
        .onChange(of: viewModel.destination?.id) { oldID, newID in
            guard newID == nil else { return }
            switch oldID {
            case "review":
                shutterExpanding = false
                capturedImage = nil
            case "paywall":
                if subscriptionStore.canUseAIIdentification {
                    Task {
                        await viewModel.retryPendingIdentification(subscriptionStore: subscriptionStore)
                    }
                }
            default:
                break
            }
        }
    }

    @ViewBuilder
    private func captureContent(appStore: AppStore) -> some View {
        GeometryReader { geometry in
            ZStack {
                mainContent(appStore: appStore, geometry: geometry)
                shutterOverlay(geometry: geometry)

                if viewModel.isIdentifying {
                    identifyingOverlay
                }
            }
            .background(FieldColor.paper)
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(appStore: AppStore, geometry: GeometryProxy) -> some View {
        VStack(spacing: FieldSpace.xl) {
            Spacer()

            VStack(spacing: FieldSpace.md) {
                decorativeEmblem

                VStack(spacing: FieldSpace.xs) {
                    Text("Capture a Plant")
                        .font(FieldType.title2)
                        .foregroundColor(FieldColor.ink)

                    Text("Identify or log a plant you've found")
                        .font(FieldType.body)
                        .foregroundColor(FieldColor.mutedInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FieldSpace.xl)
                }
            }

            VStack(spacing: FieldSpace.md) {
                // Take Photo (PRIMARY)
                if CameraView.isAvailable {
                    Button {
                        triggerShutter(geometry: geometry)
                    } label: {
                        Text("Take Photo")
                            .font(FieldType.buttonLabel)
                            .foregroundColor(.white)
                            .frame(maxWidth: 280)
                            .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                            .background(FieldColor.accent)
                            .cornerRadius(FieldRadius.button)
                    }
                    .opacity(shutterExpanding ? 0 : 1)
                }

                // Choose from Library (SECONDARY)
                PhotosPicker(
                    selection: $viewModel.selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .font(FieldType.buttonLabel)
                        .foregroundColor(FieldColor.accent)
                        .frame(maxWidth: 280)
                        .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                        .background(
                            RoundedRectangle(cornerRadius: FieldRadius.button)
                                .stroke(FieldColor.accent, lineWidth: 1.5)
                        )
                }

                // Manual Entry (TERTIARY)
                Button {
                    viewModel.startManualEntry()
                } label: {
                    Label("Manual Entry", systemImage: "pencil.line")
                        .font(FieldType.buttonLabel)
                        .foregroundColor(FieldColor.mutedInk)
                        .frame(maxWidth: 280)
                        .padding(.vertical, FieldSpace.sm)
                }
            }

            // Recent captures hint
            if !appStore.allEncounters.isEmpty {
                Text("\(appStore.allEncounters.count) total observations")
                    .font(FieldType.footnote)
                    .foregroundColor(FieldColor.mutedInk)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var decorativeEmblem: some View {
        ZStack {
            Circle()
                .fill(FieldColor.accent.opacity(0.12))
                .frame(width: 76, height: 76)

            Image(systemName: "camera.fill")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(FieldColor.accent.opacity(0.85))
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var instructionsSection: some View {
        VStack(spacing: FieldSpace.sm) {
            Text("Capture a Plant")
                .font(FieldType.title2)
                .foregroundColor(FieldColor.ink)

            Text("Tap the camera to begin")
                .font(FieldType.callout)
                .foregroundColor(FieldColor.mutedInk)
        }
        .opacity(shutterExpanding ? 0 : 1)
    }

    private var libraryPickerSection: some View {
        PhotosPicker(
            selection: $viewModel.selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack(spacing: FieldSpace.xs) {
                Image(systemName: "photo.on.rectangle")
                Text("Choose from Library")
            }
            .font(FieldType.callout)
            .foregroundColor(FieldColor.mutedInk)
        }
        .opacity(shutterExpanding ? 0 : 1)
        .padding(.bottom, FieldSpace.xl)
    }

    // MARK: - Identifying Overlay

    private var identifyingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: FieldSpace.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Identifying plant...")
                    .font(FieldType.body)
                    .foregroundColor(.white)
            }
            .padding(FieldSpace.xl)
            .background(
                RoundedRectangle(cornerRadius: FieldRadius.lg)
                    .fill(FieldColor.ink.opacity(0.9))
            )
        }
    }

    // MARK: - Shutter Overlay

    @ViewBuilder
    private func shutterOverlay(geometry: GeometryProxy) -> some View {
        if shutterExpanding {
            let size = max(geometry.size.width, geometry.size.height) * 2.5
            Circle()
                .fill(FieldColor.ink)
                .frame(width: size, height: size)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
        }
    }

    // MARK: - Actions

    private func triggerShutter(geometry: GeometryProxy) {
        // Haptic feedback for camera shutter
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(.easeInOut(duration: 0.35)) {
            shutterExpanding = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showCamera = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                shutterExpanding = false
            }
        }
    }
}

#if DEBUG
@MainActor
private enum CapturePreviewData {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Plant.self, Encounter.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try! ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeAppStore(container: ModelContainer) -> AppStore {
        let context = container.mainContext
        for plant in Plant.mockPlants {
            context.insert(plant)
        }
        return AppStore(modelContext: context)
    }

    static func makeFreeSubscriptionStore() -> SubscriptionStore {
        let store = SubscriptionStore()
        store.aiIdentificationsUsed = 0
        store.subscriptionType = .none
        store.subscriptionExpirationDate = nil
        store.hasSeenPremiumPromo = false
        return store
    }
}

@MainActor
private enum CapturePreviewModels {
    static func idle() -> CaptureViewModel {
        CaptureViewModel()
    }

    static func identifying() -> CaptureViewModel {
        let viewModel = CaptureViewModel()
        viewModel.isIdentifying = true
        return viewModel
    }

    static func manualReview() -> CaptureViewModel {
        let viewModel = CaptureViewModel()
        viewModel.destination = .review(.manualEntry)
        return viewModel
    }

    static func aiReview() -> CaptureViewModel {
        let viewModel = CaptureViewModel()
        viewModel.destination = .review(.mlIdentification(
            result: PlantIdentificationResult(
                commonName: "Common Dandelion",
                scientificName: "Taraxacum officinale",
                family: "Asteraceae",
                confidence: 0.92
            ),
            image: UIImage(systemName: "leaf.fill")!
        ))
        return viewModel
    }

    static func paywall() -> CaptureViewModel {
        let viewModel = CaptureViewModel()
        viewModel.destination = .paywall
        return viewModel
    }
}

private struct CapturePreviewHost: View {
    @State private var appStore: AppStore
    @State private var subscriptionStore: SubscriptionStore

    private let container: ModelContainer
    private let viewModel: CaptureViewModel

    @MainActor
    init(viewModel: CaptureViewModel) {
        let container = CapturePreviewData.makeContainer()
        self.container = container
        self.viewModel = viewModel
        _appStore = State(initialValue: CapturePreviewData.makeAppStore(container: container))
        _subscriptionStore = State(initialValue: CapturePreviewData.makeFreeSubscriptionStore())
    }

    @MainActor
    init(viewModel: CaptureViewModel, subscriptionStore: SubscriptionStore) {
        let container = CapturePreviewData.makeContainer()
        self.container = container
        self.viewModel = viewModel
        _appStore = State(initialValue: CapturePreviewData.makeAppStore(container: container))
        _subscriptionStore = State(initialValue: subscriptionStore)
    }

    var body: some View {
        NavigationStack {
            CaptureView(viewModel: viewModel)
        }
        .environment(\.appStore, appStore)
        .environment(\.subscriptionStore, subscriptionStore)
        .modelContainer(container)
    }
}

#Preview("Idle") {
    CapturePreviewHost(viewModel: CapturePreviewModels.idle())
}

#Preview("Identifying") {
    CapturePreviewHost(viewModel: CapturePreviewModels.identifying())
}

#Preview("Manual Review") {
    CapturePreviewHost(viewModel: CapturePreviewModels.manualReview())
}

#Preview("AI Review") {
    CapturePreviewHost(viewModel: CapturePreviewModels.aiReview())
}

#Preview("Paywall") {
    CapturePreviewHost(viewModel: CapturePreviewModels.paywall())
}
#endif
