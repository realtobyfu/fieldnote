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
    /// Scientific names set in the book's own italic, not the system serif italic.
    static let scientific = Font.custom("CormorantGaramond-Italic", size: 18, relativeTo: .subheadline)
    static let scientificSmall = Font.custom("CormorantGaramond-Italic", size: 15, relativeTo: .caption)
    /// The observer's own words, quoted in the book's italic.
    static let note = Font.custom("CormorantGaramond-Italic", size: 18, relativeTo: .body)

    /// Cormorant's default figures are old-style, so "10" reads as a small-cap "IO".
    /// Statistics use lining figures via the font's number-case feature.
    static func lining(size: CGFloat, relativeTo style: UIFont.TextStyle = .title2) -> Font {
        let descriptor = UIFontDescriptor(name: "CormorantGaramond-Regular", size: size)
            .addingAttributes([
                .featureSettings: [[
                    UIFontDescriptor.FeatureKey.type: kNumberCaseType,
                    UIFontDescriptor.FeatureKey.selector: kUpperCaseNumbersSelector
                ]]
            ])
        let font = UIFont(descriptor: descriptor, size: size)
        return Font(UIFontMetrics(forTextStyle: style).scaledFont(for: font))
    }

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

/// The book's double rule: closes a title block the way a printed herbarium does.
struct BookDoubleRule: View {
    var body: some View {
        VStack(spacing: 2) {
            Rectangle().fill(FieldColor.bookBorder).frame(height: 1)
            Rectangle().fill(FieldColor.bookBorder).frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}
