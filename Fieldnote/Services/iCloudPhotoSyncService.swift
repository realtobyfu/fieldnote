//
//  iCloudPhotoSyncService.swift
//  Fieldnote
//
//  Handles bidirectional photo sync via iCloud Documents (Ubiquity Container)
//

import Foundation

/// Status of a single photo's sync state
enum PhotoSyncStatus: Equatable {
    case local           // Only exists locally
    case uploading       // Currently uploading to iCloud
    case uploaded        // Exists in iCloud
    case downloading     // Currently downloading from iCloud
    case synced          // Exists both locally and in iCloud
    case error(String)   // Sync error
}

/// Overall photo sync status
enum PhotoSyncOverallStatus: Equatable {
    case idle
    case syncing
    case error(String)
}

/// Notification names for photo sync events
extension Notification.Name {
    static let photoSyncedFromCloud = Notification.Name("photoSyncedFromCloud")
    static let photoUploadedToCloud = Notification.Name("photoUploadedToCloud")
    static let photoSyncStatusChanged = Notification.Name("photoSyncStatusChanged")
}

// MARK: - Main Actor Query Manager

/// Manages NSMetadataQuery on the main actor (required by the API)
@MainActor
final class iCloudPhotoQueryManager {
    static let shared = iCloudPhotoQueryManager()

    private var query: NSMetadataQuery?
    private var updateHandler: ((Notification) -> Void)?

    func startQuery(onUpdate: @escaping (Notification) -> Void) {
        guard query == nil else { return }

        updateHandler = onUpdate

        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        metadataQuery.predicate = NSPredicate(format: "%K LIKE '*.jpg'", NSMetadataItemFSNameKey)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryDidUpdate(_:)),
            name: .NSMetadataQueryDidUpdate,
            object: metadataQuery
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryDidUpdate(_:)),
            name: .NSMetadataQueryDidFinishGathering,
            object: metadataQuery
        )

        metadataQuery.start()
        query = metadataQuery
    }

    func stopQuery() {
        query?.stop()
        if let q = query {
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: q)
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: q)
        }
        query = nil
        updateHandler = nil
    }

    @objc private func queryDidUpdate(_ notification: Notification) {
        updateHandler?(notification)
    }
}

// MARK: - iCloud Photo Sync Service

