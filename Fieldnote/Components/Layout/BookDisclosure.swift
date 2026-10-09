import SwiftUI

/// The header precedes its content, so expansion leaves the reading anchor in place.
struct BookDisclosure<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            Button {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) { expanded.toggle() }
            } label: {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .foregroundStyle(FieldColor.ink)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            if expanded { content.transition(.opacity) }
        }
    }
}
