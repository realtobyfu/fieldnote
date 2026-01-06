//
//  StoreKitService.swift
//  Fieldnote
//
//  StoreKit 2 wrapper for handling in-app purchases and subscriptions
//

import Foundation
import StoreKit

actor StoreKitService {
    // MARK: - Singleton

    static let shared = StoreKitService()

    // MARK: - Product IDs

    static let annualProductID = "com.fieldnote.premium.annual.1"
    static let lifetimeProductID = "com.fieldnote.premium.lifetime.1"

    private static var allProductIDs: Set<String> {
        [annualProductID, lifetimeProductID]
    }

    // MARK: - State

    private var products: [Product] = []
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Init

    private init() {}

    // MARK: - Products

    /// Fetch available products from App Store
    func fetchProducts() async throws -> [Product] {
        let storeProducts = try await Product.products(for: Self.allProductIDs)
        products = storeProducts.sorted { $0.price < $1.price }
        return products
    }

    /// Get the annual subscription product
    var annualProduct: Product? {
        products.first { $0.id == Self.annualProductID }
    }

    /// Get the lifetime purchase product
    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeProductID }
    }

    // MARK: - Purchases

    /// Purchase a product
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            // Transaction is pending (e.g., Ask to Buy)
            return nil

        @unknown default:
            return nil
        }
    }

    /// Restore previous purchases by refreshing from App Store
    func restorePurchases() async throws {
        // Sync with App Store to get latest transaction state
        // This triggers the system to re-verify all purchases
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
        }
    }

    // MARK: - Entitlements

    /// Check current subscription entitlements
    func checkCurrentEntitlements() async -> SubscriptionType {
        // Check for lifetime purchase first
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.lifetimeProductID {
                    return .lifetime
                }
                if transaction.productID == Self.annualProductID {
                    // Check if subscription is still valid
                    if let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        return .annual
                    }
                }
            }
        }
        return .none
    }

    /// Get expiration date for annual subscription
    func getSubscriptionExpirationDate() async -> Date? {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.annualProductID {
                    return transaction.expirationDate
                }
            }
        }
        return nil
    }

    // MARK: - Transaction Listener

    /// Start listening for transaction updates
    func startTransactionListener(onUpdate: @escaping (SubscriptionType, Date?) async -> Void) {
        updateListenerTask?.cancel()
        updateListenerTask = Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()

                    // Determine new subscription type
                    let newType = await self.checkCurrentEntitlements()
                    let expirationDate = await self.getSubscriptionExpirationDate()
                    await onUpdate(newType, expirationDate)
                }
            }
        }
    }

    /// Stop listening for transaction updates
    func stopTransactionListener() {
        updateListenerTask?.cancel()
        updateListenerTask = nil
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors

enum StoreKitError: LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        }
    }
}
