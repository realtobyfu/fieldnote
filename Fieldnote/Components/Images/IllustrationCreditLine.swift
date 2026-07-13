//
//  IllustrationCreditLine.swift
//  Fieldnote
//
//  Renders an attribution caption beneath a botanical illustration — but only
//  for real, human-authored plates. AI-generated house illustrations resolve to
//  no credit and this view renders nothing.
//

import SwiftUI

/// A small attribution caption for a botanical illustration, resolved from the
/// plant's illustration asset. Renders `EmptyView` when the illustration is an
/// original (AI-generated) plate, so callers can drop it in unconditionally.
struct IllustrationCreditLine: View {
    let plantName: String
    let family: String?
    var scientificName: String? = nil

    init(plantName: String, family: String? = nil, scientificName: String? = nil) {
        self.plantName = plantName
        self.family = family
        self.scientificName = scientificName
    }

    private var credit: IllustrationCredit? {
        IllustrationService.credit(for: plantName, scientificName: scientificName, family: family)
    }

    var body: some View {
        if let credit {
            HStack(spacing: FieldSpace.xs) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 9))
                    .foregroundColor(FieldColor.fadedInk.opacity(0.7))

                if let sourceURL = credit.sourceURL {
                    Link(destination: sourceURL) {
                        captionText
                    }
                } else {
                    captionText
                }

                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Illustration attribution: \(credit.captionText), \(credit.license.displayName)")
        }
    }

    @ViewBuilder
    private var captionText: some View {
        if let credit {
            Text(credit.captionText)
                .font(FieldType.caption2)
                .italic()
                .foregroundColor(FieldColor.fadedInk)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview("With credit") {
    // Illustrative only — the shipped registry is empty until real plates land.
    VStack(alignment: .leading) {
        Text("Sample attribution rendering")
            .font(FieldType.caption)
        HStack(spacing: FieldSpace.xs) {
            Image(systemName: "paintpalette")
                .font(.system(size: 9))
                .foregroundColor(FieldColor.fadedInk.opacity(0.7))
            Text("After P.-J. Redouté · Les Roses, 1817")
                .font(FieldType.caption2)
                .italic()
                .foregroundColor(FieldColor.fadedInk)
        }
    }
    .padding()
    .background(FieldColor.agedPaper)
}

#Preview("No credit (AI-generated)") {
    // Renders nothing, as intended for uncredited house illustrations.
    IllustrationCreditLine(plantName: "Dandelion")
        .padding()
        .background(FieldColor.agedPaper)
}
