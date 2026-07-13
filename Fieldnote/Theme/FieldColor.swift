//
//  FieldColor.swift
//  Fieldnote
//
//  Semantic color tokens for the Fieldnote design system
//

import SwiftUI

struct FieldColor {
    // MARK: - Backgrounds

    /// Warm paper background - main app background
    static let paper = Color(red: 0.98, green: 0.97, blue: 0.95) // #FAF8F2

    /// White surface for cards and elevated content
    static let surface = Color.white

    /// Elevated surface (same as surface for light mode)
    static let surfaceElevated = Color.white

    /// Pressed state for interactive surfaces
    static let surfacePressed = Color(white: 0.97)

    // MARK: - Text

    /// Primary text color - near black
    static let ink = Color(red: 0.15, green: 0.14, blue: 0.12) // #26241E

    /// Secondary text color - muted
    static let mutedInk = Color(red: 0.45, green: 0.44, blue: 0.42) // #72706A

    /// Tertiary text color - most subtle
    static let tertiaryInk = Color(red: 0.65, green: 0.64, blue: 0.62)

    /// Text on accent backgrounds
    static let textOnAccent = Color.white

    // MARK: - Botanical Accents

    /// Muted chlorophyll green - primary accent
    static let accent = Color(red: 0.28, green: 0.56, blue: 0.42) // #478A6B

    /// Botanical brown accent
    static let botanicalBrown = Color(red: 0.58, green: 0.48, blue: 0.38) // #947A61

    /// Botanical tan - subtle accent
    static let botanicalTan = Color(red: 0.88, green: 0.84, blue: 0.76) // #E0D6C2

    // MARK: - Confidence Indicators

    /// High confidence (≥0.85)
    static let confidenceHigh = Color(red: 0.22, green: 0.72, blue: 0.44) // #38B870

    /// Medium confidence (0.60-0.84)
    static let confidenceMedium = Color(red: 0.95, green: 0.77, blue: 0.32) // #F2C451

    /// Low confidence (<0.60)
    static let confidenceLow = Color(red: 0.93, green: 0.52, blue: 0.38) // #ED8560

    // MARK: - Vintage/Aged Tones

    /// Sepia tint for aged effect
    static let sepia = Color(red: 0.44, green: 0.36, blue: 0.26) // #70593F

    /// Aged paper - slightly warmer than standard paper
    static let agedPaper = Color(red: 0.96, green: 0.94, blue: 0.89) // #F5EFE3

    /// Ink for vintage text - warmer black
    static let vintageInk = Color(red: 0.18, green: 0.15, blue: 0.10) // #2D2519

    /// Faded ink for secondary text
    static let fadedInk = Color(red: 0.42, green: 0.38, blue: 0.32) // #6B6152

    /// Border color for book-like frames
    static let bookBorder = Color(red: 0.78, green: 0.72, blue: 0.62) // #C7B89E

    /// Illustration background - cream tint
    static let illustrationBg = Color(red: 0.98, green: 0.96, blue: 0.92) // #FAF5EB

    /// Specimen-sheet card stock - warm near-white, sits between surface and agedPaper
    static let parchment = Color(red: 0.992, green: 0.984, blue: 0.965) // #FDFBF6

    // MARK: - Dividers & Borders

    /// Very subtle separator line
    static let separator = Color(red: 0.90, green: 0.89, blue: 0.87) // #E5E4E0

    /// Subtle border
    static let border = Color(red: 0.85, green: 0.84, blue: 0.82)

    // MARK: - Semantic States

    /// Error state
    static let errorRed = Color(red: 0.85, green: 0.25, blue: 0.23)

    /// Warning state
    static let warningOrange = Color(red: 0.95, green: 0.60, blue: 0.20)

    /// Success state
    static let successGreen = confidenceHigh

    // MARK: - Modern Redesign (2026) — "Blend" direction
    // Additive tokens for the modernized, glass-forward look. Light "Herbarium"
    // base with an immersive "Dusk" treatment reserved for full-bleed photo/detail/map.

    /// Deep botanical green — gradient base for rings, progress, the Capture button.
    static let accentDeep = Color(red: 0.23, green: 0.48, blue: 0.36) // #3B7A5C

    /// Bright botanical green — accents on dark immersive surfaces.
    static let accentBright = Color(red: 0.56, green: 0.78, blue: 0.49) // #8FC77D

    /// Warm canvas gradient start (modern app background).
    static let canvasTop = Color(red: 0.985, green: 0.965, blue: 0.945) // #FBF6F1

    /// Warm canvas gradient end (modern app background).
    static let canvasBottom = Color(red: 0.945, green: 0.918, blue: 0.875) // #F1EADF

    /// Near-black ink used for full-bleed photo scrims (immersive "Dusk" treatment).
    static let photoScrim = Color(red: 0.07, green: 0.06, blue: 0.04) // #121009

    /// Warm ember — streak accent.
    static let ember = Color(red: 0.76, green: 0.38, blue: 0.17) // #C2602B
}

// MARK: - Helper for Confidence Colors

extension FieldColor {
    /// Returns the appropriate confidence color based on confidence value (0.0...1.0)
    static func confidence(for value: Double) -> Color {
        if value >= 0.85 {
            return confidenceHigh
        } else if value >= 0.60 {
            return confidenceMedium
        } else {
            return confidenceLow
        }
    }

    /// Returns the confidence label based on confidence value (0.0...1.0)
    static func confidenceLabel(for value: Double) -> String {
        if value >= 0.85 {
            return "High"
        } else if value >= 0.60 {
            return "Medium"
        } else {
            return "Low"
        }
    }
}
