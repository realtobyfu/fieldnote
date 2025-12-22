//
//  PlantCard.swift
//  Fieldnote
//
//  Card component for displaying a plant with botanical illustration
//

import SwiftUI

struct PlantCard: View {
    let plant: Plant
    let layout: Layout

    enum Layout {
        case grid
        case list
    }

    init(plant: Plant, layout: Layout = .grid) {
        self.plant = plant
        self.layout = layout
    }

    var body: some View {
        VintageCard {
            switch layout {
            case .grid:
                gridContent
            case .list:
                listContent
            }
        }
    }

    // MARK: - Grid Layout

    private var gridContent: some View {
        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            // Botanical illustration
            BotanicalIllustrationView(
                plant.commonName,
                family: plant.family,
                size: .card
            )
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipped()

            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                // Common name
                Text(plant.commonName)
                    .font(FieldType.bodyEmphasized)
                    .foregroundColor(FieldColor.vintageInk)
                    .lineLimit(2)

                // Scientific name
                ScientificNameText(plant.scientificName, size: .footnote)
                    .lineLimit(1)

                // Confidence and encounter count
                HStack {
                    ConfidencePill(confidence: plant.averageConfidence)

                    Spacer()

                    HStack(spacing: FieldSpace.xs) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        Text("\(plant.encounterCount)")
                            .font(FieldType.caption)
                    }
                    .foregroundColor(FieldColor.fadedInk)
                }
            }
        }
    }

    // MARK: - List Layout

    private var listContent: some View {
        HStack(spacing: FieldSpace.sm) {
            // Smaller botanical illustration
            BotanicalIllustrationView(
                plant.commonName,
                family: plant.family,
                size: .thumbnail
            )

            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                // Common name
                Text(plant.commonName)
                    .font(FieldType.bodyEmphasized)
                    .foregroundColor(FieldColor.vintageInk)

                // Scientific name
                ScientificNameText(plant.scientificName, size: .footnote)

                HStack {
                    ConfidencePill(confidence: plant.averageConfidence)

                    Spacer()

                    HStack(spacing: FieldSpace.xs) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        Text("\(plant.encounterCount)")
                            .font(FieldType.caption)
                    }
                    .foregroundColor(FieldColor.fadedInk)
                }
            }

            Spacer()
        }
    }
}

#Preview("Grid Layout") {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: FieldSpace.md) {
            PlantCard(plant: Plant.mockDandelion, layout: .grid)
            PlantCard(plant: Plant.mockClover, layout: .grid)
            PlantCard(plant: Plant.mockCedar, layout: .grid)
            PlantCard(plant: Plant.mockViolet, layout: .grid)
        }
        .padding(FieldSpace.md)
    }
    .background(FieldColor.agedPaper)
}

#Preview("List Layout") {
    ScrollView {
        VStack(spacing: FieldSpace.sm) {
            PlantCard(plant: Plant.mockDandelion, layout: .list)
            PlantCard(plant: Plant.mockClover, layout: .list)
            PlantCard(plant: Plant.mockCedar, layout: .list)
            PlantCard(plant: Plant.mockViolet, layout: .list)
            PlantCard(plant: Plant.mockPoisonIvy, layout: .list)
        }
        .padding(FieldSpace.md)
    }
    .background(FieldColor.agedPaper)
}
