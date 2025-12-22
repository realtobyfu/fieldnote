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

    func loadPhoto() async {
        guard let item = selectedItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedPhotoData = data
                showReviewSheet = true
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }

    func reset() {
        selectedItem = nil
        selectedPhotoData = nil
        showReviewSheet = false
    }
}
