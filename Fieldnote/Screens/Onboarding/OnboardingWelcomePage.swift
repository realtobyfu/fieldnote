//
//  OnboardingWelcomePage.swift
//  Fieldnote
//
//  Frontispiece: a full specimen plate and a quiet introduction
//

import SwiftUI

struct OnboardingWelcomePage: View {
    @State private var settled = false

    var body: some View {
        VStack(spacing: FieldSpace.xl) {
            Spacer()

            specimenPlate

            introText

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FieldSpace.xl)
        .opacity(settled ? 1 : 0)
        .offset(y: settled ? 0 : 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                settled = true
            }
        }
    }

    // MARK: - Specimen Plate

    /// The elm plate presented the way plants appear everywhere else in the
    /// app: illustration over a hairline rule, then a parchment caption block
    /// with a tracked plate-label eyebrow, the common name, and the Latin name.
    private var specimenPlate: some View {
        VStack(spacing: 0) {
            Image("american_elm")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(FieldSpace.md)
                .background(FieldColor.illustrationBg)

            Rectangle()
                .fill(FieldColor.bookBorder.opacity(0.5))
                .frame(height: 0.5)

            VStack(spacing: FieldSpace.xs) {
                HStack(spacing: FieldSpace.xs) {
                    Text("PLATE I")
                    Text("·")
                    Text("ULMACEAE")
                }
                .font(FieldType.plateLabel)
                .tracking(1.2)
                .foregroundColor(FieldColor.sepia.opacity(0.7))

                Text("American Elm")
                    .font(FieldType.title3)
                    .foregroundColor(FieldColor.vintageInk)

                ScientificNameText("Ulmus americana", size: .footnote)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FieldSpace.md)
            .background(FieldColor.parchment)
        }
        .clipShape(RoundedRectangle(cornerRadius: FieldRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.md, style: .continuous)
                .stroke(FieldColor.bookBorder.opacity(0.4), lineWidth: 0.5)
        )
        .fieldShadow(FieldShadow.card)
    }

    // MARK: - Introduction

    private var introText: some View {
        VStack(spacing: FieldSpace.md) {
            Text("A field journal for the plants you find")
                .font(FieldType.displayTitle)
                .foregroundColor(FieldColor.vintageInk)
                .multilineTextAlignment(.center)

            Text("Photograph, identify, and keep a record of what grows around you.")
                .font(FieldType.body)
                .foregroundColor(FieldColor.fadedInk)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, FieldSpace.md)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnboardingWelcomePage()
        .background(FieldColor.paper)
}
