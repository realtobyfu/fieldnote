//
//  SecondaryButton.swift
//  Fieldnote
//
//  Secondary action button with theme styling
//

import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool

    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FieldType.buttonLabel)
                .foregroundColor(isEnabled ? FieldColor.accent : FieldColor.mutedInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                .background(FieldColor.surface)
                .cornerRadius(FieldRadius.button)
                .overlay(
                    RoundedRectangle(cornerRadius: FieldRadius.button)
                        .stroke(isEnabled ? FieldColor.accent : FieldColor.separator, lineWidth: 1.5)
                )
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: FieldSpace.md) {
        PrimaryButton("Primary Action") {
            print("Primary tapped")
        }

        SecondaryButton("Secondary Action") {
            print("Secondary tapped")
        }

        SecondaryButton("Cancel", isEnabled: true) {
            print("Cancel tapped")
        }

        SecondaryButton("Disabled", isEnabled: false) {
            print("Should not print")
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.paper)
}
