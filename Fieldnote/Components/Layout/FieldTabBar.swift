//
//  FieldTabBar.swift
//  Fieldnote
//
//  Custom Liquid Glass tab bar built from THREE distinct glass elements:
//  a leading tab capsule, a centered Capture FAB, and a trailing tab capsule.
//  They share a GlassEffectContainer so they morph/merge as they approach.
//  On scroll-down each side capsule collapses to a single most-important tab
//  (the active one if it's on that side, else the primary); scroll-up re-expands.
//

import SwiftUI

/// Shared collapse state for the custom tab bar, updated by scrolling content.
@MainActor
@Observable
final class TabBarVisibility {
    var collapsed = false
}

struct FieldTabBar: View {
    /// Bottom safe-area clearance tab content needs so scrollable content and
    /// bottom-anchored controls never end up hidden beneath the floating bar
    /// (bar height + breathing room). Applied once in MainTabView.tabStack.
    static let clearance: CGFloat = 92

    @Binding var selection: AppTab
    var collapsed: Bool
    var onCapture: () -> Void
    var onCaptureLibrary: () -> Void
    var onManualEntry: () -> Void
    var namespace: Namespace.ID

    private typealias TabItem = (tab: AppTab, symbol: String, label: String)

    // First entry on each side is the "primary" (most important) tab.
    private let leading: [TabItem] = [
        (.journal, "book.closed.fill", "Journal"),
        (.explore, "safari.fill", "Explore")
    ]
    private let trailing: [TabItem] = [
        (.map, "map.fill", "Map"),
        (.profile, "person.crop.circle.fill", "Profile")
    ]

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 8) { glassBar }
            } else {
                fallbackBar
            }
        }
        .animation(.snappy(duration: 0.34), value: collapsed)
    }

    // MARK: - iOS 26 glass (always three distinct elements)

    @available(iOS 26.0, *)
    private var glassBar: some View {
        HStack(spacing: 8) {
            cluster(leading)
                .glassEffect(.regular, in: .capsule)
                .glassEffectID("leading", in: namespace)
            captureButton
                .glassEffect(.regular.tint(FieldColor.accent).interactive(), in: .circle)
                .glassEffectID("capture", in: namespace)
            cluster(trailing)
                .glassEffect(.regular, in: .capsule)
                .glassEffectID("trailing", in: namespace)
        }
    }

    // MARK: - iOS 18 fallback

    private var fallbackBar: some View {
        HStack(spacing: 8) {
            cluster(leading).modifier(GlassCapsuleFallback())
            captureButton
                .background(FieldColor.accent, in: Circle())
                .fieldShadow(FieldShadow.cardHover)
            cluster(trailing).modifier(GlassCapsuleFallback())
        }
    }

    // MARK: - Pieces

    private func cluster(_ items: [TabItem]) -> some View {
        let shown = collapsed ? [primaryItem(in: items)] : items
        return HStack(spacing: 6) {
            ForEach(shown, id: \.tab) { tabButton($0.tab, $0.symbol, $0.label) }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    /// When collapsed, keep the active tab if it's on this side; otherwise the primary.
    private func primaryItem(in items: [TabItem]) -> TabItem {
        items.first(where: { $0.tab == selection }) ?? items[0]
    }

    private var captureButton: some View {
        Button(action: onCapture) {
            Image(systemName: "camera.fill")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Capture")
        .contextMenu {
            Button { onCaptureLibrary() } label: {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
            Button { onManualEntry() } label: {
                Label("Manual Entry", systemImage: "pencil.line")
            }
        }
    }

    private func tabButton(_ tab: AppTab, _ symbol: String, _ label: String) -> some View {
        let isSelected = tab == selection
        return Button {
            withAnimation(.snappy(duration: 0.3)) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(isSelected ? FieldColor.accentDeep : FieldColor.mutedInk)
            .frame(minWidth: 56)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    Capsule()
                        .fill(FieldColor.accent.opacity(0.16))
                        .matchedGeometryEffect(id: "selpill", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .transition(.opacity.combined(with: .blurReplace))
    }
}

/// Opaque "modern paper" capsule used for the tab clusters below iOS 26.
private struct GlassCapsuleFallback: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(FieldColor.separator, lineWidth: 0.5))
            .fieldShadow(FieldShadow.card)
    }
}

// MARK: - Scroll-driven collapse

/// Apply to a scroll view (or a container holding one) to collapse the custom
/// tab bar when scrolling down and expand it when scrolling up.
struct CollapseTabBarOnScroll: ViewModifier {
    @Environment(TabBarVisibility.self) private var visibility: TabBarVisibility?

    func body(content: Content) -> some View {
        content.onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { oldY, newY in
            guard let visibility else { return }
            // Always show the full bar near the top (and at rest on launch).
            if newY < 24 {
                if visibility.collapsed {
                    withAnimation(.snappy(duration: 0.32)) { visibility.collapsed = false }
                }
                return
            }
            let delta = newY - oldY
            guard abs(delta) > 6 else { return }
            let goingDown = delta > 0
            if goingDown != visibility.collapsed {
                withAnimation(.snappy(duration: 0.32)) { visibility.collapsed = goingDown }
            }
        }
    }
}

extension View {
    func collapsesTabBarOnScroll() -> some View {
        modifier(CollapseTabBarOnScroll())
    }
}
