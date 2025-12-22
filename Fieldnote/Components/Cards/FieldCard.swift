//
//  FieldCard.swift
//  Fieldnote
//
//  Base card component with surface background, radius, shadow, and padding
//

import SwiftUI

struct FieldCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(FieldSpace.cardPadding)
            .background(FieldColor.surface)
            .cornerRadius(FieldRadius.card)
            .fieldShadow(FieldShadow.card)
    }
}

#Preview("Simple Card") {
    FieldCard {
        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            Text("Card Title")
                .font(FieldType.title3)
                .foregroundColor(FieldColor.ink)

            Text("This is a field card with standard styling. It includes surface background, rounded corners, subtle shadow, and appropriate padding.")
                .font(FieldType.body)
                .foregroundColor(FieldColor.mutedInk)
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.paper)
}

#Preview("Multiple Cards") {
    VStack(spacing: FieldSpace.md) {
        FieldCard {
            Text("First Card")
                .font(FieldType.body)
        }

        FieldCard {
            VStack(alignment: .leading) {
                Text("Second Card")
                    .font(FieldType.bodyEmphasized)
                Text("With multiple elements")
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.mutedInk)
            }
        }

        FieldCard {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(FieldColor.accent)
                Text("Card with icon")
            }
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.paper)
}
