//
//  MainTabView.swift
//  Fieldnote
//
//  Root tab navigation with 4 tabs
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.appStore) private var store
    private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if let appStore = store {
            mainContent(appStore: appStore)
        } else {
            ContentUnavailableView(
                "Unable to Load",
                systemImage: "exclamationmark.triangle",
                description: Text("Please restart the app.")
            )
        }
    }

    @ViewBuilder
    private func mainContent(appStore: AppStore) -> some View {
        ZStack(alignment: .top) {
            TabView(selection: Binding(
                get: { appStore.selectedTab },
                set: { appStore.selectedTab = $0 }
            )) {
                // Library Tab
                NavigationStack {
                    LibraryView()
                }
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
                .tag(Tab.library)

                // Capture Tab
                NavigationStack {
                    CaptureView()
                }
                .tabItem {
                    Label("Capture", systemImage: "camera.fill")
                }
                .tag(Tab.capture)

                // Explore Tab
                NavigationStack {
                    ExploreView()
                }
                .tabItem {
                    Label("Explore", systemImage: "safari.fill")
                }
                .tag(Tab.explore)

                // Profile Tab
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(Tab.profile)
            }
            .tint(FieldColor.accent)

            // Offline banner
//            if !networkMonitor.isConnected {
//                OfflineBanner()
//                    .transition(.move(edge: .top).combined(with: .opacity))
//            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

// MARK: - Offline Banner

private struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: FieldSpace.xs) {
            Image(systemName: "wifi.slash")
                .font(.caption)

            Text("You're offline")
                .font(FieldType.caption)

            Text("•")
                .font(FieldType.caption)

            Text("Data saved locally")
                .font(FieldType.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, FieldSpace.md)
        .padding(.vertical, FieldSpace.xs)
        .frame(maxWidth: .infinity)
        .background(FieldColor.mutedInk)
    }
}
