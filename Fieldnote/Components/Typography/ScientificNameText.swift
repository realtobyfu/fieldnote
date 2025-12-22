//
//  ScientificNameText.swift
//  Fieldnote
//
//  Wrapper for scientific names with italic serif style
//

import SwiftUI

struct ScientificNameText: View {
    let text: String
    let size: ScientificNameSize

    enum ScientificNameSize {
        case body
        case callout
        case footnote

        var font: Font {
            switch self {
            case .body: return FieldType.scientificBody
            case .callout: return FieldType.scientificCallout
            case .footnote: return FieldType.scientificFootnote
            }
        }
    }

    init(_ text: String, size: ScientificNameSize = .body) {
        self.text = text
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(size.font)
            .italic()
            .foregroundColor(FieldColor.mutedInk)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: FieldSpace.md) {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            Text("Common Dandelion")
                .font(FieldType.title2)
                .foregroundColor(FieldColor.ink)

            ScientificNameText("Taraxacum officinale", size: .body)
        }

        Divider()

        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            Text("White Clover")
                .font(FieldType.callout)
                .foregroundColor(FieldColor.ink)

            ScientificNameText("Trifolium repens", size: .callout)
        }

        Divider()

        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            Text("In a smaller context:")
                .font(FieldType.caption)

            ScientificNameText("Juniperus virginiana", size: .footnote)
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.paper)
}
