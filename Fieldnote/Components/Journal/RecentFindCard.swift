//
//  RecentFindCard.swift
//  Fieldnote
//
//  Editorial, full-bleed recent-find card for the Journal feed (Blend redesign).
//  Uses the immersive "Dusk" treatment — photography with a bottom ink scrim and
//  overlaid common name / scientific name / location.
//

import SwiftUI

struct RecentFindCard: View {
    var commonName: String
    var scientificName: String
    var locationName: String
    var relativeDate: String
    var isNewSpecies: Bool = false
    var height: CGFloat = 260
    /// Optional real photo; falls back to a themed gradient placeholder.
    var image: Image? = nil
    var palette: FindPalette = .forest

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Immersive ink scrim so overlaid text stays legible.
            LinearGradient(
                colors: [
                    FieldColor.photoScrim.opacity(0.85),
                    FieldColor.photoScrim.opacity(0.25),
                    .clear
                ],
                startPoint: .bottom, endPoint: .top
            )

            if isNewSpecies {
                newBadge
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(14)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(commonName)
                    .font(FieldType.title2)
                    .foregroundStyle(.white)
                Text(scientificName)
                    .font(FieldType.scientificCallout)
                    .italic()
                    .foregroundStyle(.white.opacity(0.92))
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(locationName) · \(relativeDate)")
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 5)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        // Photo as a background so a real image's intrinsic size can't widen the
        // card past its frame (which previously pushed the whole feed off-screen).
        .background { photo }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .fieldShadow(FieldShadow.cardHover)
    }

    @ViewBuilder private var photo: some View {
        if let image {
            image.resizable().scaledToFill()
        } else {
            palette.gradient
        }
    }

    private var newBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkles")
            Text("New species")
        }
        .font(.system(size: 11.5, weight: .bold))
        .foregroundStyle(FieldColor.accentDeep)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
    }
}

/// Themed gradient placeholders that evoke macro nature photography.
/// Used by the DesignLab sandbox and any photo-less card; real photos replace these.
enum FindPalette {
    case autumn, golden, aster, forest

    var gradient: LinearGradient {
        switch self {
        case .autumn:
            return LinearGradient(
                colors: [Color(red: 0.85, green: 0.42, blue: 0.20), Color(red: 0.36, green: 0.20, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .golden:
            return LinearGradient(
                colors: [Color(red: 0.86, green: 0.70, blue: 0.22), Color(red: 0.30, green: 0.36, blue: 0.16)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .aster:
            return LinearGradient(
                colors: [Color(red: 0.49, green: 0.39, blue: 0.66), Color(red: 0.25, green: 0.32, blue: 0.23)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forest:
            return LinearGradient(
                colors: [Color(red: 0.30, green: 0.46, blue: 0.32), Color(red: 0.12, green: 0.20, blue: 0.13)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            RecentFindCard(commonName: "Red Maple", scientificName: "Acer rubrum",
                           locationName: "Riverside Park", relativeDate: "2 days ago",
                           isNewSpecies: true, height: 300, palette: .autumn)
            RecentFindCard(commonName: "Goldenrod", scientificName: "Solidago canadensis",
                           locationName: "Lakeside Trail", relativeDate: "4 days ago",
                           palette: .golden)
        }
        .padding()
    }
    .background(FieldColor.canvasBottom)
}
