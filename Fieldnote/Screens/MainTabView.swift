//
//  MainTabView.swift
//  Fieldnote
//
//  Root tab navigation with 4 tabs
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.appStore) private var store

    private var appStore: AppStore {
        guard let store = store else {
            fatalError("AppStore not found in environment")
        }
        return store
    }

    var body: some View {
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
