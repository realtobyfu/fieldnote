//
//  SubscriptionStore.swift
//  Fieldnote
//
//  Manages subscription status and AI identification usage tracking
//

import Foundation
import SwiftUI

/// Subscription plan types
enum SubscriptionType: String, Codable {
    case none
    case annual
    case lifetime
}

@MainActor
@Observable
class SubscriptionStore {
    // MARK: - Constants

    static let freeIdentificationLimit = 10

    // MARK: - Keys

    private enum Keys {
        static let aiIdentificationsUsed = "aiIdentificationsUsed"
        static let subscriptionType = "subscriptionType"
        static let subscriptionExpirationDate = "subscriptionExpirationDate"
        static let hasSeenPremiumPromo = "hasSeenPremiumPromo"
    }

    // MARK: - Observable State

    /// Number of AI identifications used (persisted)
    var aiIdentificationsUsed: Int {
        didSet {
            UserDefaults.standard.set(aiIdentificationsUsed, forKey: Keys.aiIdentificationsUsed)
        }
    }

    /// Current subscription type (persisted)
    var subscriptionType: SubscriptionType {
        didSet {
            UserDefaults.standard.set(subscriptionType.rawValue, forKey: Keys.subscriptionType)
        }
    }

    /// Subscription expiration date for annual plans (persisted)
    var subscriptionExpirationDate: Date? {
        didSet {
            UserDefaults.standard.set(subscriptionExpirationDate, forKey: Keys.subscriptionExpirationDate)
        }
    }

    /// Whether user has seen the premium promo sheet (persisted)
    var hasSeenPremiumPromo: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenPremiumPromo, forKey: Keys.hasSeenPremiumPromo)
        }
    }

    /// Whether a purchase is currently in progress
    var isPurchasing: Bool = false

    /// Error message to display
    var purchaseError: String?

    // MARK: - Init

    init() {
        self.aiIdentificationsUsed = UserDefaults.standard.integer(forKey: Keys.aiIdentificationsUsed)

        if let typeString = UserDefaults.standard.string(forKey: Keys.subscriptionType),
           let type = SubscriptionType(rawValue: typeString) {
            self.subscriptionType = type
        } else {
            self.subscriptionType = .none
        }

        self.subscriptionExpirationDate = UserDefaults.standard.object(forKey: Keys.subscriptionExpirationDate) as? Date
        self.hasSeenPremiumPromo = UserDefaults.standard.bool(forKey: Keys.hasSeenPremiumPromo)
    }

    // MARK: - Computed Properties

    /// Whether to show the premium promo sheet (after onboarding, only once, if not premium)
    var shouldShowPremiumPromo: Bool {
        !hasSeenPremiumPromo && !isPremium
    }

    /// Whether user has an active premium subscription
    var isPremium: Bool {
        switch subscriptionType {
        case .lifetime:
            return true
        case .annual:
            // Check if subscription is still valid
            if let expirationDate = subscriptionExpirationDate {
                return expirationDate > Date()
            }
            return false
        case .none:
            return false
        }
    }

    /// Remaining free AI identifications
    var remainingFreeIdentifications: Int {
        max(0, Self.freeIdentificationLimit - aiIdentificationsUsed)
    }

    /// Whether user can use AI identification
    var canUseAIIdentification: Bool {
        isPremium || remainingFreeIdentifications > 0
    }

    /// Human-readable subscription status
    var statusDescription: String {
        if isPremium {
            switch subscriptionType {
            case .lifetime:
                return "Lifetime Premium"
            case .annual:
                if let expiration = subscriptionExpirationDate {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    return "Premium (renews \(formatter.string(from: expiration)))"
                }
                return "Annual Premium"
            case .none:
                return "Free"
            }
        } else {
            return "Free (\(remainingFreeIdentifications) IDs left)"
        }
    }

    // MARK: - Actions

    /// Record that an AI identification was used
    func recordIdentification() {
        if !isPremium {
            aiIdentificationsUsed += 1
        }
    }

    /// Update subscription status after a purchase
    func updateSubscription(type: SubscriptionType, expiresAt: Date? = nil) {
        subscriptionType = type
        subscriptionExpirationDate = expiresAt
    }

    /// Check and update subscription status (called on app launch)
    func checkAndUpdateStatus() async {
        // Always verify current entitlements with StoreKit
        let currentType = await StoreKitService.shared.checkCurrentEntitlements()
        let expirationDate = await StoreKitService.shared.getSubscriptionExpirationDate()
        updateSubscription(type: currentType, expiresAt: expirationDate)
    }

    /// Mark that user has seen the premium promo
    func markPromoAsSeen() {
        hasSeenPremiumPromo = true
    }

    /// Reset for testing (DEBUG only)
    #if DEBUG
    func resetForTesting() {
        aiIdentificationsUsed = 0
        subscriptionType = .none
        subscriptionExpirationDate = nil
        hasSeenPremiumPromo = false
    }
    #endif
}
