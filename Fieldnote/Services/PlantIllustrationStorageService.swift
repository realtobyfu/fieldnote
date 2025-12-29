//
//  PlantIllustrationStorageService.swift
//  Fieldnote
//
//  Handles saving and loading user-provided plant illustrations
//

import UIKit

actor PlantIllustrationStorageService {
    static let shared = PlantIllustrationStorageService()

    private let fileManager = FileManager.default

    private var illustrationsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let illustrationsPath = documentsPath.appendingPathComponent("PlantIllustrations", isDirectory: true)

        if !fileManager.fileExists(atPath: illustrationsPath.path) {
            try? fileManager.createDirectory(at: illustrationsPath, withIntermediateDirectories: true)
        }

        return illustrationsPath
    }

    func saveIllustration(_ image: UIImage, for plantId: UUID) async throws -> String {
        let filename = "\(plantId.uuidString).jpg"
        let fileURL = illustrationsDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw StorageError.compressionFailed
        }

        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            throw StorageError.saveFailed(error)
        }
    }

    func loadIllustration(filename: String) async -> UIImage? {
        let fileURL = illustrationsDirectory.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    func deleteIllustration(filename: String) async throws {
        let fileURL = illustrationsDirectory.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw StorageError.deleteFailed(error)
        }
    }

    enum StorageError: LocalizedError {
        case compressionFailed
        case saveFailed(Error)
        case deleteFailed(Error)

        var errorDescription: String? {
            switch self {
            case .compressionFailed:
                return "Failed to compress image"
            case .saveFailed(let error):
                return "Failed to save illustration: \(error.localizedDescription)"
            case .deleteFailed(let error):
                return "Failed to delete illustration: \(error.localizedDescription)"
            }
        }
    }
}
