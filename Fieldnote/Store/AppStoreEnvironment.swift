//
//  AppStoreEnvironment.swift
//  Fieldnote
//
//  Environment key for AppStore
//

import SwiftUI

// Environment key for AppStore
private struct AppStoreKey: EnvironmentKey {
    static let defaultValue = AppStore()
}

extension EnvironmentValues {
    var appStore: AppStore {
        get { self[AppStoreKey.self] }
        set { self[AppStoreKey.self] = newValue }
    }
}
