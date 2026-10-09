import SwiftUI

struct NearbyPlantRoute: Hashable {
    let plant: CatalogPlant
}

struct NearbyFieldGuide: View {
    let items: [LocalCatalogItem]
    let isDiscovered: (CatalogPlant) -> Bool

    private var common: [LocalCatalogItem] {
        items.filter { $0.explanationCodes.contains(.commonlyReported) }
    }
    private var featured: [LocalCatalogItem] { Array((common.isEmpty ? items : common).prefix(3)) }
    private var remaining: [LocalCatalogItem] {
        let featuredIDs = Set(featured.map(\.id))
        return Array(items.filter { !featuredIDs.contains($0.id) }.prefix(20))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(common.isEmpty ? "Reported here" : "Commonly reported").font(FieldBook.heading)
                .padding(.horizontal, 24).accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(featured) { item in
                        NavigationLink(value: NearbyPlantRoute(plant: item.catalogPlant)) {
                            VStack(alignment: .leading, spacing: 10) {
                                NearbyPlantImage(plant: item.catalogPlant)
                                    .frame(width: 248, height: 170).clipped()
                                    .clipShape(.rect(cornerRadius: 14))
                                    .specimenSource(item.catalogPlant.id)
                                Text(item.catalogPlant.commonName).font(FieldBook.name)
                                status(item.catalogPlant)
                                if PlantPhotoService.photoNames(for: item.catalogPlant.commonName).isEmpty,
                                   item.catalogPlant.photoURL != nil,
                                   let credit = item.catalogPlant.photoAttribution {
                                    Text(credit).font(.caption2).foregroundStyle(FieldColor.mutedInk)
                                        .lineLimit(2)
                                }
                            }
                            .frame(width: 248, alignment: .leading)
                            .foregroundStyle(FieldColor.ink)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            if !remaining.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    Text("More to look for").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
                    ForEach(remaining) { item in
                        NavigationLink(value: NearbyPlantRoute(plant: item.catalogPlant)) {
                            HStack(spacing: 16) {
                                NearbyPlantImage(plant: item.catalogPlant)
                                    .frame(width: 78, height: 78).clipped()
                                    .clipShape(.rect(cornerRadius: 10))
                                    .specimenSource(item.catalogPlant.id)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.catalogPlant.commonName).font(.body.weight(.medium))
                                    status(item.catalogPlant)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").font(.caption2)
                            }
                            .foregroundStyle(FieldColor.ink)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
        }
    }

    private func status(_ plant: CatalogPlant) -> some View {
        Label(isDiscovered(plant) ? "In your herbarium" : "Yet to discover",
              systemImage: isDiscovered(plant) ? "checkmark.circle" : "circle.dotted")
            .font(.caption).foregroundStyle(FieldBook.cover)
    }
}
