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
                // Recently Encountered section
                ExploreSection(
                    title: "Recently Encountered",
                    plants: appStore.recentlyEncountered
                )

                // Location-based sections (discovered + undiscovered)
                ForEach(appStore.mixedPlantsByLocation.prefix(2), id: \.location) { locationGroup in
                    LocationSection(
                        title: "Common in \(locationGroup.location)",
                        discoveredPlants: locationGroup.discovered,
                        undiscoveredPlants: locationGroup.undiscovered
                    )
                }

                // Undiscovered plants from catalog
                CatalogSection(
                    title: "Discover More",
                    catalogPlants: Array(appStore.undiscoveredPlants.prefix(15))
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
