//
//  SectionHeader.swift
//  Fieldnote
//
//  Literary-style section header for vintage book aesthetic
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var showRuledLine: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            if showRuledLine {
                RuledLine(color: FieldColor.bookBorder.opacity(0.6))
            }

            Text(title.uppercased())
                .font(FieldType.sectionHeader)
                .foregroundColor(FieldColor.fadedInk)
                .tracking(1.5)

            if showRuledLine {
                RuledLine(color: FieldColor.bookBorder.opacity(0.6))
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: FieldSpace.lg) {
        SectionHeader(title: "Recently Encountered")

        SectionHeader(title: "With Ruled Lines", showRuledLine: true)
            .padding(.horizontal, FieldSpace.md)

        VintageCard {
            Text("Plant card would go here")
                .font(FieldType.body)
        }

        SectionHeader(title: "All Plants")

        VintageCard {
            Text("Another plant card")
                .font(FieldType.body)
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.agedPaper)
}
