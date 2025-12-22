//
//  FieldShadow.swift
//  Fieldnote
//
//  Shadow presets for the Fieldnote design system
//

import SwiftUI

struct FieldShadow {
    /// Shadow configuration
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    /// Soft shadow for cards
    static let card = Shadow(
        color: Color.black.opacity(0.04),
        radius: 8,
        x: 0,
        y: 2
    )

    /// Elevated shadow for hover/pressed states
    static let cardHover = Shadow(
        color: Color.black.opacity(0.08),
        radius: 12,
        x: 0,
        y: 4
    )

    /// Shadow for modal sheets
    static let modal = Shadow(
        color: Color.black.opacity(0.12),
        radius: 24,
        x: 0,
        y: 8
    )
}

// MARK: - View Extension

extension View {
    /// Apply a Fieldnote shadow style to this view
    func fieldShadow(_ shadow: FieldShadow.Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
