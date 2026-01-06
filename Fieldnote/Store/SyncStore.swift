//
//  SyncStore.swift
//  Fieldnote
//
//  Manages iCloud sync state and user preferences
//

import Foundation
import SwiftUI
import CloudKit

/// Sync status for UI display
enum SyncStatus: Equatable {
    case disabled
    case idle
    case syncing
    case synced(Date)
    case error(String)

    var description: String {
        switch self {
        case .disabled:
            return "iCloud sync disabled"
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .synced(let date):
            return "Last synced \(date.formatted(.relative(presentation: .named)))"
        case .error(let message):
            return "Sync error: \(message)"
        }
    }
}

@MainActor
@Observable
class SyncStore {
    // MARK: - Keys

    private enum Keys {
        static let iCloudSyncEnabled = "iCloudSyncEnabled"
        static let lastSyncDate = "lastSyncDate"
    }

    // MARK: - Observable State

    /// Whether iCloud sync is enabled by user
    var iCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(iCloudSyncEnabled, forKey: Keys.iCloudSyncEnabled)
            if iCloudSyncEnabled {
                checkiCloudAvailability()
            }
        }
    }

    /// Current sync status
    var syncStatus: SyncStatus = .disabled

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
        self.iCloudSyncEnabled = UserDefaults.standard.bool(forKey: Keys.iCloudSyncEnabled)
        self.lastSyncDate = UserDefaults.standard.object(forKey: Keys.lastSyncDate) as? Date

        // Set initial status
        if iCloudSyncEnabled {
            if let lastSync = lastSyncDate {
                syncStatus = .synced(lastSync)
            } else {
                syncStatus = .idle
            }
        } else {
            syncStatus = .disabled
        }

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
                case .noAccount:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "Sign in to iCloud in Settings"
                case .restricted:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "iCloud access is restricted"
                case .couldNotDetermine:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "Could not determine iCloud status"
                case .temporarilyUnavailable:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "iCloud temporarily unavailable"
                @unknown default:
                    self?.iCloudAvailable = false
                    self?.iCloudUnavailableReason = "Unknown iCloud status"
                }
            }
        }
    }

    // MARK: - Sync Actions

    /// Toggle sync on/off
    func toggleSync() {
        if !iCloudSyncEnabled && !iCloudAvailable {
            // Can't enable sync without iCloud
            return
        }

        iCloudSyncEnabled.toggle()

        if iCloudSyncEnabled {
            syncStatus = .idle
            // SwiftData will automatically start syncing
            // In a real implementation, we'd listen to NSPersistentCloudKitContainer notifications
            simulateSyncComplete()
        } else {
            syncStatus = .disabled
        }
    }

    /// Mark sync as in progress
    func startSync() {
        guard iCloudSyncEnabled else { return }
        syncStatus = .syncing
    }

    /// Mark sync as complete
    func syncCompleted() {
        guard iCloudSyncEnabled else { return }
        lastSyncDate = Date()
        syncStatus = .synced(Date())
    }

    /// Mark sync as failed
    func syncFailed(error: String) {
        guard iCloudSyncEnabled else { return }
        syncStatus = .error(error)
    }

    /// Simulate sync completion (for demo purposes)
    /// In production, this would be triggered by CloudKit notifications
    private func simulateSyncComplete() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.syncCompleted()
        }
    }

    // MARK: - Computed Properties

    /// Whether user can enable sync
    var canEnableSync: Bool {
        iCloudAvailable
    }

    /// Human-readable sync status for UI
    var statusText: String {
        if !iCloudSyncEnabled {
            return "Your observations are stored locally on this device."
        }

        switch syncStatus {
        case .syncing:
            return "Syncing your botanical journal..."
        case .synced(let date):
            return "Your journal syncs across all your devices.\nLast synced \(date.formatted(.relative(presentation: .named)))"
        case .error(let message):
            return "Sync error: \(message)"
        default:
            return "Ready to sync across your devices."
        }
    }
}
