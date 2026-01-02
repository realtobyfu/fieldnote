//
//  PlantIdentificationService.swift
//  Fieldnote
//
//  ML service for plant identification using CoreML
//

import UIKit
import Vision
import CoreML

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
    case modelLoadFailed
    case predictionFailed
    case noResult
    case networkError
    case invalidAPIKey
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image"
        case .modelLoadFailed:
            return "Failed to load identification model"
        case .predictionFailed:
            return "Identification failed"
        case .noResult:
            return "Could not identify plant"
        case .networkError:
            return "Network error - using offline identification"
        case .invalidAPIKey:
            return "API configuration error"
        case .rateLimited:
            return "Too many requests - try again later"
        }
    }
}

// MARK: - CoreML Implementation

actor CoreMLPlantIdentificationService: PlantIdentificationServiceProtocol {
    static let shared = CoreMLPlantIdentificationService()

    private var vnModel: VNCoreMLModel?

    private init() {}

    /// Lazily loads the CoreML model wrapped for Vision
    private func getModel() throws -> VNCoreMLModel {
        if let existing = vnModel {
            return existing
        }

        let config = MLModelConfiguration()
        config.computeUnits = .all  // Use Neural Engine when available

        guard let mlModel = try? plant_identifier_40_classes(configuration: config).model,
              let model = try? VNCoreMLModel(for: mlModel) else {
            throw PlantIdentificationError.modelLoadFailed
        }

        vnModel = model
        return model
    }

    func identify(image: UIImage) async throws -> PlantIdentificationResult {
        guard let cgImage = image.cgImage else {
            throw PlantIdentificationError.imageProcessingFailed
        }

        let model = try getModel()

        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false

            let request = VNCoreMLRequest(model: model) { request, error in
                guard !hasResumed else { return }
                hasResumed = true

                if error != nil {
                    continuation.resume(throwing: PlantIdentificationError.predictionFailed)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation],
                      let top = results.first,
                      top.confidence >= 0.3 else {  // 30% minimum threshold
                    continuation.resume(throwing: PlantIdentificationError.noResult)
                    return
                }

                let result = PlantIdentificationResult(
                    commonName: Self.formatLabel(top.identifier),
                    scientificName: "",
                    family: "",
                    confidence: Double(top.confidence)
                )
                continuation.resume(returning: result)
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(throwing: PlantIdentificationError.predictionFailed)
            }
        }
    }

    // MARK: - Label Formatting

    /// Converts ML label format to catalog display format
    /// "black-eyed_susan" -> "Black-eyed Susan"
    private static func formatLabel(_ label: String) -> String {
        label.split(separator: "_").enumerated().map { index, word in
            let s = String(word)
            return index == 0
                ? s.prefix(1).uppercased() + s.dropFirst()
                : s.capitalized
        }.joined(separator: " ")
    }
}

// MARK: - Mock Implementation (for testing)

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
