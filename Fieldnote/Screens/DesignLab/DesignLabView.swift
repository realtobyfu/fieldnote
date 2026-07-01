//
//  DesignLabView.swift
//  Fieldnote
//
//  DEBUG design sandbox — previews the redesigned Journal home (Blend direction:
//  light "Herbarium" base + immersive "Dusk" photo treatment) without needing the
//  full app wired up. Not shipped in the tab bar; use Xcode Previews or mount
//  temporarily to render on a simulator.
//

#if DEBUG
import SwiftUI

struct DesignLabView: View {
    /// Top inset so the feed scrolls *under* the pinned glass header.
    private let headerInset: CGFloat = 140

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [FieldColor.canvasTop, FieldColor.canvasBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: FieldSpace.md) {
                    Color.clear.frame(height: headerInset)

                    sectionLabel

                    RecentFindCard(
                        commonName: "Red Maple", scientificName: "Acer rubrum",
                        locationName: "Riverside Park", relativeDate: "2 days ago",
                        isNewSpecies: true, height: 300, palette: .autumn
                    )

                    CollectionProgressRow(discovered: 48, total: 78)

                    RecentFindCard(
                        commonName: "Goldenrod", scientificName: "Solidago canadensis",
                        locationName: "Lakeside Trail", relativeDate: "4 days ago",
                        palette: .golden
                    )

                    RecentFindCard(
                        commonName: "New England Aster", scientificName: "Symphyotrichum novae-angliae",
                        locationName: "Meadow Loop", relativeDate: "5 days ago",
                        palette: .aster
                    )
                }
                .padding(.horizontal, FieldSpace.md)
                .padding(.bottom, 48)
            }

            JournalStatusHeader(
                greeting: "Good morning, Toby",
                dateLine: "Tuesday · Oct 14",
                streak: 12,
                challengeName: "Autumn Challenge",
                challengeProgress: 4,
                challengeTarget: 10
            )
            .padding(.horizontal, 14)
            .padding(.top, FieldSpace.sm)
        }
    }

    private var sectionLabel: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Recent finds")
                .font(FieldType.title3)
                .foregroundStyle(FieldColor.ink)
            Spacer()
            Text("All collection ›")
                .font(FieldType.footnote.weight(.semibold))
                .foregroundStyle(FieldColor.accentDeep)
        }
        .padding(.horizontal, 4)
    }
}

#Preview("Journal — Blend") {
    DesignLabView()
}
#endif
