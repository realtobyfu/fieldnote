//
//  ExpandablePlantSummary.swift
//  Fieldnote
//
//  Compact plant prose with an accessible inline disclosure control.
//

import SwiftUI

struct ExpandablePlantSummary: View {
    let text: String

    @State private var isExpanded = false

    private let collapsedLineLimit = 4
    private let disclosureCharacterThreshold = 220

    private var needsDisclosure: Bool {
        text.count > disclosureCharacterThreshold
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            Text(text)
                .font(FieldType.callout)
                .foregroundStyle(FieldColor.ink)
                .lineLimit(isExpanded || !needsDisclosure ? nil : collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: true)

            if needsDisclosure {
                Button(action: toggleExpanded) {
                    HStack(spacing: FieldSpace.xs) {
                        Text(isExpanded ? "Show less" : "Read more")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .font(FieldType.subheadline)
                    .foregroundStyle(FieldColor.accent)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            }
        }
    }

    private func toggleExpanded() {
        isExpanded.toggle()
    }
}

#Preview("Expandable plant summary · Long text") {
    ExpandablePlantSummary(
        text: "Oxalis pes-caprae (Bermuda buttercup, African wood-sorrel, Bermuda sorrel, buttercup oxalis, Cape sorrel, English weed, goat's-foot, sourgrass, soursob and soursop; Afrikaans: suring) is a species of tristylous flowering plant in the wood sorrel family Oxalidaceae. Oxalis cernua is a less common synonym for this species."
    )
    .padding(FieldSpace.md)
    .background(FieldColor.agedPaper)
}

#Preview("Expandable plant summary · Short text") {
    ExpandablePlantSummary(text: "A compact plant description that does not need a disclosure control.")
        .padding(FieldSpace.md)
        .background(FieldColor.agedPaper)
}
