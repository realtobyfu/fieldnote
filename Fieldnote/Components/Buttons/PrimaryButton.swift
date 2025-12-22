//
//  PrimaryButton.swift
//  Fieldnote
//
//  Primary CTA button with theme styling
//

import SwiftUI

struct PrimaryButton: View {
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                .background(isEnabled ? FieldColor.accent : FieldColor.mutedInk)
                .cornerRadius(FieldRadius.button)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: FieldSpace.md) {
        PrimaryButton("Save Plant") {
            print("Save tapped")
        }

        PrimaryButton("Add Encounter") {
            print("Add tapped")
        }

        PrimaryButton("Disabled Button", isEnabled: false) {
            print("Should not print")
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.paper)
}
