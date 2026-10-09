import SwiftUI

struct ProfileSourcesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    BookSectionLabel(text: "Sources & credits")
                    Text("A shared field guide.").font(FieldBook.title).accessibilityAddTraits(.isHeader)
                    Text("Fieldnote brings together your observations and open botanical reference material.")
                        .font(.body).foregroundStyle(FieldColor.mutedInk)
                }
                source("Local and regional guides", detail: "Guides use research-grade plant reports from iNaturalist. Reports describe an area’s recorded plants; they do not promise a plant is at a particular spot or flowering today.")
                source("Scientific names", detail: "Some regional scientific names are matched through GBIF. Names and identifications can change as botanical knowledge grows.")
                source("Photo identification", detail: "Online identification is powered by Pl@ntNet. Suggestions help you explore; they are not a confirmed identification.")
                source("Images and typography", detail: "Available image credits appear with specimens and photographs. The book’s headings use Cormorant Garamond, distributed under the SIL Open Font License.")
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle("Sources & credits")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func source(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(FieldBook.heading).accessibilityAddTraits(.isHeader)
            Divider()
            Text(detail).font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
