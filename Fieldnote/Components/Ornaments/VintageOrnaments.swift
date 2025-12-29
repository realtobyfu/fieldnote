//
//  VintageOrnaments.swift
//  Fieldnote
//
//  Vintage decorative elements for the botanical book aesthetic
//

import SwiftUI

// MARK: - Ruled Line Divider

/// A thin horizontal ruled line, like those found in vintage books
struct RuledLine: View {
    var color: Color = FieldColor.bookBorder
    var thickness: CGFloat = 0.5

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: thickness)
    }
}

// MARK: - Double Ruled Line

/// A double-line divider for chapter-style separations
struct DoubleRuledLine: View {
    var color: Color = FieldColor.bookBorder

    var body: some View {
        VStack(spacing: 3) {
            RuledLine(color: color, thickness: 0.5)
            RuledLine(color: color, thickness: 0.5)
        }
    }
}

// MARK: - Ornamental Divider

/// A centered ornamental divider with a decorative element
struct OrnamentalDivider: View {
    var symbol: String = "leaf.fill"

    var body: some View {
        HStack(spacing: FieldSpace.sm) {
            RuledLine()
            Image(systemName: symbol)
                .font(.system(size: 10))
                .foregroundColor(FieldColor.bookBorder)
            RuledLine()
        }
    }
}

// MARK: - Book Page Border Modifier

/// Adds a subtle book-page style border to a view
struct BookPageBorder: ViewModifier {
    var padding: CGFloat = FieldSpace.sm
    var cornerRadius: CGFloat = FieldRadius.sm

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
            )
    }
}

extension View {
    /// Apply a vintage book-page border
    func bookPageBorder(padding: CGFloat = FieldSpace.sm, cornerRadius: CGFloat = FieldRadius.sm) -> some View {
        modifier(BookPageBorder(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Vintage Card

/// A card styled like a page from a vintage botanical book
struct VintageCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(FieldSpace.cardPadding)
            .background(FieldColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.card)
                    .stroke(FieldColor.bookBorder.opacity(0.4), lineWidth: 0.5)
            )
            .cornerRadius(FieldRadius.card)
            .fieldShadow(FieldShadow.card)
    }
}

// MARK: - Illustration Frame

/// A decorative frame for botanical illustrations
struct IllustrationFrame: ViewModifier {
    var frameWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(FieldColor.illustrationBg)
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .stroke(FieldColor.bookBorder, lineWidth: frameWidth)
            )
            .cornerRadius(FieldRadius.sm)
    }
}

extension View {
    /// Apply a vintage illustration frame
    func illustrationFrame(width: CGFloat = 1) -> some View {
        modifier(IllustrationFrame(frameWidth: width))
    }
}

// MARK: - Scientific Name Plate

/// A styled plate for displaying scientific names under illustrations
struct ScientificNamePlate: View {
    let name: String

    var body: some View {
        HStack(spacing: FieldSpace.sm) {
            RuledLine()
            Text(name)
                .font(FieldType.scientificCallout)
                .italic()
                .foregroundColor(FieldColor.fadedInk)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
            RuledLine()
        }
    }
}

// MARK: - Chapter Header

/// A literary-style header for major sections
struct ChapterHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: FieldSpace.xs) {
            RuledLine()

            VStack(spacing: 2) {
                Text(title)
                    .font(FieldType.displaySubtitle)
                    .foregroundColor(FieldColor.vintageInk)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }
            .padding(.vertical, FieldSpace.xs)

            RuledLine()
        }
    }
}

// MARK: - Previews

#Preview("Ornaments") {
    ScrollView {
        VStack(spacing: FieldSpace.xl) {
            // Ruled lines
            VStack(spacing: FieldSpace.md) {
                Text("Ruled Lines").font(FieldType.caption)
                RuledLine()
                DoubleRuledLine()
                OrnamentalDivider()
            }

            // Scientific name plate
            ScientificNamePlate(name: "Taraxacum officinale")

            // Chapter header
            ChapterHeader("Field Observations", subtitle: "Spring 2024")

            // Vintage card
            VintageCard {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Text("Common Dandelion")
                        .font(FieldType.title3)
                        .foregroundColor(FieldColor.vintageInk)

                    Text("A resilient wildflower found across meadows and gardens.")
                        .font(FieldType.body)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }

            // Book page border
            Text("Framed Content")
                .font(FieldType.body)
                .padding()
                .bookPageBorder()
        }
        .padding()
    }
    .background(FieldColor.agedPaper)
}
