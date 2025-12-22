//
//  ConfidencePill.swift
//  Fieldnote
//
//  Simple percentage display for confidence (0...1)
//

import SwiftUI

struct ConfidencePill: View {
    let confidence: Double

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(FieldType.caption)
            .foregroundColor(FieldColor.mutedInk)
    }
}

#Preview {
    VStack(spacing: FieldSpace.md) {
        HStack(spacing: FieldSpace.sm) {
            ConfidencePill(confidence: 0.95)
            Text("High confidence (0.95)")
                .font(FieldType.caption)
        }

        HStack(spacing: FieldSpace.sm) {
            ConfidencePill(confidence: 0.75)
            Text("Medium confidence (0.75)")
                .font(FieldType.caption)
        }

        HStack(spacing: FieldSpace.sm) {
            ConfidencePill(confidence: 0.45)
            Text("Low confidence (0.45)")
                .font(FieldType.caption)
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.paper)
}

#Preview("In Cards") {
    VStack(spacing: FieldSpace.md) {
        FieldCard {
            HStack {
                VStack(alignment: .leading) {
                    Text("Common Dandelion")
                        .font(FieldType.bodyEmphasized)
                    ScientificNameText("Taraxacum officinale", size: .callout)
                }
                Spacer()
                ConfidencePill(confidence: 0.92)
            }
        }

        FieldCard {
            HStack {
                VStack(alignment: .leading) {
                    Text("Eastern Red Cedar")
                        .font(FieldType.bodyEmphasized)
                    ScientificNameText("Juniperus virginiana", size: .callout)
                }
                Spacer()
                ConfidencePill(confidence: 0.71)
            }
        }

        FieldCard {
            HStack {
                VStack(alignment: .leading) {
                    Text("Unknown Species")
                        .font(FieldType.bodyEmphasized)
                    ScientificNameText("Needs identification", size: .callout)
                }
                Spacer()
                ConfidencePill(confidence: 0.35)
            }
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.paper)
}
