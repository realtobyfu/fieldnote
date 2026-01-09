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
    @State private var fallbackHeroPhoto: UIImage?
    @State private var isLoadingFallbackPhoto = false

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
            } else if let heroPhoto = fallbackHeroPhoto {
                userPhoto(heroPhoto)
            } else if isLoadingFallbackPhoto {
                loadingPlaceholder
            } else {
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

    private var fallbackPhotoFilename: String? {
        plant.encounters?
            .sorted { $0.date > $1.date }
            .compactMap { $0.photoFileName }
            .first
    }

    private func loadCustomIllustrationIfNeeded() async {
        guard loadedImage == nil,
              let filename = plant.customIllustrationFileName,
              !filename.isEmpty,
              !isLoading else { return }

        isLoading = true
        loadedImage = await PlantIllustrationStorageService.shared.loadIllustration(filename: filename)
        isLoading = false
    }

    private func loadFallbackPhotoIfNeeded() async {
        guard !hasCustomIllustration,
              !hasBuiltInIllustration,
              fallbackHeroPhoto == nil,
              !isLoadingFallbackPhoto,
              let filename = fallbackPhotoFilename else { return }

        isLoadingFallbackPhoto = true
        let image = await PhotoStorageService.shared.loadPhoto(filename: filename)
        await MainActor.run {
            fallbackHeroPhoto = image
            isLoadingFallbackPhoto = false
        }
    }

    private func customIllustration(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .background(FieldColor.illustrationBg)
            .overlay(
                Rectangle()
                    .fill(FieldColor.sepia.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
            )
            .cornerRadius(FieldRadius.sm)
    }

    private func userPhoto(_ image: UIImage) -> some View {
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
