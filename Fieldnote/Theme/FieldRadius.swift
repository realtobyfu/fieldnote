//
//  FieldRadius.swift
//  Fieldnote
//
//  Corner radius values for the Fieldnote design system
//

import Foundation

struct FieldRadius {
    /// Small radius: 8pt
    static let sm: CGFloat = 8

    /// Medium radius: 12pt
    static let md: CGFloat = 12

    /// Large radius (cards): 16pt
    static let lg: CGFloat = 16

    /// Extra large radius: 20pt
    static let xl: CGFloat = 20

    /// Pill shape (fully rounded): 999pt
    static let pill: CGFloat = 999

    // MARK: - Semantic Radii

    /// Standard card corner radius: 16pt
    static let card: CGFloat = lg

    /// Button corner radius: 12pt
    static let button: CGFloat = md

    /// Chip/badge corner radius: 999pt (fully rounded)
    static let chip: CGFloat = pill
}
