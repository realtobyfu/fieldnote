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

/// Provider of multi-candidate identification, so the review sheet can surface
/// reranked alternatives. See LocaleAwareCatalogImplementationPlan.md (B4).
protocol PlantCandidateProviding {
    func identifyCandidates(
        image: UIImage,
        location: CLLocationCoordinate2D?,
        maxResults: Int
    ) async throws -> [PlantIdentificationCandidate]
}

extension PlantIDAPIService: PlantCandidateProviding {}

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

    enum Destination: Identifiable {
        case review(CaptureMode)
        case paywall

        var id: String {
            switch self {
            case .review: return "review"
            case .paywall: return "paywall"
            }
        }
    }

    var destination: Destination?

    var selectedItem: PhotosPickerItem?
    var selectedPhotoData: Data?

    var isIdentifying = false
    var identificationError: Error?

    private var pendingImage: UIImage?
    /// Locality context captured from the AppStore at request time, used to
    /// rerank visual candidates against what's reported nearby this month.
    private var pendingLocalItems: [LocalCatalogItem] = []
    private var pendingLocalMonth: Int?

    private let locationService: CaptureLocationProviding
    private let identificationService: PlantIdentificationProviding
    private let candidateService: PlantCandidateProviding

    init(
        locationService: CaptureLocationProviding = LocationService.shared,
        identificationService: PlantIdentificationProviding = HybridPlantIdentificationService.shared,
        candidateService: PlantCandidateProviding = PlantIDAPIService.shared
    ) {
        self.locationService = locationService
        self.identificationService = identificationService
        self.candidateService = candidateService
    }

    func loadPhoto(
        subscriptionStore: CaptureSubscriptionProviding,
        localItems: [LocalCatalogItem] = [],
        localMonth: Int? = nil
    ) async {
        guard let item = selectedItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedPhotoData = data

                if let image = UIImage(data: data) {
                    await identifyPlant(
                        image: image,
                        subscriptionStore: subscriptionStore,
                        localItems: localItems,
                        localMonth: localMonth
                    )
                }
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    func handleCapturedImage(
        _ image: UIImage,
        subscriptionStore: CaptureSubscriptionProviding,
        localItems: [LocalCatalogItem] = [],
        localMonth: Int? = nil
    ) async {
        await identifyPlant(
            image: image,
            subscriptionStore: subscriptionStore,
            localItems: localItems,
            localMonth: localMonth
        )
    }

    private func identifyPlant(
        image: UIImage,
        subscriptionStore: CaptureSubscriptionProviding,
        localItems: [LocalCatalogItem],
        localMonth: Int?
    ) async {
        // Check if user can use AI identification
        guard subscriptionStore.canUseAIIdentification else {
            pendingImage = image
            pendingLocalItems = localItems
            pendingLocalMonth = localMonth
            destination = .paywall
            return
        }

        isIdentifying = true
        identificationError = nil

        defer {
            isIdentifying = false
        }

        // Fetch location for better API accuracy (non-blocking)
        let location = await locationService.requestCurrentLocation()
        let month = localMonth ?? Calendar.current.component(.month, from: Date())

        do {
            // Pull the top visual candidates so we can rerank + offer alternatives.
            let candidates = try await candidateService.identifyCandidates(
                image: image,
                location: location,
                maxResults: 5
            )

            // Rerank with the local + seasonal prior (visual signal stays dominant).
            let ranked = LocalRankingService().rerankCandidates(
                candidates,
                localItems: localItems,
                month: month
            )

            guard let top = ranked.first else {
                throw PlantIdentificationError.noResult
            }

            // Record AI identification usage
            subscriptionStore.recordIdentification()

            // Alternatives = the reranked tail, surfaced when scores are close.
            let alternatives = Array(ranked.dropFirst())
            destination = .review(.mlIdentification(
                result: top.candidate.asResult,
                image: image,
                alternatives: alternatives
            ))
        } catch {
            // The candidate path is Pl@ntNet-only. When it fails (offline or API
            // error), fall back to the hybrid service, which uses the on-device
            // CoreML model offline. No alternatives are available on this path.
            do {
                let result = try await identificationService.identify(
                    image: image,
                    location: location
                )
                subscriptionStore.recordIdentification()
                destination = .review(.mlIdentification(result: result, image: image))
            } catch let fallbackError {
                identificationError = fallbackError
                // Still show review sheet but with empty fields for manual entry
                destination = .review(.mlIdentification(
                    result: PlantIdentificationResult(
                        commonName: "",
                        scientificName: "",
                        family: "",
                        confidence: 0.75
                    ),
                    image: image
                ))
            }
        }
    }

    /// Retry identification after subscription purchase
    func retryPendingIdentification(subscriptionStore: CaptureSubscriptionProviding) async {
        guard let image = pendingImage else { return }
        pendingImage = nil
        let localItems = pendingLocalItems
        let localMonth = pendingLocalMonth
        pendingLocalItems = []
        pendingLocalMonth = nil
        await identifyPlant(
            image: image,
            subscriptionStore: subscriptionStore,
            localItems: localItems,
            localMonth: localMonth
        )
    }

    func startManualEntry() {
        destination = .review(.manualEntry)
    }

    func reset() {
        selectedItem = nil
        selectedPhotoData = nil
        destination = nil
        isIdentifying = false
        identificationError = nil
    }
}
