//
//  RecentFindRow.swift
//  Fieldnote
//
//  Compact paper row for the Journal feed ("field paper, glass chrome"):
//  every recent find after the hero card renders as a scannable journal line —
//  thumbnail, names, location · time — on an opaque surface card.
//

import SwiftUI

struct RecentFindRow: View {
    var commonName: String
    var scientificName: String
    var locationName: String
    var relativeDate: String
    /// Optional real photo; falls back to a themed gradient thumbnail.
    var image: Image? = nil
    var palette: FindPalette = .forest

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 2) {
                Text(commonName)
                    .font(FieldType.bodyEmphasized)
                    .foregroundStyle(FieldColor.ink)
                    .lineLimit(1)
                Text(scientificName)
                    .font(FieldType.scientificFootnote)
                    .italic()
                    .foregroundStyle(FieldColor.mutedInk)
                    .lineLimit(1)
                Text("\(locationName) · \(relativeDate)")
                    .font(FieldType.caption)
                    .foregroundStyle(FieldColor.tertiaryInk)
                    .lineLimit(1)
                    .padding(.top, 2)
            }

            Spacer(minLength: FieldSpace.sm)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FieldColor.tertiaryInk)
        }
        .padding(12)
        .background(FieldColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .fieldShadow(FieldShadow.card)
    }

    private var thumbnail: some View {
        ZStack {
            if let image {
                image.resizable().scaledToFill()
            } else {
                palette.gradient
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview("Recent find row · Standard") {
    VStack(spacing: 12) {
        RecentFindRow(commonName: "Goldenrod", scientificName: "Solidago canadensis",
                      locationName: "Lakeside Trail", relativeDate: "4 days ago",
                      palette: .golden)
        RecentFindRow(commonName: "New England Aster", scientificName: "Symphyotrichum novae-angliae",
                      locationName: "Meadow Loop", relativeDate: "1 week ago",
                      palette: .aster)
    }
    .padding()
    .background(FieldColor.canvasBottom)
}
