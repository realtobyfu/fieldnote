//
//  BotanicalIllustrationView.swift
//  Fieldnote
//
//  Displays botanical illustrations with vintage styling
//

import SwiftUI

struct BotanicalIllustrationView: View {
    let plantName: String
    let family: String?
    let size: IllustrationSize

    enum IllustrationSize {
        case thumbnail  // 80x80 for list views
        case card       // 140x100 for cards
        case hero       // Full width, 240 height for detail views

        var dimensions: (width: CGFloat?, height: CGFloat) {
            switch self {
            case .thumbnail: return (80, 80)
            case .card: return (140, 100)
            case .hero: return (nil, 240)
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .thumbnail: return 28
            case .card: return 40
            case .hero: return 72
            }
        }
    }

    init(_ plantName: String, family: String? = nil, size: IllustrationSize = .card) {
        self.plantName = plantName
        self.family = family
        self.size = size
    }

    var body: some View {
        Group {
            if let assetName = IllustrationService.illustrationName(
                for: plantName, family: family
            ) {
                illustrationImage(assetName)
            } else {
                fallbackPlaceholder
            }
        }
        .frame(width: size.dimensions.width, height: size.dimensions.height)
        .frame(maxWidth: size == .hero ? .infinity : nil)
    }

    // MARK: - Illustration Image

    private func illustrationImage(_ assetName: String) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .background(FieldColor.illustrationBg)
            .overlay(
                // Subtle aged paper tint
                Rectangle()
                    .fill(FieldColor.sepia.opacity(0.03))
            )
            .overlay(
                // Vintage frame border
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
            )
            .cornerRadius(FieldRadius.sm)
    }

    // MARK: - Fallback Placeholder

    private var fallbackPlaceholder: some View {
        ZStack {
            // Aged paper background
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .fill(FieldColor.illustrationBg)

            // Decorative border pattern
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .strokeBorder(
                    FieldColor.bookBorder.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
                .padding(4)

            // Plant icon
            VStack(spacing: FieldSpace.xs) {
                Image(systemName: fallbackIcon)
                    .font(.system(size: size.iconSize, weight: .light))
                    .foregroundColor(FieldColor.botanicalBrown.opacity(0.4))

                if size == .hero {
                    Text("No Illustration")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk.opacity(0.6))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .stroke(FieldColor.bookBorder.opacity(0.4), lineWidth: 0.5)
        )
    }

    private var fallbackIcon: String {
        let name = plantName.lowercased()
        if name.contains("tree") || name.contains("oak") || name.contains("maple") {
            return "tree"
        } else if name.contains("fern") {
            return "leaf.fill"
        } else if name.contains("mushroom") || name.contains("fungus") {
            return "circle.hexagonpath"
        } else {
            return "leaf.fill"
        }
    }
}

// MARK: - Undiscovered Variant

/// A faded, desaturated version for undiscovered plants
struct UndiscoveredIllustrationView: View {
    let plantName: String
    let family: String?
    let size: BotanicalIllustrationView.IllustrationSize

    init(_ plantName: String, family: String? = nil, size: BotanicalIllustrationView.IllustrationSize = .card) {
        self.plantName = plantName
        self.family = family
        self.size = size
    }

    var body: some View {
        BotanicalIllustrationView(plantName, family: family, size: size)
            .saturation(0)      // Desaturate to grayscale
            .opacity(0.5)       // Fade out
            .overlay(
                // Subtle vignette effect
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .fill(
                        RadialGradient(
                            colors: [.clear, FieldColor.agedPaper.opacity(0.3)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
            )
    }
}

// MARK: - Previews

#Preview("Illustration Sizes") {
    ScrollView {
        VStack(spacing: FieldSpace.xl) {
            Text("Hero Size")
                .font(FieldType.caption)
            BotanicalIllustrationView("Dandelion", size: .hero)

            HStack(spacing: FieldSpace.md) {
                VStack {
                    Text("Card Size")
                        .font(FieldType.caption)
                    BotanicalIllustrationView("Rose", size: .card)
                }

                VStack {
                    Text("Thumbnail")
                        .font(FieldType.caption)
                    BotanicalIllustrationView("Oak", size: .thumbnail)
                }
            }

            Text("Fallback (no illustration)")
                .font(FieldType.caption)
            BotanicalIllustrationView("Unknown Plant", size: .card)

            Text("Undiscovered")
                .font(FieldType.caption)
            UndiscoveredIllustrationView("Violet", size: .card)
        }
        .padding()
    }
    .background(FieldColor.agedPaper)
}
