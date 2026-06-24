//
//  AlternativeCandidatesCard.swift
//  Fieldnote
//
//  "Other possibilities" card shown in the capture review sheet when the
//  identification reranker returns close runner-up candidates. These are offered
//  as "did you mean…?", not as equal claims — the visual signal stays dominant.
//  See LocaleAwareCatalogImplementationPlan.md (B4).
//

import SwiftUI

struct AlternativeCandidatesCard: View {
    let alternatives: [RankedCandidate]
    let onSelect: (PlantIdentificationCandidate) -> Void

    var body: some View {
        VintageCard {
            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                HStack(spacing: FieldSpace.xs) {
                    Image(systemName: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(FieldColor.mutedInk)
                    Text("Other possibilities")
                        .font(FieldType.bodyEmphasized)
                        .foregroundColor(FieldColor.vintageInk)
                }

                Text("If this isn't quite right, tap a closer match.")
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.fadedInk)

                ForEach(alternatives) { ranked in
                    Button {
                        onSelect(ranked.candidate)
                    } label: {
                        row(for: ranked)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func row(for ranked: RankedCandidate) -> some View {
        HStack(spacing: FieldSpace.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ranked.candidate.commonName)
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.ink)
                    .lineLimit(1)
                Text(ranked.candidate.scientificName)
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.fadedInk)
                    .italic()
                    .lineLimit(1)
                if ranked.hasLocalSupport {
                    Text("Also reported nearby")
                        .font(FieldType.caption2)
                        .foregroundColor(FieldColor.accent)
                }
            }

            Spacer()

            Text("\(Int((ranked.candidate.visualConfidence * 100).rounded()))%")
                .font(FieldType.caption)
                .foregroundColor(FieldColor.mutedInk)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(FieldColor.fadedInk)
        }
        .padding(FieldSpace.sm)
        .background(FieldColor.surface)
        .cornerRadius(FieldRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
        )
    }
}

#if DEBUG
#Preview("Alternative Candidates") {
    ScrollView {
        AlternativeCandidatesCard(
            alternatives: [
                RankedCandidate(
                    candidate: PlantIdentificationCandidate(
                        commonName: "California Poppy",
                        scientificName: "Eschscholzia californica",
                        family: "Papaveraceae",
                        visualConfidence: 0.74,
                        gbifTaxonKey: nil
                    ),
                    combinedScore: 0.81,
                    hasLocalSupport: true,
                    nearbyObservationCount: 940
                ),
                RankedCandidate(
                    candidate: PlantIdentificationCandidate(
                        commonName: "Mexican Poppy",
                        scientificName: "Eschscholzia mexicana",
                        family: "Papaveraceae",
                        visualConfidence: 0.41,
                        gbifTaxonKey: nil
                    ),
                    combinedScore: 0.42,
                    hasLocalSupport: false,
                    nearbyObservationCount: 0
                )
            ],
            onSelect: { _ in }
        )
        .padding()
    }
    .background(FieldColor.paper)
}
#endif
