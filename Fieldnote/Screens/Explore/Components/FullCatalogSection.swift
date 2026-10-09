import SwiftUI

/// A general field guide remains available before a nearby area is chosen.
struct FullCatalogSection: View {
    let catalogPlants: [CatalogPlant]
    let isDiscovered: (CatalogPlant) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Field guide").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
                Text("Browse all species in the guide.")
                    .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
            }
            LazyVStack(spacing: 16) {
                ForEach(catalogPlants) { plant in
                    NavigationLink(value: NearbyPlantRoute(plant: plant)) {
                        HStack(spacing: 16) {
                            NearbyPlantImage(plant: plant)
                                .frame(width: 68, height: 78).clipped()
                                .clipShape(.rect(cornerRadius: 10))
                                .specimenSource(plant.id)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(plant.commonName).font(FieldBook.name)
                                Text(plant.scientificName).font(.caption).italic()
                                    .foregroundStyle(FieldColor.mutedInk)
                                if isDiscovered(plant) {
                                    Label("In your herbarium", systemImage: "checkmark.circle")
                                        .font(.caption).foregroundStyle(FieldBook.cover)
                                }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.caption2)
                                .foregroundStyle(FieldColor.mutedInk)
                        }
                        .foregroundStyle(FieldColor.ink).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
        .padding(.horizontal, 24)
    }
}
