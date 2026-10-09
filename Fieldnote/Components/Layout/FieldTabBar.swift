//
//  FieldTabBar.swift
//  Fieldnote
//
//  A glass capsule for Atlas, Nearby, and Collection, with a separate camera
//  action on the right. Capture never becomes a selected tab.
//

import SwiftUI

/// Shared collapse state for the custom tab bar, updated by scrolling content.
@MainActor
@Observable
final class TabBarVisibility {
    var collapsed = false
    /// Temporarily removes the root bar for other bottom chrome, such as search.
    var suppressed = false
}

struct FieldTabBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selection: AppTab
    var collapsed: Bool
    var onCapture: () -> Void
    var onCaptureLibrary: () -> Void
    var onManualEntry: () -> Void
    var namespace: Namespace.ID

    private typealias TabItem = (tab: AppTab, symbol: String, label: String)

    private let tabs: [TabItem] = [
        (.journal, "book.closed.fill", "Atlas"),
        (.explore, "location", "Nearby"),
        (.collection, "square.grid.2x2.fill", "Collection")
    ]

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if #available(iOS 26.0, *) {
                    tabCapsule
                        .glassEffect(.regular, in: .capsule)
                        .glassEffectID("field-tab-bar", in: namespace)
                        .glassEffectTransition(.materialize)
                } else {
                    tabCapsule
                        .background(.regularMaterial, in: Capsule())
                        .overlay(Capsule().stroke(FieldColor.separator, lineWidth: 0.5))
                        .fieldShadow(FieldShadow.card)
                }
            }
            captureButton
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.34), value: collapsed)
    }

    // MARK: - Pieces

    private var tabCapsule: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.tab) { tabButton($0.tab, $0.symbol, $0.label) }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
    }

    private var captureButton: some View {
        Button(action: onCapture) {
            Image(systemName: "camera.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(
                        colors: [FieldColor.accent, FieldColor.accentDeep],
                        startPoint: .top, endPoint: .bottom
                    ),
                    in: Circle()
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Capture plant")
        .accessibilityIdentifier("tab.capture")
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
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                if !collapsed {
                    Text(label)
                        .font(.caption2.weight(.medium))
                        .transition(.opacity.combined(with: .blurReplace))
                }
            }
            .foregroundStyle(isSelected ? FieldColor.accentDeep : FieldColor.mutedInk)
            // Width stays constant on collapse — only the caption is dropped, so
            // targets never narrow or slide under the finger.
            .frame(
                minWidth: 44,
                maxWidth: .infinity,
                minHeight: 44
            )
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
        .accessibilityIdentifier("tab.\(label.lowercased())")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Scroll-driven collapse

/// Apply to a scroll view (or a container holding one) to contract the custom
/// tab bar when scrolling down and expand it when scrolling up.
struct CollapseTabBarOnScroll: ViewModifier {
    @Environment(TabBarVisibility.self) private var visibility: TabBarVisibility?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { oldY, newY in
            guard let visibility else { return }
            // Always show the full bar near the top (and at rest on launch).
            if newY < 24 {
                if visibility.collapsed {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.32)) {
                        visibility.collapsed = false
                    }
                }
                return
            }
            let delta = newY - oldY
            guard abs(delta) > 6 else { return }
            let goingDown = delta > 0
            if goingDown != visibility.collapsed {
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.32)) {
                    visibility.collapsed = goingDown
                }
            }
        }
    }
}

extension View {
    func collapsesTabBarOnScroll() -> some View {
        modifier(CollapseTabBarOnScroll())
    }
}

private struct FieldTabBarPreview: View {
    let collapsed: Bool

    @State private var selection: AppTab = .explore
    @Namespace private var namespace

    var body: some View {
        FieldTabBar(
            selection: $selection,
            collapsed: collapsed,
            onCapture: {},
            onCaptureLibrary: {},
            onManualEntry: {},
            namespace: namespace
        )
        .padding()
        .background(FieldColor.paper)
    }
}

#Preview("Tab bar · Expanded") {
    FieldTabBarPreview(collapsed: false)
}

#Preview("Tab bar · Collapsed") {
    FieldTabBarPreview(collapsed: true)
}
