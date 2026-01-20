//
//  CaptureViewModel.swift
//  Fieldnote
//
//  View model for capture screen photo handling
//

import CoreLocation
import Foundation
import PhotosUI
import SwiftUI

protocol CaptureLocationProviding {
    func requestCurrentLocation() async -> CLLocationCoordinate2D?
}

protocol PlantIdentificationProviding {
    func identify(image: UIImage, location: CLLocationCoordinate2D?) async throws -> PlantIdentificationResult
}

protocol CaptureSubscriptionProviding: AnyObject {
    var canUseAIIdentification: Bool { get }
    func recordIdentification()
}

extension LocationService: CaptureLocationProviding {}
extension HybridPlantIdentificationService: PlantIdentificationProviding {}
extension SubscriptionStore: CaptureSubscriptionProviding {}

@MainActor
@Observable
class CaptureViewModel {
    var selectedItem: PhotosPickerItem?
    var selectedPhotoData: Data?
    var showReviewSheet = false
    var showPaywall = false

    // ML identification state
    var isIdentifying = false
    var identificationError: Error?
    var captureMode: CaptureMode?

    // Pending image for retry after paywall dismissal
    private var pendingImage: UIImage?

    private let locationService: CaptureLocationProviding
    private let identificationService: PlantIdentificationProviding

    init(
        locationService: CaptureLocationProviding = LocationService.shared,
        identificationService: PlantIdentificationProviding = HybridPlantIdentificationService.shared
    ) {
        self.locationService = locationService
        self.identificationService = identificationService
    }

    func loadPhoto(subscriptionStore: CaptureSubscriptionProviding) async {
        guard let item = selectedItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedPhotoData = data

                if let image = UIImage(data: data) {
                    await identifyPlant(image: image, subscriptionStore: subscriptionStore)
                }
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    func handleCapturedImage(_ image: UIImage, subscriptionStore: CaptureSubscriptionProviding) async {
        await identifyPlant(image: image, subscriptionStore: subscriptionStore)
    }

    private func identifyPlant(image: UIImage, subscriptionStore: CaptureSubscriptionProviding) async {
        // Check if user can use AI identification
        guard subscriptionStore.canUseAIIdentification else {
            pendingImage = image
            showPaywall = true
            return
        }

        isIdentifying = true
        identificationError = nil

        defer {
            isIdentifying = false
        }

        do {
            // Fetch location for better API accuracy (non-blocking)
            let location = await locationService.requestCurrentLocation()

            // Use hybrid service (API-first, CoreML fallback)
            let result = try await identificationService.identify(
                image: image,
                location: location
            )

            // Record AI identification usage
            subscriptionStore.recordIdentification()

            captureMode = .mlIdentification(result: result, image: image)
            showReviewSheet = true
        } catch {
            identificationError = error
            // Still show review sheet but with empty fields for manual entry
            captureMode = .mlIdentification(
                result: PlantIdentificationResult(
                    commonName: "",
                    scientificName: "",
                    family: "",
                    confidence: 0.75
                ),
                image: image
            )
            showReviewSheet = true
        }
    }

    /// Retry identification after subscription purchase
    func retryPendingIdentification(subscriptionStore: CaptureSubscriptionProviding) async {
        guard let image = pendingImage else { return }
        pendingImage = nil
        await identifyPlant(image: image, subscriptionStore: subscriptionStore)
    }

    func startManualEntry() {
        captureMode = .manualEntry
        showReviewSheet = true
    }

    func reset() {
        selectedItem = nil
        selectedPhotoData = nil
        showReviewSheet = false
        isIdentifying = false
        identificationError = nil
        captureMode = nil
    }
}
