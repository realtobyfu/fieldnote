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

// Environment key for OnboardingStore
private struct OnboardingStoreKey: EnvironmentKey {
    @MainActor static let defaultValue: OnboardingStore = OnboardingStore()
}

extension EnvironmentValues {
    var onboardingStore: OnboardingStore {
        get { self[OnboardingStoreKey.self] }
        set { self[OnboardingStoreKey.self] = newValue }
    }
}
