//
//  ExploreSection.swift
//  Fieldnote
//
//  Section component with horizontal scroll for Explore screen
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
                        .foregroundColor(FieldColor.mutedInk)
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
            .foregroundColor(FieldColor.mutedInk)
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
                        .foregroundColor(FieldColor.mutedInk)
                }
            }
            .padding(.horizontal, FieldSpace.md)

            if catalogPlants.isEmpty {
                Text("You've discovered all plants!")
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.mutedInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FieldSpace.xl)
                    .padding(.horizontal, FieldSpace.md)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.sm) {
                        ForEach(catalogPlants) { catalogPlant in
                            UndiscoveredPlantCard(catalogPlant: catalogPlant)
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
                        .foregroundColor(FieldColor.mutedInk)
                }
            }
            .padding(.horizontal, FieldSpace.md)

            if totalCount == 0 {
                Text("No plants in this area yet")
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.mutedInk)
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
                            UndiscoveredPlantCard(catalogPlant: catalogPlant)
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
            // Placeholder image
            ZStack {
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .fill(placeholderColor)

                Image(systemName: plant.displayPlaceholder)
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 140, height: 100)

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.commonName)
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.ink)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)

                HStack {
                    ConfidencePill(confidence: plant.averageConfidence)

                    Spacer()

                    Text("\(plant.encounterCount)")
                        .font(FieldType.caption2)
                        .foregroundColor(FieldColor.mutedInk)
                }
            }
        }
        .frame(width: 140)
    }

    private var placeholderColor: Color {
        let colors: [Color] = [
            FieldColor.accent,
            FieldColor.botanicalBrown,
            Color.green.opacity(0.6),
            Color.blue.opacity(0.4),
            Color.orange.opacity(0.5),
            Color.purple.opacity(0.5)
        ]
        let hash = abs(plant.id.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Undiscovered Plant Card (Faded)

struct UndiscoveredPlantCard: View {
    let catalogPlant: CatalogPlant

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            // Placeholder image (faded)
            ZStack {
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .fill(FieldColor.separator)

                Image(systemName: catalogPlant.defaultPlaceholder)
                    .font(.system(size: 32))
                    .foregroundColor(FieldColor.mutedInk.opacity(0.5))
            }
            .frame(width: 140, height: 100)

            VStack(alignment: .leading, spacing: 2) {
                Text(catalogPlant.commonName)
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.mutedInk)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)

                Text("Not discovered")
                    .font(FieldType.caption2)
                    .foregroundColor(FieldColor.mutedInk.opacity(0.6))
            }
        }
        .frame(width: 140)
        .opacity(0.6)
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
        .background(FieldColor.paper)
        .navigationDestination(for: Plant.self) { plant in
            PlantDetailView(plant: plant)
        }
    }
    .environment(\.appStore, store)
}
