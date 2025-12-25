//
//  AppStoreEnvironment.swift
//  Fieldnote
//
//  Environment key for AppStore
//

import SwiftUI
import SwiftData

// Environment key for AppStore
// Note: AppStore is injected at app level with actual ModelContext
private struct AppStoreKey: EnvironmentKey {
    @MainActor static let defaultValue: AppStore? = nil
}

extension EnvironmentValues {
    var appStore: AppStore? {
        get { self[AppStoreKey.self] }
        set { self[AppStoreKey.self] = newValue }
    }
}
