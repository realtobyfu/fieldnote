//
//  HybridPlantIdentificationService.swift
//  Fieldnote
//
//  Hybrid plant identification: API-first with CoreML fallback
//

import UIKit
import CoreLocation

actor HybridPlantIdentificationService {
    static let shared = HybridPlantIdentificationService()

    private let apiService = PlantIDAPIService.shared
    private let localService = CoreMLPlantIdentificationService.shared

    private init() {}

    /// Identifies a plant using the best available method
    ///
    /// Strategy:
    /// 1. If online, try Plant.id API (better accuracy, scientific names, family data)
    /// 2. If API fails or offline, fall back to local CoreML model
    ///
    /// - Parameters:
    ///   - image: The plant photo to identify
    ///   - location: Optional GPS coordinates for improved API accuracy
    /// - Returns: PlantIdentificationResult from either API or local model
    func identify(image: UIImage, location: CLLocationCoordinate2D? = nil) async throws -> PlantIdentificationResult {
        // Check network connectivity on main actor
        let isOnline = await MainActor.run { NetworkMonitor.shared.isConnected }

        if isOnline {
            do {
                // Try API with location for better accuracy
                return try await apiService.identify(image: image, location: location)
            } catch {
                // API failed, fall back to local CoreML
                print("Plant.id API failed: \(error.localizedDescription), falling back to local model")
                return try await localService.identify(image: image)
            }
        } else {
            // Offline: use local CoreML directly
            return try await localService.identify(image: image)
        }
    }
}
