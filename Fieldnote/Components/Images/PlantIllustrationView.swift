//
//  PlantIllustrationView.swift
//  Fieldnote
//
//  Displays a plant illustration or a user-provided image
//

import SwiftUI
import UIKit

struct PlantIllustrationView: View {
    let plant: Plant
    let size: BotanicalIllustrationView.IllustrationSize

    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var fallbackPhoto: UIImage?
    @State private var isLoadingFallback = false

    init(plant: Plant, size: BotanicalIllustrationView.IllustrationSize = .card) {
        self.plant = plant
        self.size = size
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                customIllustration(image)
            } else if hasCustomIllustration {
                loadingPlaceholder
            } else if hasBuiltInIllustration {
                BotanicalIllustrationView(plant.commonName, family: plant.family, size: size)
            } else if size != .hero, let photo = fallbackPhoto {
                // Show encounter photo for card sizes only (not hero)
                userPhotoView(photo)
            } else if size != .hero && isLoadingFallback {
                loadingPlaceholder
            } else {
                // Hero size OR no fallback photo available
                BotanicalIllustrationView(plant.commonName, family: plant.family, size: size)
            }
        }
        .frame(width: size.dimensions.width, height: size.dimensions.height)
        .frame(maxWidth: size == .hero ? .infinity : nil)
        .task {
            await loadCustomIllustrationIfNeeded()
            await loadFallbackPhotoIfNeeded()
        }
    }

    private var hasCustomIllustration: Bool {
        guard let filename = plant.customIllustrationFileName else { return false }
        return !filename.isEmpty
    }

    private var hasBuiltInIllustration: Bool {
        IllustrationService.hasIllustration(for: plant.commonName, family: plant.family)
    }

    @MainActor
    private func loadCustomIllustrationIfNeeded() async {
        guard loadedImage == nil,
              let filename = plant.customIllustrationFileName,
              !filename.isEmpty,
              !isLoading else { return }

        isLoading = true
        let loaded = await PlantIllustrationStorageService.shared.loadIllustration(filename: filename)
        loadedImage = loaded
        isLoading = false
    }

    @MainActor
    private func loadFallbackPhotoIfNeeded() async {
        // Only load for non-hero sizes when no other illustration exists
        guard size != .hero,
              !hasCustomIllustration,
              !hasBuiltInIllustration,
              fallbackPhoto == nil,
              !isLoadingFallback else { return }

        // Access encounters and find photo filename
        // Note: SwiftData may lazy-load the relationship here
        guard let encounters = plant.encounters,
              !encounters.isEmpty else { return }

        let sortedEncounters = encounters.sorted { $0.date > $1.date }
        guard let filename = sortedEncounters.compactMap({ $0.photoFileName }).first else { return }

        isLoadingFallback = true
        let loadedPhoto = await PhotoStorageService.shared.loadPhoto(filename: filename)
        fallbackPhoto = loadedPhoto
        isLoadingFallback = false
    }

    private func customIllustration(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .background(FieldColor.illustrationBg)
            .overlay(
                Rectangle()
                    .fill(FieldColor.sepia.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
            )
            .clipped()
            .cornerRadius(FieldRadius.sm)
    }

    private func userPhotoView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .background(FieldColor.illustrationBg)
            .overlay(
                Rectangle()
                    .fill(FieldColor.sepia.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
            )
            .clipped()
            .cornerRadius(FieldRadius.sm)
    }

    private var loadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .fill(FieldColor.illustrationBg)

            ProgressView()
                .tint(FieldColor.fadedInk)
        }
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .stroke(FieldColor.bookBorder.opacity(0.4), lineWidth: 0.5)
        )
    }
}
