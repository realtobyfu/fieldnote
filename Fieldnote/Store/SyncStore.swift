//
//  SyncStore.swift
//  Fieldnote
//
//  Manages iCloud sync status display (auto-sync, no user toggle)
//

import Foundation
import SwiftUI
import CloudKit

/// Sync status for UI display
enum SyncStatus: Equatable {
    case unavailable
    case idle
    case syncing
    case synced(Date)
    case error(String)
}

@MainActor
@Observable
class SyncStore {
    // MARK: - Keys

    private enum Keys {
        static let lastSyncDate = "lastSyncDate"
    }

    // MARK: - Observable State

    /// Current sync status
    var syncStatus: SyncStatus = .unavailable

    /// Last successful sync date
    var lastSyncDate: Date? {
        didSet {
            if let date = lastSyncDate {
                UserDefaults.standard.set(date, forKey: Keys.lastSyncDate)
            }
        }
    }

    /// Whether iCloud is available on this device
    var iCloudAvailable: Bool = false

    /// Error message if iCloud is unavailable
    var iCloudUnavailableReason: String?

    // MARK: - Init

    init() {
        self.lastSyncDate = UserDefaults.standard.object(forKey: Keys.lastSyncDate) as? Date

        // Check iCloud availability
        checkiCloudAvailability()
    }

    // MARK: - iCloud Availability

    func checkiCloudAvailability() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.iCloudAvailable = true
                    self?.iCloudUnavailableReason = nil
                    // Set status based on last sync
                    if let lastSync = self?.lastSyncDate {
                        self?.syncStatus = .synced(lastSync)
                    } else {
                        self?.syncStatus = .idle
                    }
                case .noAccount:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "Sign in to iCloud in Settings"
                    self?.syncStatus = .unavailable
                case .restricted:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "iCloud access is restricted"
                    self?.syncStatus = .unavailable
                case .couldNotDetermine:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "Could not determine iCloud status"
                    self?.syncStatus = .unavailable
                case .temporarilyUnavailable:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "iCloud temporarily unavailable"
                    self?.syncStatus = .unavailable
                @unknown default:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "Unknown iCloud status"
                    self?.syncStatus = .unavailable
                }
            }
        }
    }

    // MARK: - Sync Status Updates

    /// Mark sync as in progress
    func startSync() {
        guard iCloudAvailable else { return }
        syncStatus = .syncing
    }

    /// Mark sync as complete
    func syncCompleted() {
        guard iCloudAvailable else { return }
        lastSyncDate = Date()
        syncStatus = .synced(Date())
    }

    /// Mark sync as failed
    func syncFailed(error: String) {
        guard iCloudAvailable else { return }
        syncStatus = .error(error)
    }

    // MARK: - Computed Properties

    /// Human-readable sync status for UI
    var statusText: String {
        switch syncStatus {
        case .unavailable:
            return "Your observations are stored locally on this device."
        case .idle:
            return "Ready to sync across your devices."
        case .syncing:
            return "Syncing your botanical journal..."
        case .synced(let date):
            return "Last synced \(date.formatted(.relative(presentation: .named)))"
        case .error(let message):
            return "Sync error: \(message)"
        }
    }
}
