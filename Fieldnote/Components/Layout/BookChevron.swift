import SwiftUI

/// The one disclosure mark for ruled book rows, so every row points the same way.
struct BookChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(FieldColor.tertiaryInk)
            .accessibilityHidden(true)
    }
}
