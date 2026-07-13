//
//  FieldTabBar.swift
//  Fieldnote
//
//  Custom tab bar: ONE glass capsule holding all four tabs with the Capture
//  button embedded at its center as a solid accent circle. Glass is reserved
//  for this floating chrome layer ("field paper, glass chrome").
//
//  On scroll-down the bar contracts to a compact icons-only capsule — labels
//  slide away and the capture circle shrinks — but every tab stays visible in
//  the same order, so targets never disappear or shift under the finger
//  (unlike the old per-side collapse-to-one-tab behavior).
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
                bar.glassEffect(.regular, in: .capsule)
            } else {
                bar
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().stroke(FieldColor.separator, lineWidth: 0.5))
                    .fieldShadow(FieldShadow.card)
            }
        }
        .animation(.snappy(duration: 0.34), value: collapsed)
    }

    // MARK: - Pieces

    private var bar: some View {
        HStack(spacing: 4) {
            ForEach(leading, id: \.tab) { tabButton($0.tab, $0.symbol, $0.label) }
            captureButton
                .padding(.horizontal, 6)
            ForEach(trailing, id: \.tab) { tabButton($0.tab, $0.symbol, $0.label) }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var captureButton: some View {
        Button(action: onCapture) {
            Image(systemName: "camera.fill")
                .font(.system(size: collapsed ? 16 : 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: collapsed ? 40 : 50, height: collapsed ? 40 : 50)
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
                if !collapsed {
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                        .transition(.opacity.combined(with: .blurReplace))
                }
            }
            .foregroundStyle(isSelected ? FieldColor.accentDeep : FieldColor.mutedInk)
            .frame(maxWidth: .infinity)
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
    }
}

// MARK: - Scroll-driven collapse

/// Apply to a scroll view (or a container holding one) to contract the custom
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
