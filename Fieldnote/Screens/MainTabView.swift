//
//  MainTabView.swift
//  Fieldnote
//
//  Root tab navigation with 4 tabs
//

import SwiftUI

struct MainTabView: View {
    @State private var store = AppStore()

    var body: some View {
        TabView {
            // Library Tab
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "book.fill")
            }

            // Capture Tab
            NavigationStack {
                CaptureView()
            }
            .tabItem {
                Label("Capture", systemImage: "camera.fill")
            }

            // Explore Tab
            NavigationStack {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "safari.fill")
            }

            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .environment(\.appStore, store)
        .tint(FieldColor.accent)
    }
}

#Preview {
    MainTabView()
}
