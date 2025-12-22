//
//  SectionHeader.swift
//  Fieldnote
//
//  Section header component with small caps/meta style
//

import SwiftUI

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(FieldType.sectionHeader)
            .foregroundColor(FieldColor.mutedInk)
            .tracking(0.5)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: FieldSpace.lg) {
        SectionHeader(title: "Recently Encountered")

        FieldCard {
            Text("Plant card would go here")
        }

        SectionHeader(title: "All Plants")

        FieldCard {
            Text("Another plant card")
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.paper)
}
