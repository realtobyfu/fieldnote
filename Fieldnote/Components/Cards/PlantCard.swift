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
        switch layout {
        case .grid:
            gridCard
        case .list:
            VintageCard { listContent }
        }
    }

    // MARK: - Grid Layout

    /// A self-contained, uniform-height card: an edge-to-edge image plate over an
    /// opaque surface, with a fixed 2-line name block so the grid columns stay aligned.
    private var gridCard: some View {
        VStack(spacing: 0) {
            PlantIllustrationView(plant: plant, size: .card, fill: true)
                .frame(height: 132)
                .frame(maxWidth: .infinity)
                .background(FieldColor.illustrationBg)
                .clipped()

            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                // Common name — always reserves 2 lines so all cards match height.
                Text(plant.commonName)
                    .font(FieldType.title3)
                    .foregroundColor(FieldColor.vintageInk)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)

                // Scientific name
                ScientificNameText(plant.scientificName, size: .footnote)
                    .lineLimit(1)

                // Calm metadata: color-coded confidence dot + sighting count.
                HStack(spacing: 6) {
                    Circle()
                        .fill(FieldColor.confidence(for: plant.averageConfidence))
                        .frame(width: 7, height: 7)
                    Text("\(plant.encounterCount) \(plant.encounterCount == 1 ? "sighting" : "sightings")")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, FieldSpace.sm + FieldSpace.xs)
            .padding(.top, FieldSpace.sm)
            .padding(.bottom, FieldSpace.sm + FieldSpace.xs)
        }
        .background(FieldColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FieldRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.card, style: .continuous)
                .stroke(FieldColor.bookBorder.opacity(0.35), lineWidth: 0.5)
        )
        .fieldShadow(FieldShadow.card)
    }

    // MARK: - List Layout

    private var listContent: some View {
        HStack(spacing: FieldSpace.sm) {
            // Smaller botanical illustration
            PlantIllustrationView(plant: plant, size: .thumbnail)

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

// Previews disabled - require SwiftData ModelContainer setup
//#Preview("Grid Layout") {
//    PlantCard(plant: Plant(...), layout: .grid)
//}
