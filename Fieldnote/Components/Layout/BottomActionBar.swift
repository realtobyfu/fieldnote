//
//  BottomActionBar.swift
//  Fieldnote
//
//  Pins a primary action (e.g. a Save button) to the bottom of a scrollable
//  screen. On iOS 26 it uses the safeAreaBar API so scrolled content gets the
//  system's soft scroll-edge blur beneath the floating action instead of being
//  hidden behind an opaque slab; earlier OSes fall back to safeAreaInset over
//  aged paper.
//

import SwiftUI

struct BottomActionBar<Bar: View>: ViewModifier {
    @ViewBuilder var bar: () -> Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .scrollEdgeEffectStyle(.soft, for: .bottom)
                .safeAreaBar(edge: .bottom) {
                    bar()
                        .padding(.horizontal, FieldSpace.md)
                        .padding(.vertical, FieldSpace.sm)
                }
        } else {
            content
                .safeAreaInset(edge: .bottom) {
                    bar()
                        .padding(.horizontal, FieldSpace.md)
                        .padding(.vertical, FieldSpace.sm)
                        .background(
                            FieldColor.agedPaper
                                .overlay(alignment: .top) { RuledLine().opacity(0.5) }
                                // Cover the home-indicator zone too, so scroll
                                // content can't peek out beneath the bar.
                                .ignoresSafeArea(edges: .bottom)
                        )
                }
        }
    }
}

extension View {
    /// Pins `bar` to the bottom edge; blurred scroll-under on iOS 26,
    /// opaque paper bar on earlier OSes.
    func bottomActionBar<Bar: View>(@ViewBuilder _ bar: @escaping () -> Bar) -> some View {
        modifier(BottomActionBar(bar: bar))
    }
}
