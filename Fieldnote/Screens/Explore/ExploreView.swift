//
//  ExploreView.swift
//  Fieldnote
//
//  Curated sections view for exploring plants with discovery catalog
//

import SwiftUI

struct ExploreView: View {
    @Environment(\.appStore) private var store

    private var appStore: AppStore {
        guard let store = store else {
            fatalError("AppStore not found in environment")
        }
        return store
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.xl) {
                // GPS-based nearby plants section
                NearMeSection()

                // Recently Encountered section
                ExploreSection(
                    title: "Recently Encountered",
                    plants: appStore.recentlyEncountered
                )

                // TODO: Re-enable location-based sections when regional plant data is available
                // Option 1: Add `regions: [String]` to CatalogPlant (e.g., ["Northeast", "Mid-Atlantic"])
                // - Detect user's region from GPS coordinates
                // - Only suggest plants that actually grow in that region
                // - Generate regional data for 50 plants similar to nativeRange
                //
                // ForEach(appStore.mixedPlantsByLocation.prefix(2), id: \.location) { locationGroup in
                //     LocationSection(
                //         title: "Common in \(locationGroup.location)",
                //         discoveredPlants: locationGroup.discovered,
                //         undiscoveredPlants: locationGroup.undiscovered
                //     )
                // }

                // Full plant catalog grid
                FullCatalogSection(
                    catalogPlants: appStore.catalogPlants,
                    isDiscovered: appStore.isDiscovered
                )
            }
            .padding(.vertical, FieldSpace.md)
        }
        .background(FieldColor.paper)
        .navigationTitle("Explore")
        .navigationDestination(for: Plant.self) { plant in
            PlantDetailView(plant: plant)
        }
        .navigationDestination(for: CatalogPlant.self) { catalogPlant in
            CatalogPlantDetailView(catalogPlant: catalogPlant)
        }
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    ExploreView()
//}
