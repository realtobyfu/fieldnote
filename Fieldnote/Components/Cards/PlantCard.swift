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
    /// Accession number: the plant's position in the collection by date added.
    /// Shown as specimen-sheet marginalia ("№ 4") on the grid card.
    let collectionNumber: Int?

    enum Layout {
        case grid
        case list
    }

    init(plant: Plant, layout: Layout = .grid, collectionNumber: Int? = nil) {
        self.plant = plant
        self.layout = layout
        self.collectionNumber = collectionNumber
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

    /// A catalog-plate card: edge-to-edge illustration up top (separated from the
    /// caption by a hairline rule, like a plate in a botanical book), then a
    /// left-aligned caption block on warm parchment — accession № + family as a
    /// small-caps eyebrow, the serif name (2 lines reserved for uniform height),
    /// the Latin name, and a quiet small-caps sightings line.
    private var gridCard: some View {
        VStack(spacing: 0) {
            PlantIllustrationView(plant: plant, size: .card, fill: true)
                .frame(height: 132)
                .frame(maxWidth: .infinity)
                .background(FieldColor.illustrationBg)
                .clipped()

            Rectangle()
                .fill(FieldColor.bookBorder.opacity(0.5))
                .frame(height: 0.5)

            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                // Eyebrow: accession number + family, tracked serif caps.
                HStack(spacing: FieldSpace.xs) {
                    Text(accessionLabel)
                        .layoutPriority(1)
                    Text("·")
                    Text(plant.family.uppercased())
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .font(FieldType.plateLabel)
                .tracking(1.2)
                .foregroundColor(FieldColor.sepia.opacity(0.7))

                // Common name — always reserves 2 lines so all cards match height.
                Text(plant.commonName)
                    .font(FieldType.title3)
                    .foregroundColor(FieldColor.vintageInk)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)

                // Scientific name
                ScientificNameText(plant.scientificName, size: .footnote)
                    .lineLimit(1)

                Text(sightingsLabel)
                    .font(FieldType.plateLabel)
                    .tracking(1.4)
                    .foregroundColor(FieldColor.fadedInk)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, FieldSpace.sm + FieldSpace.xs)
            .padding(.top, FieldSpace.sm)
            .padding(.bottom, FieldSpace.sm + FieldSpace.xs)
        }
        .background(FieldColor.parchment)
        .clipShape(RoundedRectangle(cornerRadius: FieldRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.md, style: .continuous)
                .stroke(FieldColor.bookBorder.opacity(0.4), lineWidth: 0.5)
        )
        .fieldShadow(FieldShadow.card)
    }

    private var accessionLabel: String {
        if let collectionNumber {
            return "№ \(collectionNumber)"
        }
        return "№ —"
    }

    private var sightingsLabel: String {
        let count = plant.encounterCount
        return "\(count) \(count == 1 ? "SIGHTING" : "SIGHTINGS")"
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
