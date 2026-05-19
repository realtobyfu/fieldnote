//
//  ExploreView.swift
//  Fieldnote
//
//  Curated sections view for exploring plants with discovery catalog
//

import SwiftUI

struct ExploreView: View {
    @Environment(\.appStore) private var store
    @State private var searchQuery = ""

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
        .searchable(text: $searchQuery, prompt: "Search plants")
        .navigationDestination(for: Plant.self) { plant in
            PlantDetailView(plant: plant)
        }
        .navigationDestination(for: CatalogPlant.self) { catalogPlant in
            CatalogPlantDetailView(catalogPlant: catalogPlant)
        }
    }

    private var trimmedQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private func exploreContent(appStore: AppStore) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.xl) {
                if trimmedQuery.isEmpty {
                    browseSections(appStore: appStore)
                } else {
                    searchResults(appStore: appStore)
                }
            }
            .padding(.vertical, FieldSpace.md)
        }
        .refreshable {
            await appStore.refresh()
        }
    }

    @ViewBuilder
    private func browseSections(appStore: AppStore) -> some View {
        // TODO: GPS-based nearby plants section
        //                NearMeSection()

        ExploreSection(
            title: "Recently Encountered",
            plants: appStore.recentlyEncountered
        )

        let customPlants = appStore.customPlants
        if !customPlants.isEmpty {
            ExploreSection(
                title: "Your Custom Plants",
                plants: customPlants
            )
        }

        FullCatalogSection(
            catalogPlants: appStore.catalogPlants,
            isDiscovered: appStore.isDiscovered
        )
    }

    @ViewBuilder
    private func searchResults(appStore: AppStore) -> some View {
        let matchedPlants = appStore.searchPlants(trimmedQuery)
        let matchedCatalog = appStore.searchCatalog(trimmedQuery)

        if matchedPlants.isEmpty && matchedCatalog.isEmpty {
            ContentUnavailableView.search(text: trimmedQuery)
                .padding(.top, FieldSpace.xl)
        } else {
            if !matchedPlants.isEmpty {
                ExploreSection(
                    title: "Your Plants",
                    plants: matchedPlants
                )
            }

            if !matchedCatalog.isEmpty {
                CatalogSection(
                    title: "Catalog",
                    catalogPlants: matchedCatalog
                )
            }
        }
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    ExploreView()
//}
