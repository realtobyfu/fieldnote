import SwiftUI
import UIKit

/// A compact plate without another card, mat, or border around the artwork.
struct BookPlantImage: View {
    let plant: Plant
    @State private var encounterPhoto: UIImage?

    private var latestPhotoFilename: String? {
        (plant.encounters ?? []).sorted { $0.date > $1.date }.compactMap(\.photoFileName).first
    }

    var body: some View {
        Group {
            if plant.customIllustrationFileName?.isEmpty == false {
                PlantIllustrationView(plant: plant, fill: true)
            } else if let name = IllustrationService.illustrationName(
                for: plant.commonName, scientificName: plant.scientificName, family: plant.family
            ) {
                BundledImagery.image(name).resizable().scaledToFit().blendMode(.multiply)
            } else if let encounterPhoto {
                Image(uiImage: encounterPhoto).resizable().scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
            } else {
                // A typographic index mark never suggests a different plant's anatomy.
                VStack(spacing: 6) {
                    Text(String(plant.commonName.prefix(1)).uppercased())
                        .font(FieldBook.heading).foregroundStyle(FieldColor.botanicalBrown)
                    Rectangle().fill(FieldColor.botanicalBrown.opacity(0.3))
                        .frame(width: 24, height: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FieldBook.wash.opacity(0.35))
            }
        }
        .accessibilityHidden(true)
        .task(id: latestPhotoFilename) {
            guard plant.customIllustrationFileName?.isEmpty != false,
                  !IllustrationService.hasIllustration(for: plant.commonName,
                      scientificName: plant.scientificName, family: plant.family) else { return }
            guard let filename = latestPhotoFilename else { encounterPhoto = nil; return }
            encounterPhoto = await PhotoStorageService.shared.loadPhoto(filename: filename)
        }
    }
}
