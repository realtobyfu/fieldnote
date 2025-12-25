//
//  PlantIdentificationService.swift
//  Fieldnote
//
//  Mock ML service for plant identification (to be replaced with real ML)
//

import UIKit

// MARK: - Identification Result

struct PlantIdentificationResult {
    let commonName: String
    let scientificName: String
    let family: String
    let confidence: Double
}

// MARK: - Service Protocol

protocol PlantIdentificationServiceProtocol {
    func identify(image: UIImage) async throws -> PlantIdentificationResult
}

// MARK: - Errors

enum PlantIdentificationError: LocalizedError {
    case imageProcessingFailed
    case networkError
    case noResult

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image for identification"
        case .networkError:
            return "Network error during identification"
        case .noResult:
            return "Could not identify plant"
        }
    }
}

// MARK: - Mock Implementation

actor MockPlantIdentificationService: PlantIdentificationServiceProtocol {
    static let shared = MockPlantIdentificationService()

    func identify(image: UIImage) async throws -> PlantIdentificationResult {
        // Simulate brief ML processing time (non-throwing)
        try? await Task.sleep(for: .milliseconds(800))

        // Mock result: Always returns Common Dandelion
        return PlantIdentificationResult(
            commonName: "Common Dandelion",
            scientificName: "Taraxacum officinale",
            family: "Asteraceae",
            confidence: Double.random(in: 0.85...0.98)
        )
    }
}
