//
//  MainTabView.swift
//  Fieldnote
//
//  Root tab navigation with 4 tabs
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.appStore) private var store

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

            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
        .tint(FieldColor.accent)
    }
}
