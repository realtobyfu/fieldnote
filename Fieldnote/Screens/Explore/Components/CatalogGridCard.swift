//
//  CatalogGridCard.swift
//  Fieldnote
//
//  Grid card for catalog plants showing discovered/undiscovered state
//

import SwiftUI

struct CatalogGridCard: View {
    let catalogPlant: CatalogPlant
    let isDiscovered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            // Illustration with discovery badge
            ZStack(alignment: .topTrailing) {
                if isDiscovered {
                    BotanicalIllustrationView(
                        catalogPlant.commonName,
                        family: catalogPlant.family,
                        size: .card
                    )
                } else {
                    UndiscoveredIllustrationView(
                        catalogPlant.commonName,
                        family: catalogPlant.family,
                        size: .card
                    )
                }
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                if isDiscovered {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(FieldColor.accent)
                        .background(
                            Circle()
                                .fill(FieldColor.surface)
                                .frame(width: 18, height: 18)
                        )
                        .padding(FieldSpace.xs)
                }
            }

            // Plant name and habitat
            VStack(alignment: .leading, spacing: 2) {
                Text(catalogPlant.commonName)
                    .font(FieldType.callout)
                    .foregroundColor(isDiscovered ? FieldColor.vintageInk : FieldColor.fadedInk)
                    .lineLimit(2)

//                Text(catalogPlant.habitat.capitalized)
//                    .font(FieldType.caption)
//                    .foregroundColor(FieldColor.fadedInk)
//                    .lineLimit(1)
            }
            .frame(height: 50, alignment: .top)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
