//
//  FieldGlass.swift
//  Fieldnote
//
//  Centralized Liquid Glass adoption for the Fieldnote design system.
//
//  Liquid Glass (`.glassEffect`) is iOS 26+. The app's deployment floor is iOS 18,
//  so every glass surface degrades to an opaque "modern paper" surface below 26.
//  This file is the ONLY place the iOS 26 availability check for glass lives — keeping
//  it centralized means the translucent (26+) and opaque (18–25) paths can't drift apart.
//
//  Rule of thumb: glass goes on floating *chrome* and transient controls (tab bar,
//  capture shutter, map controls, status pills); text-heavy reading content stays opaque.
//

import SwiftUI

enum FieldGlass {
    /// Default corner radius for glass cards/controls.
    static let cornerRadius: CGFloat = FieldRadius.lg

    /// Default rounded-rectangle shape used by `fieldGlass()` when no shape is supplied.
    static var defaultShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}

// MARK: - Glass surface modifier

extension View {
    /// Apply Liquid Glass to floating chrome / controls, with an opaque fallback below iOS 26.
    ///
    /// - Parameters:
    ///   - shape: clip/effect shape (default: continuous rounded rect, `FieldRadius.lg`).
    ///   - tint: optional botanical tint blended into the glass; also tints the opaque fallback fill.
    ///   - interactive: whether the glass reacts to touch (iOS 26 only; ignored on the fallback).
    ///   - fallbackFill: opaque surface used below iOS 26 (default: `FieldColor.surface`).
    ///   - fallbackShadow: shadow paired with the opaque fallback (default: `.card`).
    @ViewBuilder
    func fieldGlass(
        in shape: some Shape = FieldGlass.defaultShape,
        tint: Color? = nil,
        interactive: Bool = false,
        fallbackFill: Color = FieldColor.surface,
        fallbackShadow: FieldShadow.Shadow = FieldShadow.card
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                FieldGlass.glass(tint: tint, interactive: interactive),
                in: shape
            )
        } else {
            // Opaque "modern paper" fallback — glass self-separates, so here we
            // restore an explicit fill + shadow to keep the control legible.
            self
                .background((tint ?? fallbackFill).opacity(tint == nil ? 1 : 0.16), in: shape)
                .background(fallbackFill, in: shape)
                .fieldShadow(fallbackShadow)
        }
    }

    /// Convenience for the most common glass shape: a capsule (status pills, floating buttons).
    func fieldGlassCapsule(tint: Color? = nil, interactive: Bool = false) -> some View {
        fieldGlass(in: Capsule(style: .continuous), tint: tint, interactive: interactive)
    }
}

// MARK: - Glass configuration (iOS 26+ only)

@available(iOS 26.0, *)
extension FieldGlass {
    /// Builds a `Glass` configuration from Fieldnote-level intent.
    static func glass(tint: Color?, interactive: Bool) -> Glass {
        var glass: Glass = .regular
        if let tint {
            glass = glass.tint(tint)
        }
        if interactive {
            glass = glass.interactive()
        }
        return glass
    }
}

// MARK: - Glass grouping container

/// Groups multiple glass elements so they blend and morph together (iOS 26).
/// Below iOS 26 it simply renders its content; the children fall back to opaque surfaces
/// individually via `fieldGlass()`.
struct FieldGlassContainer<Content: View>: View {
    private let spacing: CGFloat?
    private let content: () -> Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}
