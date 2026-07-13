//
//  JournalEmptyState.swift
//  Fieldnote
//
//  First-run Journal home, styled as the opening page of a field journal:
//  a plain typographic greeting (no streak/challenge chrome — those only
//  appear once there are entries to count), an unboxed invitation to make
//  the first capture, and a horizontal "specimen shelf" of species
//  reported nearby — real region-pack data when the local catalog has
//  loaded, a mock catalog sample until then.
//

import SwiftUI

struct JournalEmptyState: View {
    /// Ranked nearby species (see JournalView.nearbyPreviewItems for sourcing).
    let nearbyItems: [LocalCatalogItem]
    var greeting: String
    var dateLine: String
    var onCapture: () -> Void
    var onExplore: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                greetingBlock
                    .padding(.top, FieldSpace.sm)

                invitation
                    .padding(.top, FieldSpace.xxl)

                if !nearbyItems.isEmpty {
                    nearbyShelf
                        .padding(.top, FieldSpace.xxl)
                }
            }
            .padding(.bottom, FieldSpace.md)
        }
    }

    // MARK: - Greeting

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(dateLine.uppercased())
                .font(FieldType.caption2)
                .tracking(1.6)
                .foregroundStyle(FieldColor.mutedInk)
            Text(greeting)
                .font(FieldType.title1)
                .foregroundStyle(FieldColor.ink)
        }
        .padding(.horizontal, FieldSpace.md)
    }

    // MARK: - First-entry invitation

    private var invitation: some View {
        VStack(alignment: .leading, spacing: FieldSpace.md) {
            Text("Every field journal starts with a single plant.")
                .font(FieldType.displaySubtitle)
                .foregroundStyle(FieldColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Photograph one and it becomes your first page.")
                .font(FieldType.callout)
                .foregroundStyle(FieldColor.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            PrimaryButton("Capture a Plant", action: onCapture)
                .padding(.top, FieldSpace.xs)
        }
        .padding(.horizontal, FieldSpace.md)
    }

    // MARK: - Growing near you

    private var nearbyShelf: some View {
        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            HStack(alignment: .firstTextBaseline) {
                // Deliberately no region suffix: localeRegionName can be a full
                // street address, which wraps this small-caps label to two lines.
                Text("Growing near you".uppercased())
                    .font(FieldType.sectionHeader)
                    .tracking(1.4)
                    .foregroundStyle(FieldColor.fadedInk)
                    .lineLimit(1)
                Spacer()
                Button(action: onExplore) {
                    Text("Explore ›")
                        .font(FieldType.footnote.weight(.semibold))
                        .foregroundStyle(FieldColor.accentDeep)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, FieldSpace.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: FieldSpace.md) {
                    ForEach(nearbyItems) { item in
                        NavigationLink(value: item.catalogPlant) {
                            ShelfSpecimen(
                                plant: item.catalogPlant,
                                observationCount: item.nearbyObservationCount
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, FieldSpace.md)
            }
        }
    }

}

// MARK: - Shelf specimen

/// An unboxed nearby-species item: the illustration plate with the name and
/// report count beneath, laid directly on the paper canvas.
private struct ShelfSpecimen: View {
    let plant: CatalogPlant
    let observationCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BotanicalIllustrationView(
                plant.commonName,
                family: plant.family,
                size: .card
            )

            Text(plant.commonName)
                .font(FieldType.callout)
                .foregroundStyle(FieldColor.vintageInk)
                .lineLimit(1)

            Text(observationCount > 0 ? "\(observationCount) reports nearby" : plant.family)
                .font(FieldType.caption)
                .foregroundStyle(FieldColor.fadedInk)
                .lineLimit(1)
        }
        .frame(width: 140, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        ZStack {
            LinearGradient(
                colors: [FieldColor.canvasTop, FieldColor.canvasBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            JournalEmptyState(
                nearbyItems: Array(LocaleCatalogPreviewData.items.prefix(4)),
                greeting: "Good morning",
                dateLine: "Saturday · Jul 11",
                onCapture: {},
                onExplore: {}
            )
        }
    }
}
#endif
