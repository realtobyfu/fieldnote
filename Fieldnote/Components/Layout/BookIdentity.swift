import SwiftUI

/// Identity reads as one typographic unit, rather than three separate sections.
struct BookIdentity: View {
    let label: String
    let name: String
    let scientificName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BookSectionLabel(text: label)
            Text(name).font(FieldBook.title)
                .fixedSize(horizontal: false, vertical: true)
            if !scientificName.isEmpty {
                Text(scientificName).font(.subheadline).italic()
                    .foregroundStyle(FieldColor.mutedInk)
            }
        }
    }
}

struct BookRecognition: View {
    let traits: [String]
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Getting to know it").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
            if !traits.isEmpty {
                Text(traits.joined(separator: " · "))
                    .font(.subheadline.weight(.medium)).foregroundStyle(FieldBook.cover)
            }
            if !summary.isEmpty { ExpandablePlantSummary(text: summary) }
        }
    }
}
