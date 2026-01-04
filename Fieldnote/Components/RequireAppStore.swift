//
//  RequireAppStore.swift
//  Fieldnote
//
//  Helper to safely unwrap AppStore from environment
//

import SwiftUI

struct RequireAppStore<Content: View>: View {
    @Environment(\.appStore) private var store
    let content: (AppStore) -> Content

    init(@ViewBuilder content: @escaping (AppStore) -> Content) {
        self.content = content
    }

    var body: some View {
        if let store = store {
            content(store)
        } else {
            // Fallback view - should never happen in production
            ContentUnavailableView(
                "Unable to Load",
                systemImage: "exclamationmark.triangle",
                description: Text("Please restart the app.")
            )
        }
    }
}
