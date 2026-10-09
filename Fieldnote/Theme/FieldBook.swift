import SwiftUI
import CoreText

/// The book uses serif headings; controls and reading copy retain system type.
enum FieldBook {
    static let cover = Color(red: 0.18, green: 0.34, blue: 0.28)
    static let paper = Color(red: 0.975, green: 0.964, blue: 0.94)
    static let wash = Color(red: 0.91, green: 0.93, blue: 0.88)
    static let title = Font.custom("CormorantGaramond-Regular", size: 42, relativeTo: .largeTitle)
    static let heading = Font.custom("CormorantGaramond-Regular", size: 29, relativeTo: .title2)
    static let name = Font.custom("CormorantGaramond-Regular", size: 25, relativeTo: .title3)

    static func encounterCount(_ count: Int) -> String {
        "\(count) \(count == 1 ? "encounter" : "encounters")"
    }

    static func registerFonts() {
        for name in ["CormorantGaramond-Regular", "CormorantGaramond-Italic"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}

struct BookSectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.medium))
            .tracking(2)
            .foregroundStyle(FieldColor.mutedInk)
            .accessibilityAddTraits(.isHeader)
    }
}
