//
//  FieldTabBar.swift
//  Fieldnote
//
//  A glass capsule for Atlas, Nearby, and Collection, with a separate camera
//  action on the right. Capture never becomes a selected tab.
//

import SwiftUI

/// Shared visibility state for the custom tab bar.
@MainActor
@Observable
final class TabBarVisibility {
    /// Temporarily removes the root bar for other bottom chrome, such as search.
    var suppressed = false
}

struct FieldTabBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selection: AppTab
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
                .frame(width: 54, height: 54)
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
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isSelected ? FieldColor.accentDeep : FieldColor.mutedInk)
                // Icons stay compact while every tab retains a 44pt touch target.
                .frame(
                    minWidth: 44,
                    maxWidth: .infinity,
                    minHeight: 44
                )
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

private struct FieldTabBarPreview: View {
    @State private var selection: AppTab = .explore
    @Namespace private var namespace

    var body: some View {
        FieldTabBar(
            selection: $selection,
            onCapture: {},
            onCaptureLibrary: {},
            onManualEntry: {},
            namespace: namespace
        )
        .padding()
        .background(FieldColor.paper)
    }
}

#Preview("Tab bar · Icons") {
    FieldTabBarPreview()
}
