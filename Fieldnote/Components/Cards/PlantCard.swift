//
//  PlantCard.swift
//  Fieldnote
//
//  Card component for displaying a plant in grid or list layouts
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
        FieldCard {
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
            // Colored placeholder with symbol
            placeholderImage
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                // Common name
                Text(plant.commonName)
                    .font(FieldType.bodyEmphasized)
                    .foregroundColor(FieldColor.ink)
                    .lineLimit(2)

                // Scientific name
                ScientificNameText(plant.scientificName, size: .footnote)
                    .lineLimit(1)

                // Confidence and encounter count
                HStack {
                    ConfidencePill(confidence: plant.averageConfidence)

                    Spacer()

                    HStack(spacing: FieldSpace.xs) {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                        Text("\(plant.encounterCount)")
                            .font(FieldType.caption)
                    }
                    .foregroundColor(FieldColor.mutedInk)
                }
            }
        }
    }

    // MARK: - List Layout

    private var listContent: some View {
        HStack(spacing: FieldSpace.sm) {
            // Smaller placeholder
            placeholderImage
                .frame(width: 80, height: 80)
                .cornerRadius(FieldRadius.sm)

            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                // Common name
                Text(plant.commonName)
                    .font(FieldType.bodyEmphasized)
                    .foregroundColor(FieldColor.ink)

                // Scientific name
                ScientificNameText(plant.scientificName, size: .footnote)

                HStack {
                    ConfidencePill(confidence: plant.averageConfidence)

                    Spacer()

                    HStack(spacing: FieldSpace.xs) {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                        Text("\(plant.encounterCount)")
                            .font(FieldType.caption)
                    }
                    .foregroundColor(FieldColor.mutedInk)
                }
            }

            Spacer()
        }
    }

    // MARK: - Placeholder Image

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .fill(placeholderColor)

            Image(systemName: plant.displayPlaceholder)
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
        }
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
    .background(FieldColor.paper)
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
    .background(FieldColor.paper)
}
