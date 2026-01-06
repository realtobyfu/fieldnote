//
//  OnboardingFeaturesPage.swift
//  Fieldnote
//
//  Features overview: Capture -> Library -> Explore flow
//

import SwiftUI

struct OnboardingFeaturesPage: View {
    @State private var headerVisible = false
    @State private var featureVisibility: [Bool] = [false, false, false]

    private let features: [(icon: String, title: String, description: String)] = [
        ("camera.fill", "Capture", "Photograph plants in the field and identify them instantly"),
        ("book.fill", "Library", "Build your personal herbarium of observed species"),
        ("safari.fill", "Explore", "Discover new plants waiting to be found nearby")
    ]

    var body: some View {
        VStack(spacing: FieldSpace.xl) {
            Spacer()

            // Chapter header
            ChapterHeader("Field Guide", subtitle: "How It Works")
                .padding(.horizontal, FieldSpace.md)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : 10)

            // Feature cards in vertical stack with connecting lines
            VStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    featureRow(feature, index: index)
                        .opacity(featureVisibility[index] ? 1 : 0)
                        .offset(x: featureVisibility[index] ? 0 : -20)

                    if index < features.count - 1 {
                        // Connecting line between features
                        connectingLine
                            .opacity(featureVisibility[index] ? 1 : 0)
                    }
                }
            }
            .padding(.horizontal, FieldSpace.lg)

            Spacer()
            Spacer()
        }
        .onAppear {
            // Header appears first
            withAnimation(.easeOut(duration: 0.4)) {
                headerVisible = true
            }
            // Staggered feature animations
            for i in 0..<features.count {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2 + Double(i) * 0.15)) {
                    featureVisibility[i] = true
                }
            }
        }
    }

    // MARK: - Feature Row

    private func featureRow(_ feature: (icon: String, title: String, description: String), index: Int) -> some View {
        HStack(spacing: FieldSpace.md) {
            // Icon in circle
            ZStack {
//                Circle()
//                    .fill(FieldColor.accent.opacity())
//                    .frame(width: 56, height: 56)

                Circle()
                    .stroke(FieldColor.accent, lineWidth: 1)
                    .frame(width: 56, height: 56)

                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(FieldColor.accent)
            }

            // Text content
            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                Text(feature.title)
                    .font(FieldType.title3)
                    .foregroundColor(FieldColor.vintageInk)

                Text(feature.description)
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, FieldSpace.sm)
    }

    // MARK: - Connecting Line

    private var connectingLine: some View {
        HStack {
            Rectangle()
                .fill(FieldColor.bookBorder)
                .frame(width: 1.5, height: 24)
                .padding(.leading, 27) // Center under the 56pt circle
            Spacer()
        }
    }
}

#Preview {
    OnboardingFeaturesPage()
        .background(FieldColor.paper)
}
