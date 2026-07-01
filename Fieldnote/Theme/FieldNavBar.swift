//
//  FieldNavBar.swift
//  Fieldnote
//
//  Navigation chrome for the Fieldnote design language. The stock UINavigationBar
//  ships a sans-serif title on a grey/blurred bar, which clashes with the warm
//  "botanical book" aesthetic (serif display type over a paper canvas). This file
//  restyles the bar globally — serif titles, a paper-tinted scrolled background
//  that fades to transparent at rest, an accent-tinted back chevron — and provides
//  the canvas backgrounds that let plain-List sub-pages sit on the same paper.
//

import SwiftUI
import UIKit

enum FieldNavBar {
    /// Configure the global navigation-bar appearance to match the design language.
    /// Call once at launch (idempotent).
    static func applyAppearance() {
        let ink = UIColor(FieldColor.ink)

        let appearance = UINavigationBarAppearance()
        // At rest (scroll edge) the bar is transparent so the canvas gradient shows
        // through; once content scrolls under it we swap in a paper-tinted fill so
        // the title stays legible over whatever is passing beneath.
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        appearance.titleTextAttributes = [
            .font: serifFont(size: 17, weight: .semibold),
            .foregroundColor: ink
        ]
        appearance.largeTitleTextAttributes = [
            .font: serifFont(size: 30, weight: .bold),
            .foregroundColor: ink
        ]

        // Custom back chevron + serif, accent-tinted back label.
        let chevron = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        appearance.setBackIndicatorImage(chevron, transitionMaskImage: chevron)

        let backButton = UIBarButtonItemAppearance(style: .plain)
        let backAttributes: [NSAttributedString.Key: Any] = [
            .font: serifFont(size: 16, weight: .medium),
            .foregroundColor: UIColor(FieldColor.accentDeep)
        ]
        backButton.normal.titleTextAttributes = backAttributes
        backButton.highlighted.titleTextAttributes = backAttributes
        appearance.backButtonAppearance = backButton

        // Scrolled ("standard") appearance keeps the same serif type but on a paper
        // fill so titles never sit directly on top of content.
        let scrolled = appearance.copy()
        scrolled.backgroundColor = UIColor(FieldColor.canvasTop).withAlphaComponent(0.92)

        let bar = UINavigationBar.appearance()
        bar.scrollEdgeAppearance = appearance
        bar.compactScrollEdgeAppearance = appearance
        bar.standardAppearance = scrolled
        bar.compactAppearance = scrolled
        bar.tintColor = UIColor(FieldColor.accentDeep)
    }

    /// System font resolved to the serif design (the botanical-book face used everywhere).
    private static func serifFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

// MARK: - Canvas backgrounds

extension View {
    /// The warm paper canvas gradient used as the base of every screen. Extends
    /// under the (transparent) nav bar and home indicator.
    func fieldCanvasBackground() -> some View {
        background(
            LinearGradient(
                colors: [FieldColor.canvasTop, FieldColor.canvasBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    /// Drops a `List`'s opaque grey system background so it sits on the paper canvas.
    /// Apply to List-based screens together with `fieldCanvasBackground()`.
    func fieldListBackground() -> some View {
        scrollContentBackground(.hidden)
            .fieldCanvasBackground()
    }
}
