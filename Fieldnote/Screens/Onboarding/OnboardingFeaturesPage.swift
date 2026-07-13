//
//  OnboardingFeaturesPage.swift
//  Fieldnote
//
//  Contents page: the Capture -> Library -> Explore flow as a
//  field-guide table of contents
//

import SwiftUI

struct OnboardingFeaturesPage: View {
    @State private var headerVisible = false
    @State private var rowVisibility: [Bool] = [false, false, false]

    private let chapters: [(numeral: String, title: String, description: String)] = [
        ("I", "Capture", "Photograph a plant and Fieldnote identifies it in the field."),
        ("II", "Library", "Each find becomes a dated entry in your own herbarium."),
        ("III", "Explore", "See what grows near you, season by season.")
    ]

    var body: some View {
        VStack(spacing: FieldSpace.xl) {
            Spacer()

            header

            contentsCard

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FieldSpace.xl)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                headerVisible = true
            }
            for i in 0..<chapters.count {
                withAnimation(.easeOut(duration: 0.4).delay(0.15 + Double(i) * 0.12)) {
                    rowVisibility[i] = true
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: FieldSpace.sm) {
            Text("CONTENTS")
                .font(FieldType.plateLabel)
                .tracking(2.0)
                .foregroundColor(FieldColor.sepia.opacity(0.7))

            Text("How the journal works")
                .font(FieldType.displayTitle)
                .foregroundColor(FieldColor.vintageInk)
                .multilineTextAlignment(.center)
        }
        .opacity(headerVisible ? 1 : 0)
        .offset(y: headerVisible ? 0 : 8)
    }

    // MARK: - Contents Card

    /// Three chapters on parchment, separated by hairline rules —
    /// read like the table of contents of a field guide.
    private var contentsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                chapterRow(chapter)
                    .opacity(rowVisibility[index] ? 1 : 0)
                    .offset(y: rowVisibility[index] ? 0 : 6)

                if index < chapters.count - 1 {
                    RuledLine(color: FieldColor.bookBorder.opacity(0.35))
                        .opacity(rowVisibility[index] ? 1 : 0)
                }
            }
        }
        .padding(.horizontal, FieldSpace.md)
        .background(FieldColor.parchment)
        .clipShape(RoundedRectangle(cornerRadius: FieldRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.md, style: .continuous)
                .stroke(FieldColor.bookBorder.opacity(0.4), lineWidth: 0.5)
        )
        .fieldShadow(FieldShadow.card)
    }

    private func chapterRow(_ chapter: (numeral: String, title: String, description: String)) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: FieldSpace.md) {
            Text(chapter.numeral)
                .font(FieldType.displaySubtitle)
                .foregroundColor(FieldColor.sepia.opacity(0.75))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title)
                    .font(FieldType.title3)
                    .foregroundColor(FieldColor.vintageInk)

                Text(chapter.description)
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, FieldSpace.md)
    }
}

#Preview {
    OnboardingFeaturesPage()
        .background(FieldColor.paper)
}
