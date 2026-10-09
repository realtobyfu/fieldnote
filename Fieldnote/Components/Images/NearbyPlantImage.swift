import SwiftUI

/// Photo-first imagery for recognizing a plant outdoors. Missing photos stay honest.
struct NearbyPlantImage: View {
    let plant: CatalogPlant

    var body: some View {
        if let name = PlantPhotoService.photoNames(for: plant.commonName).first {
            BundledImagery.image(name).resizable().scaledToFill()
        } else if let raw = plant.photoURL, let url = URL(string: raw) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else { fallback }
            }
        } else { fallback }
    }

    private var fallback: some View {
        ZStack {
            FieldBook.wash
            if let name = IllustrationService.illustrationName(
                for: plant.commonName, scientificName: plant.scientificName, family: plant.family
            ) {
                BundledImagery.image(name).resizable().scaledToFit()
            } else {
                Image(systemName: "camera.macro").font(.title).foregroundStyle(FieldBook.cover.opacity(0.5))
            }
        }
    }
}
