//
//  PhotoStorageService.swift
//  Fieldnote
//
//  Handles saving and loading user photos for encounters
//

import UIKit

actor PhotoStorageService {
    static let shared = PhotoStorageService()

    private let fileManager = FileManager.default

    // MARK: - Directory Management

    /// The directory where encounter photos are stored
    private var photosDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosPath = documentsPath.appendingPathComponent("EncounterPhotos", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: photosPath.path) {
            try? fileManager.createDirectory(at: photosPath, withIntermediateDirectories: true)
        }

        return photosPath
    }

    // MARK: - Save Photo

    /// Save a photo for an encounter and return the filename
    /// - Parameters:
    ///   - image: The UIImage to save
    ///   - encounterId: The encounter's UUID (used as filename)
    /// - Returns: The saved filename
    func savePhoto(_ image: UIImage, for encounterId: UUID) async throws -> String {
        let filename = "\(encounterId.uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)

        // Compress to JPEG with reasonable quality
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoStorageError.compressionFailed
        }

        do {
            try data.write(to: fileURL)

            // Upload to iCloud in background
            Task.detached {
                try? await iCloudPhotoSyncService.shared.uploadPhoto(filename: filename)
            }

            return filename
        } catch {
            throw PhotoStorageError.saveFailed(error)
        }
    }

    /// Save a photo with an index for multiple photos per encounter
    /// - Parameters:
    ///   - image: The UIImage to save
    ///   - encounterId: The encounter's UUID
    ///   - index: The photo index (0, 1, 2, etc.)
    /// - Returns: The saved filename
    func savePhoto(_ image: UIImage, for encounterId: UUID, index: Int) async throws -> String {
        let filename = "\(encounterId.uuidString)_\(index).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)

        // Compress to JPEG with reasonable quality
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoStorageError.compressionFailed
        }

        do {
            try data.write(to: fileURL)

            // Upload to iCloud in background
            Task.detached {
                try? await iCloudPhotoSyncService.shared.uploadPhoto(filename: filename)
            }

            return filename
        } catch {
            throw PhotoStorageError.saveFailed(error)
        }
    }

    // MARK: - Load Photo

    /// Load a photo by filename
    /// - Parameter filename: The saved filename
    /// - Returns: The UIImage if found, nil otherwise
    func loadPhoto(filename: String) async -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(filename)

        // Try loading from local storage first
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            return image
        }

        // If local file missing, try downloading from iCloud
        if await iCloudPhotoSyncService.shared.isAvailable {
            let downloaded = try? await iCloudPhotoSyncService.shared.downloadPhoto(filename: filename)
            if downloaded == true {
                // Retry loading from local storage
                if let data = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: data) {
                    return image
                }
            }
        }

        return nil
    }

    // MARK: - Delete Photo

    /// Delete a photo by filename
    /// - Parameter filename: The filename to delete
    func deletePhoto(filename: String) async throws {
        let fileURL = photosDirectory.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            // Still try to delete from iCloud in case it exists there
            Task.detached {
                try? await iCloudPhotoSyncService.shared.deletePhoto(filename: filename)
            }
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)

            // Also delete from iCloud
            Task.detached {
                try? await iCloudPhotoSyncService.shared.deletePhoto(filename: filename)
            }
        } catch {
            throw PhotoStorageError.deleteFailed(error)
        }
    }

    // MARK: - Thumbnail Generation

    /// Generate a thumbnail for a photo
    /// - Parameters:
    ///   - filename: The source photo filename
    ///   - maxSize: Maximum dimension for the thumbnail
    /// - Returns: A thumbnail UIImage
    func loadThumbnail(filename: String, maxSize: CGFloat = 200) async -> UIImage? {
        guard let fullImage = await loadPhoto(filename: filename) else {
            return nil
        }

        let scale = min(maxSize / fullImage.size.width, maxSize / fullImage.size.height)

        // If image is already smaller than target, return as-is
        if scale >= 1.0 {
            return fullImage
        }

        let newSize = CGSize(
            width: fullImage.size.width * scale,
            height: fullImage.size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            fullImage.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Storage Info

    /// Get the total size of stored photos
    var totalStorageSize: Int64 {
        get async {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: photosDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            ) else {
                return 0
            }

            return contents.reduce(0) { total, url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return total + Int64(size)
            }
        }
    }

    /// Get count of stored photos
    var photoCount: Int {
        get async {
            (try? fileManager.contentsOfDirectory(atPath: photosDirectory.path))?.count ?? 0
        }
    }

    // MARK: - Errors

    enum PhotoStorageError: LocalizedError {
        case compressionFailed
        case saveFailed(Error)
        case deleteFailed(Error)

        var errorDescription: String? {
            switch self {
            case .compressionFailed:
                return "Failed to compress image"
            case .saveFailed(let error):
                return "Failed to save photo: \(error.localizedDescription)"
            case .deleteFailed(let error):
                return "Failed to delete photo: \(error.localizedDescription)"
            }
        }
    }
}
