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

// Environment key for SubscriptionStore
private struct SubscriptionStoreKey: EnvironmentKey {
    @MainActor static let defaultValue: SubscriptionStore = SubscriptionStore()
}

extension EnvironmentValues {
    var subscriptionStore: SubscriptionStore {
        get { self[SubscriptionStoreKey.self] }
        set { self[SubscriptionStoreKey.self] = newValue }
    }
}

// Environment key for SyncStore
private struct SyncStoreKey: EnvironmentKey {
    @MainActor static let defaultValue: SyncStore = SyncStore()
}

extension EnvironmentValues {
    var syncStore: SyncStore {
        get { self[SyncStoreKey.self] }
        set { self[SyncStoreKey.self] = newValue }
    }
}
