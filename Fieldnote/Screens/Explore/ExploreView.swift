//
//  ExploreView.swift
//  Fieldnote
//
//  Curated sections view for exploring plants with discovery catalog
//

import SwiftUI

struct ExploreView: View {
    @Environment(\.appStore) private var store

    var body: some View {
        Group {
            if let appStore = store {
                exploreContent(appStore: appStore)
            } else {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app.")
                )
            }
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

    @ViewBuilder
    private func exploreContent(appStore: AppStore) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.xl) {
                // GPS-based nearby plants section
                NearMeSection()

                // Recently Encountered section
                ExploreSection(
                    title: "Recently Encountered",
                    plants: appStore.recentlyEncountered
                )

                // Full plant catalog grid
                FullCatalogSection(
                    catalogPlants: appStore.catalogPlants,
                    isDiscovered: appStore.isDiscovered
                )
            }
            .padding(.vertical, FieldSpace.md)
        }
        .refreshable {
            await appStore.refresh()
        }
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    ExploreView()
//}
