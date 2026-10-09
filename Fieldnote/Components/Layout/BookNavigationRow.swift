import SwiftUI

/// A quiet, ruled entry shared by the book's utility pages.
struct BookNavigationRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let symbol: String
    let title: String
    var subtitle: String? = nil
    var detail: String? = nil
    var showsChevron = true

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(FieldBook.cover)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.body)
                    .foregroundStyle(FieldColor.ink)
                if let subtitle {
                    Text(subtitle).font(.caption)
                        .foregroundStyle(FieldColor.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if dynamicTypeSize.isAccessibilitySize, let detail {
                    Text(detail).font(.subheadline)
                        .foregroundStyle(FieldColor.mutedInk)
                }
            }
            Spacer(minLength: 8)
            if !dynamicTypeSize.isAccessibilitySize, let detail {
                Text(detail).font(.subheadline)
                    .foregroundStyle(FieldColor.mutedInk)
                    .monospacedDigit()
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(FieldColor.tertiaryInk)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
