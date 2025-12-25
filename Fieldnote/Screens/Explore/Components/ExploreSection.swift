//
//  ExploreSection.swift
//  Fieldnote
//
//  Section components with botanical illustrations for Explore screen
//

import SwiftUI

// MARK: - Discovered Plants Section

struct ExploreSection: View {
    let title: String
    let plants: [Plant]

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            HStack {
                SectionHeader(title: title)
                Spacer()
                if !plants.isEmpty {
                    Text("\(plants.count)")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }
            .padding(.horizontal, FieldSpace.md)

            if plants.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.sm) {
                        ForEach(plants) { plant in
                            NavigationLink(value: plant) {
                                CompactPlantCard(plant: plant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, FieldSpace.md)
                }
            }
        }
    }

    private var emptyState: some View {
        Text("No plants in this category yet")
            .font(FieldType.callout)
            .foregroundColor(FieldColor.fadedInk)
            .italic()
            .frame(maxWidth: .infinity)
            .padding(.vertical, FieldSpace.xl)
            .padding(.horizontal, FieldSpace.md)
    }
}

// MARK: - Undiscovered Plants Section (Catalog)

struct CatalogSection: View {
    let title: String
    let catalogPlants: [CatalogPlant]

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            HStack {
                SectionHeader(title: title)
                Spacer()
                if !catalogPlants.isEmpty {
                    Text("\(catalogPlants.count)")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }
            .padding(.horizontal, FieldSpace.md)

            if catalogPlants.isEmpty {
                Text("You've discovered all plants!")
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
                    .italic()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FieldSpace.xl)
                    .padding(.horizontal, FieldSpace.md)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.sm) {
                        ForEach(catalogPlants) { catalogPlant in
                            NavigationLink(value: catalogPlant) {
                                UndiscoveredPlantCard(catalogPlant: catalogPlant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, FieldSpace.md)
                }
            }
        }
    }
}

// MARK: - Mixed Location Section (Discovered + Undiscovered)

struct LocationSection: View {
    let title: String
    let discoveredPlants: [Plant]
    let undiscoveredPlants: [CatalogPlant]

    private var totalCount: Int {
        discoveredPlants.count + undiscoveredPlants.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            HStack {
                SectionHeader(title: title)
                Spacer()
                if totalCount > 0 {
                    Text("\(discoveredPlants.count)/\(totalCount)")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }
            .padding(.horizontal, FieldSpace.md)

            if totalCount == 0 {
                Text("No plants in this area yet")
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
                    .italic()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FieldSpace.xl)
                    .padding(.horizontal, FieldSpace.md)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.sm) {
                        // Discovered plants first
                        ForEach(discoveredPlants) { plant in
                            NavigationLink(value: plant) {
                                CompactPlantCard(plant: plant)
                            }
                            .buttonStyle(.plain)
                        }

                        // Undiscovered plants after
                        ForEach(undiscoveredPlants) { catalogPlant in
                            NavigationLink(value: catalogPlant) {
                                UndiscoveredPlantCard(catalogPlant: catalogPlant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, FieldSpace.md)
                }
            }
        }
    }
}

// MARK: - Compact Plant Card (Discovered)

struct CompactPlantCard: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            // Botanical illustration
            BotanicalIllustrationView(
                plant.commonName,
                family: plant.family,
                size: .card
            )
            .frame(width: 140, height: 100)

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.commonName)
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.vintageInk)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)

//                HStack {
//                    ConfidencePill(confidence: plant.averageConfidence)
//
//                    Spacer()
//
//                    HStack(spacing: 2) {
//                        Image(systemName: "eye.fill")
//                            .font(.system(size: 9))
//                        Text("\(plant.encounterCount)")
//                            .font(FieldType.caption2)
//                    }
//                    .foregroundColor(FieldColor.fadedInk)
//                }
            }
        }
        .frame(width: 140)
    }
}

// MARK: - Undiscovered Plant Card (Faded)

struct UndiscoveredPlantCard: View {
    let catalogPlant: CatalogPlant

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            // Faded botanical illustration
            UndiscoveredIllustrationView(
                catalogPlant.commonName,
                family: catalogPlant.family,
                size: .card
            )
            .frame(width: 140, height: 100)

            VStack(alignment: .leading, spacing: 2) {
                Text(catalogPlant.commonName)
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)
            }
        }
        .frame(width: 140)
    }
}

#Preview {
    let store = AppStore()
    return NavigationStack {
        ScrollView {
            VStack(spacing: FieldSpace.xl) {
                ExploreSection(title: "Recently Encountered", plants: [
                    Plant.mockDandelion,
                    Plant.mockClover,
                    Plant.mockViolet
                ])

                CatalogSection(title: "Discover More", catalogPlants: Array(CatalogPlant.catalog.prefix(5)))

                ExploreSection(title: "Empty Section", plants: [])
            }
        }
        .background(FieldColor.agedPaper)
        .navigationDestination(for: Plant.self) { plant in
            PlantDetailView(plant: plant)
        }
        .navigationDestination(for: CatalogPlant.self) { catalogPlant in
            PlantDetailView(plant: catalogPlant.asPlant)
        }
    }
    .environment(\.appStore, store)
}
