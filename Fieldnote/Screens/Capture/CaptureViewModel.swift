//
//  CaptureViewModel.swift
//  Fieldnote
//
//  View model for capture screen photo handling
//

import Foundation
import PhotosUI
import SwiftUI

@MainActor
@Observable
class CaptureViewModel {
    var selectedItem: PhotosPickerItem?
    var selectedPhotoData: Data?
    var showReviewSheet = false

    // ML identification state
    var isIdentifying = false
    var identificationError: Error?
    var captureMode: CaptureMode?

    func loadPhoto() async {
        guard let item = selectedItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedPhotoData = data

                if let image = UIImage(data: data) {
                    await identifyPlant(image: image)
                }
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    func handleCapturedImage(_ image: UIImage) async {
        await identifyPlant(image: image)
    }

    private func identifyPlant(image: UIImage) async {
        isIdentifying = true
        identificationError = nil

        do {
            let result = try await MockPlantIdentificationService.shared.identify(image: image)
            captureMode = .mlIdentification(result: result, image: image)
            isIdentifying = false
            showReviewSheet = true
        } catch {
            identificationError = error
            isIdentifying = false
            // Still show review sheet but with empty fields
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
