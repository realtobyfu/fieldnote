//
//  OnboardingWelcomePage.swift
//  Fieldnote
//
//  "Your Botanical Journal Awaits" - welcome page with botanical illustration
//

import SwiftUI
import Combine

struct OnboardingWelcomePage: View {
    @State private var illustrationVisible = false
    @State private var textVisible = false
    @State private var currentIllustrationIndex = 0

    // Diverse plant illustrations for carousel
    private let illustrations = [
        "white_pine",
        "red_maple",
        "virginia_bluebells",
        "common_milkweed",
        "eastern_redbud"
    ]

    // Timer for auto-advance
    private let timer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

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
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                illustrationVisible = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                textVisible = true
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                currentIllustrationIndex = (currentIllustrationIndex + 1) % illustrations.count
            }
        }
    }

    // MARK: - Illustration Section

    private var illustrationSection: some View {
        VStack(spacing: FieldSpace.md) {
            // Botanical illustration carousel with vintage frame
            ZStack {
                ForEach(Array(illustrations.enumerated()), id: \.offset) { index, imageName in
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                        .opacity(index == currentIllustrationIndex ? 1 : 0)
                        .scaleEffect(index == currentIllustrationIndex ? 1 : 0.95)
                }
            }
            .padding(FieldSpace.lg)
            .background(FieldColor.illustrationBg)
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.lg)
                    .stroke(FieldColor.bookBorder, lineWidth: 2)
            )
            .overlay(
                // Inner decorative border
                RoundedRectangle(cornerRadius: FieldRadius.md)
                    .stroke(FieldColor.bookBorder.opacity(0.3), lineWidth: 1)
                    .padding(6)
            )
            .cornerRadius(FieldRadius.lg)
            .fieldShadow(FieldShadow.card)

            // Page dots indicator
            HStack(spacing: 6) {
                ForEach(0..<illustrations.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIllustrationIndex ? FieldColor.accent : FieldColor.bookBorder.opacity(0.5))
                        .frame(width: index == currentIllustrationIndex ? 8 : 6,
                               height: index == currentIllustrationIndex ? 8 : 6)
                        .animation(.easeInOut(duration: 0.3), value: currentIllustrationIndex)
                }
            }
            .padding(.top, FieldSpace.xs)

            // Decorative divider below illustration
            OrnamentalDivider(symbol: "leaf.fill")
                .padding(.horizontal, FieldSpace.lg)
        }
        .scaleEffect(illustrationVisible ? 1 : 0.85)
        .opacity(illustrationVisible ? 1 : 0)
    }

    // MARK: - Welcome Text

    private var welcomeText: some View {
        VStack(spacing: FieldSpace.md) {
            Text("Your Botanical Journal Awaits")
                .font(FieldType.displayTitle)
                .foregroundColor(FieldColor.vintageInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("Welcome, fellow naturalist. Begin your journey of discovery through the botanical world around you.")
                .font(FieldType.body)
                .foregroundColor(FieldColor.fadedInk)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, FieldSpace.md)
                .fixedSize(horizontal: false, vertical: true)
        }
        .offset(y: textVisible ? 0 : 15)
        .opacity(textVisible ? 1 : 0)
    }
}

#Preview {
    OnboardingWelcomePage()
        .background(FieldColor.paper)
}
