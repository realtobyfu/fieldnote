//
//  FieldModifiers.swift
//  Fieldnote
//
//  Custom view modifiers for the vintage field guide theme
//

import SwiftUI

// MARK: - Vintage TextField

struct VintageTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(FieldType.body)
            .foregroundColor(FieldColor.ink)
            .padding(.horizontal, FieldSpace.sm)
            .padding(.vertical, FieldSpace.sm)
            .background(FieldColor.surface)
            .cornerRadius(FieldRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
            )
    }
}

extension View {
    func vintageTextField() -> some View {
        self
            .textFieldStyle(.plain)
            .modifier(VintageTextFieldModifier())
    }
}
