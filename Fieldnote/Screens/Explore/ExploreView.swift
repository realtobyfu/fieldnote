//
//  ExploreView.swift
//  Fieldnote
//
//  Curated sections view for exploring plants with discovery catalog
//

import SwiftUI

struct ExploreView: View {
    @Environment(\.appStore) var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.xl) {
                // Recently Encountered section
                ExploreSection(
                    title: "Recently Encountered",
                    plants: store.recentlyEncountered
                )

                // Location-based sections
                ForEach(store.plantsByLocation.prefix(5), id: \.location) { locationGroup in
                    ExploreSection(
                        title: "Common in \(locationGroup.location)",
                        plants: locationGroup.plants
                    )
                }

                // Undiscovered plants from catalog
                CatalogSection(
                    title: "Discover More",
                    catalogPlants: Array(store.undiscoveredPlants.prefix(15))
                )
            }
            .padding(.vertical, FieldSpace.md)
        }
        .background(FieldColor.paper)
        .navigationTitle("Explore")
        .navigationDestination(for: Plant.self) { plant in
            PlantDetailView(plant: plant)
        }
    }
}

#Preview {
    let store = AppStore()
    return NavigationStack {
        ExploreView()
    }
    .environment(\.appStore, store)
}

#Preview("Empty State") {
    let store = AppStore()
    store.plants = []
    return NavigationStack {
        ExploreView()
    }
    .environment(\.appStore, store)
}
