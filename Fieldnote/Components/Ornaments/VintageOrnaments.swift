//
//  VintageOrnaments.swift
//  Fieldnote
//
//  Shared card + divider primitives. Modernized for the redesign: the heavy
//  sepia "book-border" skeuomorphism is retired in favour of clean neutral
//  tones and continuous corners. Names are kept so call sites don't change.
//

import SwiftUI

// MARK: - Ruled Line Divider

/// A thin horizontal hairline divider.
struct RuledLine: View {
    var color: Color = FieldColor.separator
    var thickness: CGFloat = 1

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: thickness)
    }
}

// MARK: - Double Ruled Line

struct DoubleRuledLine: View {
    var color: Color = FieldColor.separator

    var body: some View {
        VStack(spacing: 3) {
            RuledLine(color: color)
            RuledLine(color: color)
        }
    }
}

// MARK: - Ornamental Divider

/// A centered divider with a small leaf accent.
struct OrnamentalDivider: View {
    var symbol: String = "leaf.fill"

    var body: some View {
        HStack(spacing: FieldSpace.sm) {
            RuledLine()
            Image(systemName: symbol)
                .font(.system(size: 10))
                .foregroundStyle(FieldColor.tertiaryInk)
            RuledLine()
        }
    }
}

// MARK: - Page Border Modifier

/// A subtle hairline border around framed content.
struct BookPageBorder: ViewModifier {
    var padding: CGFloat = FieldSpace.sm
    var cornerRadius: CGFloat = FieldRadius.sm

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(FieldColor.separator, lineWidth: 1)
            )
    }
}

extension View {
    func bookPageBorder(padding: CGFloat = FieldSpace.sm, cornerRadius: CGFloat = FieldRadius.sm) -> some View {
        modifier(BookPageBorder(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Card

/// The standard content card — clean modern surface with a hairline border.
struct VintageCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(FieldSpace.cardPadding)
            .background(
                FieldColor.surface,
                in: RoundedRectangle(cornerRadius: FieldRadius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.card, style: .continuous)
                    .stroke(FieldColor.separator, lineWidth: 1)
            )
            .fieldShadow(FieldShadow.card)
    }
}

// MARK: - Illustration Frame

/// A soft frame for botanical illustrations.
struct IllustrationFrame: ViewModifier {
    var frameWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(FieldColor.illustrationBg)
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.sm, style: .continuous)
                    .stroke(FieldColor.separator, lineWidth: frameWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: FieldRadius.sm, style: .continuous))
    }
}

extension View {
    func illustrationFrame(width: CGFloat = 1) -> some View {
        modifier(IllustrationFrame(frameWidth: width))
    }
}

// MARK: - Scientific Name Plate

/// Scientific name flanked by hairlines (used under illustrations).
struct ScientificNamePlate: View {
    let name: String

    var body: some View {
        HStack(spacing: FieldSpace.sm) {
            RuledLine()
            Text(name)
                .font(FieldType.scientificCallout)
                .italic()
                .foregroundStyle(FieldColor.mutedInk)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
            RuledLine()
        }
    }
}

// MARK: - Chapter Header

/// A header for major sections.
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
                    .foregroundStyle(FieldColor.ink)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(FieldType.callout)
                        .foregroundStyle(FieldColor.mutedInk)
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
            VStack(spacing: FieldSpace.md) {
                Text("Dividers").font(FieldType.caption)
                RuledLine()
                DoubleRuledLine()
                OrnamentalDivider()
            }

            ScientificNamePlate(name: "Taraxacum officinale")
            ChapterHeader("Field Observations", subtitle: "Spring 2024")

            VintageCard {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Text("Common Dandelion")
                        .font(FieldType.title3)
                        .foregroundStyle(FieldColor.ink)
                    Text("A resilient wildflower found across meadows and gardens.")
                        .font(FieldType.body)
                        .foregroundStyle(FieldColor.mutedInk)
                }
            }

            Text("Framed Content")
                .font(FieldType.body)
                .padding()
                .bookPageBorder()
        }
        .padding()
    }
    .background(FieldColor.canvasBottom)
}
