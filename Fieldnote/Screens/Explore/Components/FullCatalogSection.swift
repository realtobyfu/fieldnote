//
//  FullCatalogSection.swift
//  Fieldnote
//
//  Full catalog showing all plants in horizontal scrolling rows
//

import SwiftUI

struct FullCatalogSection: View {
    let catalogPlants: [CatalogPlant]
    let isDiscovered: (CatalogPlant) -> Bool

    private let plantsPerRow = 10

    private var discoveredCount: Int {
        catalogPlants.filter { isDiscovered($0) }.count
    }

    /// Split catalog into chunks of 10 for horizontal rows
    private var plantRows: [[CatalogPlant]] {
        stride(from: 0, to: catalogPlants.count, by: plantsPerRow).map { startIndex in
            Array(catalogPlants[startIndex..<min(startIndex + plantsPerRow, catalogPlants.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.lg) {
            // Header
            HStack {
                SectionHeader(title: "Plant Catalog")
                Spacer()
                Text("\(discoveredCount)/\(catalogPlants.count)")
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.fadedInk)
            }
            .padding(.horizontal, FieldSpace.md)

            // Horizontal scrolling rows
            ForEach(Array(plantRows.enumerated()), id: \.offset) { index, rowPlants in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.sm) {
                        ForEach(rowPlants) { catalogPlant in
                            NavigationLink(value: catalogPlant) {
                                CatalogGridCard(
                                    catalogPlant: catalogPlant,
                                    isDiscovered: isDiscovered(catalogPlant)
                                )
                                .frame(width: 140)
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
