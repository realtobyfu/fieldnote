import SwiftUI
import UIKit

/// Temporarily hides native tabs while a screen presents its own bottom chrome.
@MainActor
@Observable
final class TabBarVisibility {
    var suppressed = false
}

/// UIKit owns tab selection, accessibility, and icon layout. Capture is a Button.
struct FieldTabBar: View {
    @Binding var selection: AppTab
    var onCapture: () -> Void
    var onCaptureLibrary: () -> Void
    var onManualEntry: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            NativeFieldTabs(selection: $selection)
                // Native floating tabs already provide their own side margins.
                .padding(.horizontal, nativeSideMargin)
                .frame(height: 64)
                .offset(y: 9)
            captureButton
        }
    }

    private var captureButton: some View {
        Button(action: onCapture) {
            Image(systemName: "camera.fill")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 62, height: 62)
                .contentShape(Circle())
        }
        .modifier(CaptureActionStyle())
        .accessibilityLabel("Capture plant")
        .accessibilityIdentifier("tab.capture")
        .contextMenu {
            Button("Choose from Library", systemImage: "photo.on.rectangle", action: onCaptureLibrary)
            Button("Manual Entry", systemImage: "pencil.line", action: onManualEntry)
        }
    }

    private var nativeSideMargin: CGFloat {
        if #available(iOS 26.0, *) { -16 } else { 0 }
    }
}

private struct CaptureActionStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .glassEffect(.regular.tint(FieldColor.accentDeep).interactive(), in: .circle)
        } else {
            content
                .foregroundStyle(.white)
                .background(FieldColor.accentDeep, in: Circle())
                .buttonStyle(.plain)
        }
    }
}

private struct NativeFieldTabs: UIViewRepresentable {
    @Binding var selection: AppTab

    private static let items: [(AppTab, String, String)] = [
        (.journal, "Atlas", "book.closed.fill"),
        (.explore, "Nearby", "location"),
        (.collection, "Collection", "square.grid.2x2.fill")
    ]

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection) }

    func makeUIView(context: Context) -> UITabBar {
        let bar = UITabBar()
        bar.delegate = context.coordinator
        bar.itemPositioning = .fill
        bar.tintColor = UIColor(FieldColor.accentDeep)
        bar.unselectedItemTintColor = UIColor(FieldColor.mutedInk)
        bar.items = Self.items.map { tab, title, symbol in
            let item = UITabBarItem(title: nil, image: UIImage(systemName: symbol), tag: tab.rawValue)
            item.accessibilityLabel = title
            item.accessibilityIdentifier = "tab.\(title.lowercased())"
            return item
        }
        return bar
    }

    func updateUIView(_ bar: UITabBar, context: Context) {
        context.coordinator.selection = $selection
        bar.selectedItem = bar.items?.first { $0.tag == selection.rawValue }
    }

    final class Coordinator: NSObject, UITabBarDelegate {
        var selection: Binding<AppTab>

        init(selection: Binding<AppTab>) { self.selection = selection }

        func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            guard let tab = AppTab(rawValue: item.tag) else { return }
            selection.wrappedValue = tab
        }
    }
}
