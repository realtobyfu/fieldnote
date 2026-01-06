//
//  OnboardingWelcomePage.swift
//  Fieldnote
//
//  "Your Botanical Journal Awaits" - welcome page with botanical illustration
//

import SwiftUI

struct OnboardingWelcomePage: View {
    @State private var illustrationOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: FieldSpace.xl) {
            Spacer()

            // Botanical illustration with vintage frame
            illustrationSection

            // Welcome text
            welcomeText

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FieldSpace.xl)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                illustrationOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1
            }
        }
    }

    // MARK: - Illustration Section

    private var illustrationSection: some View {
        VStack(spacing: FieldSpace.md) {
            // Botanical illustration
            Image("white_pine")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .padding(FieldSpace.md)
                .background(FieldColor.illustrationBg)
                .overlay(
                    RoundedRectangle(cornerRadius: FieldRadius.md)
                        .stroke(FieldColor.bookBorder, lineWidth: 1.5)
                )
                .cornerRadius(FieldRadius.md)
                .fieldShadow(FieldShadow.card)

            // Decorative divider below illustration
            OrnamentalDivider(symbol: "leaf.fill")
                .padding(.horizontal, FieldSpace.xl)
        }
        .opacity(illustrationOpacity)
    }

    // MARK: - Welcome Text

    private var welcomeText: some View {
        VStack(spacing: FieldSpace.md) {
            Text("Your Botanical Journal Awaits")
                .font(FieldType.displayTitle)
                .foregroundColor(FieldColor.vintageInk)
                .multilineTextAlignment(.center)

            Text("Welcome, fellow naturalist. Begin your journey of discovery through the botanical world around you.")
                .font(FieldType.body)
                .foregroundColor(FieldColor.fadedInk)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, FieldSpace.md)
        }
        .opacity(textOpacity)
    }
}

#Preview {
    OnboardingWelcomePage()
        .background(FieldColor.agedPaper)
}