actor iCloudPhotoSyncService {
    static let shared = iCloudPhotoSyncService()

    private let fileManager = FileManager.default
    private var isMonitoring = false

    // Track sync status for each photo
    private var photoStatuses: [String: PhotoSyncStatus] = [:]
    private var pendingUploads: Set<String> = []
    private var pendingDownloads: Set<String> = []

    // MARK: - iCloud Container URLs

    /// The iCloud ubiquity container URL
    private var ubiquityContainerURL: URL? {
        fileManager.url(forUbiquityContainerIdentifier: "iCloud.com.fieldnote.app")
    }

    /// The directory in iCloud where photos are stored
    private var iCloudPhotosDirectory: URL? {
        guard let container = ubiquityContainerURL else { return nil }
        let photosDir = container.appendingPathComponent("Documents/EncounterPhotos", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: photosDir.path) {
            try? fileManager.createDirectory(at: photosDir, withIntermediateDirectories: true)
        }

        return photosDir
    }

    /// Local photos directory (matches PhotoStorageService)
    private var localPhotosDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("EncounterPhotos", isDirectory: true)
    }

    // MARK: - Availability

    /// Whether iCloud Documents is available
    var isAvailable: Bool {
        ubiquityContainerURL != nil
    }

    /// Current pending upload count
    var pendingUploadCount: Int {
        pendingUploads.count
    }

    /// Current pending download count
    var pendingDownloadCount: Int {
        pendingDownloads.count
    }

    /// Get sync status for a specific photo
    func status(for filename: String) -> PhotoSyncStatus {
        photoStatuses[filename] ?? .local
    }

    // MARK: - Upload Photo to iCloud

    /// Upload a photo from local storage to iCloud
    /// - Parameter filename: The photo filename to upload
    func uploadPhoto(filename: String) async throws {
        guard let iCloudDir = iCloudPhotosDirectory else {
            throw iCloudPhotoError.iCloudUnavailable
        }

        let localURL = localPhotosDirectory.appendingPathComponent(filename)
        let iCloudURL = iCloudDir.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: localURL.path) else {
            throw iCloudPhotoError.localFileNotFound
        }

        // Update status
        pendingUploads.insert(filename)
        photoStatuses[filename] = .uploading
        await notifyStatusChanged()

        do {
            // Use NSFileCoordinator for safe iCloud writes
            var coordinatorError: NSError?
            var writeError: Error?

            let coordinator = NSFileCoordinator()
            coordinator.coordinate(writingItemAt: iCloudURL, options: .forReplacing, error: &coordinatorError) { coordURL in
                do {
                    // Remove existing file if present
                    if self.fileManager.fileExists(atPath: coordURL.path) {
                        try self.fileManager.removeItem(at: coordURL)
                    }
                    // Copy local file to iCloud
                    try self.fileManager.copyItem(at: localURL, to: coordURL)
                } catch {
                    writeError = error
                }
            }

            if let error = coordinatorError ?? writeError {
                throw error
            }

            // Update status
            pendingUploads.remove(filename)
            photoStatuses[filename] = .synced
            await notifyStatusChanged()

            // Post notification
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .photoUploadedToCloud,
                    object: nil,
                    userInfo: ["filename": filename]
                )
            }

        } catch {
            pendingUploads.remove(filename)
            photoStatuses[filename] = .error(error.localizedDescription)
            await notifyStatusChanged()
            throw iCloudPhotoError.uploadFailed(error)
        }
    }

    // MARK: - Download Photo from iCloud

    /// Download a photo from iCloud to local storage
    /// - Parameter filename: The photo filename to download
    /// - Returns: true if download succeeded, false if file not in iCloud
    func downloadPhoto(filename: String) async throws -> Bool {
        guard let iCloudDir = iCloudPhotosDirectory else {
            return false
        }

        let iCloudURL = iCloudDir.appendingPathComponent(filename)
        let localURL = localPhotosDirectory.appendingPathComponent(filename)

        // Check if file exists in iCloud
        guard fileManager.fileExists(atPath: iCloudURL.path) else {
            return false
        }

        // If local file already exists, we're synced
        if fileManager.fileExists(atPath: localURL.path) {
            photoStatuses[filename] = .synced
            return true
        }

        // Update status
        pendingDownloads.insert(filename)
        photoStatuses[filename] = .downloading
        await notifyStatusChanged()

        do {
            // Check if file needs to be downloaded from iCloud
            let resourceValues = try iCloudURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            if let status = resourceValues.ubiquitousItemDownloadingStatus,
               status != .current {
                // Trigger download
                try fileManager.startDownloadingUbiquitousItem(at: iCloudURL)

                // Wait for download to complete
                try await waitForDownload(url: iCloudURL)
            }

            // Use NSFileCoordinator for safe read
            var coordinatorError: NSError?
            var readError: Error?

            let coordinator = NSFileCoordinator()
            coordinator.coordinate(readingItemAt: iCloudURL, options: [], error: &coordinatorError) { coordURL in
                do {
                    // Ensure local directory exists
                    if !self.fileManager.fileExists(atPath: self.localPhotosDirectory.path) {
                        try self.fileManager.createDirectory(at: self.localPhotosDirectory, withIntermediateDirectories: true)
                    }
                    // Copy from iCloud to local
                    try self.fileManager.copyItem(at: coordURL, to: localURL)
                } catch {
                    readError = error
                }
            }

            if let error = coordinatorError ?? readError {
                throw error
            }

            // Update status
            pendingDownloads.remove(filename)
            photoStatuses[filename] = .synced
            await notifyStatusChanged()

            // Post notification
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .photoSyncedFromCloud,
                    object: nil,
                    userInfo: ["filename": filename]
                )
            }

            return true

        } catch {
            pendingDownloads.remove(filename)
            photoStatuses[filename] = .error(error.localizedDescription)
            await notifyStatusChanged()
            throw iCloudPhotoError.downloadFailed(error)
        }
    }

    /// Wait for an iCloud file to finish downloading
    private func waitForDownload(url: URL, timeout: TimeInterval = 60) async throws {
        let startTime = Date()

        while true {
            let resourceValues = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            if let status = resourceValues.ubiquitousItemDownloadingStatus,
               status == .current {
                return
            }

            // Check timeout
            if Date().timeIntervalSince(startTime) > timeout {
                throw iCloudPhotoError.downloadTimeout
            }

            // Wait before checking again
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
    }

    // MARK: - Delete Photo from iCloud

    /// Delete a photo from iCloud
    /// - Parameter filename: The photo filename to delete
    func deletePhoto(filename: String) async throws {
        guard let iCloudDir = iCloudPhotosDirectory else {
            return // iCloud not available, nothing to delete
        }

        let iCloudURL = iCloudDir.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: iCloudURL.path) else {
            return // Already deleted
        }

        do {
            var coordinatorError: NSError?
            var deleteError: Error?

            let coordinator = NSFileCoordinator()
            coordinator.coordinate(writingItemAt: iCloudURL, options: .forDeleting, error: &coordinatorError) { coordURL in
                do {
                    try self.fileManager.removeItem(at: coordURL)
                } catch {
                    deleteError = error
                }
            }

            if let error = coordinatorError ?? deleteError {
                throw error
            }

            // Remove from tracking
            photoStatuses.removeValue(forKey: filename)
            await notifyStatusChanged()

        } catch {
            throw iCloudPhotoError.deleteFailed(error)
        }
    }

    // MARK: - Sync All Photos

    /// Perform a full sync - upload local photos and download cloud photos
    func syncAllPhotos() async {
        guard isAvailable else { return }

        // Get local photos
        let localPhotos = (try? fileManager.contentsOfDirectory(atPath: localPhotosDirectory.path)) ?? []
        let localJpgs = Set(localPhotos.filter { $0.hasSuffix(".jpg") })

        // Get iCloud photos
        let cloudPhotos: Set<String>
        if let iCloudDir = iCloudPhotosDirectory,
           let contents = try? fileManager.contentsOfDirectory(atPath: iCloudDir.path) {
            cloudPhotos = Set(contents.filter { $0.hasSuffix(".jpg") })
        } else {
            cloudPhotos = []
        }

        // Upload photos that exist locally but not in cloud
        let toUpload = localJpgs.subtracting(cloudPhotos)
        for filename in toUpload {
            do {
                try await uploadPhoto(filename: filename)
            } catch {
                print("Failed to upload \(filename): \(error)")
            }
        }

        // Download photos that exist in cloud but not locally
        let toDownload = cloudPhotos.subtracting(localJpgs)
        for filename in toDownload {
            do {
                _ = try await downloadPhoto(filename: filename)
            } catch {
                print("Failed to download \(filename): \(error)")
            }
        }

        // Mark photos that exist in both as synced
        let synced = localJpgs.intersection(cloudPhotos)
        for filename in synced {
            photoStatuses[filename] = .synced
        }

        await notifyStatusChanged()
    }

    // MARK: - Migration for Existing Users

    /// Upload all existing local photos to iCloud (for first-time iCloud users)
    func migrateExistingPhotos() async {
        guard isAvailable else { return }

        let localPhotos = (try? fileManager.contentsOfDirectory(atPath: localPhotosDirectory.path)) ?? []

        for filename in localPhotos where filename.hasSuffix(".jpg") {
            if photoStatuses[filename] != .synced && photoStatuses[filename] != .uploading {
                do {
                    try await uploadPhoto(filename: filename)
                } catch {
                    print("Migration: Failed to upload \(filename): \(error)")
                }
            }
        }
    }

    // MARK: - Monitoring for Remote Changes

    /// Start monitoring for changes from other devices
    nonisolated func startMonitoring() {
        Task {
            await self.beginMonitoring()
        }
    }

    /// Stop monitoring for changes
    nonisolated func stopMonitoring() {
        Task {
            await self.endMonitoring()
        }
    }

    private func beginMonitoring() async {
        guard !isMonitoring else { return }
        guard isAvailable else { return }

        isMonitoring = true

        // Setup the query on main actor
        await MainActor.run {
            iCloudPhotoQueryManager.shared.startQuery { [weak self] notification in
                guard let self = self else { return }
                Task {
                    await self.handleMetadataQueryUpdate(notification)
                }
            }
        }
    }

    private func endMonitoring() async {
        isMonitoring = false
        await MainActor.run {
            iCloudPhotoQueryManager.shared.stopQuery()
        }
    }

    private func handleMetadataQueryUpdate(_ notification: Notification) async {
        guard let query = notification.object as? NSMetadataQuery else { return }

        // Extract filenames on the main actor where NSMetadataQuery is safe to access
        let filenames: [String] = await MainActor.run {
            query.disableUpdates()
            defer { query.enableUpdates() }

            var names: [String] = []
            for i in 0..<query.resultCount {
                if let item = query.result(at: i) as? NSMetadataItem,
                   let filename = item.value(forAttribute: NSMetadataItemFSNameKey) as? String {
                    names.append(filename)
                }
            }
            return names
        }

        // Process filenames back on the actor
        for filename in filenames {
            let localURL = localPhotosDirectory.appendingPathComponent(filename)
            if !fileManager.fileExists(atPath: localURL.path) {
                // Download the new photo
                do {
                    _ = try await downloadPhoto(filename: filename)
                } catch {
                    print("Failed to download new cloud photo \(filename): \(error)")
                }
            }
        }
    }

    // MARK: - Notifications

    private func notifyStatusChanged() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .photoSyncStatusChanged, object: nil)
        }
    }

    // MARK: - Errors

    enum iCloudPhotoError: LocalizedError {
        case iCloudUnavailable
        case localFileNotFound
        case uploadFailed(Error)
        case downloadFailed(Error)
        case downloadTimeout
        case deleteFailed(Error)

        var errorDescription: String? {
            switch self {
            case .iCloudUnavailable:
                return "iCloud is not available"
            case .localFileNotFound:
                return "Local photo file not found"
            case .uploadFailed(let error):
                return "Failed to upload photo: \(error.localizedDescription)"
            case .downloadFailed(let error):
                return "Failed to download photo: \(error.localizedDescription)"
            case .downloadTimeout:
                return "Photo download timed out"
            case .deleteFailed(let error):
                return "Failed to delete photo: \(error.localizedDescription)"
            }
        }
    }
}
