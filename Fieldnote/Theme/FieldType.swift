//
//  FieldType.swift
//  Fieldnote
//
//  Typography system for the Fieldnote design system
//  Vintage botanical book aesthetic with serif fonts
//

import SwiftUI

struct FieldType {
    // MARK: - Display Titles (Decorative Serif)

    /// Display large: 38pt serif bold - for hero titles
    static let displayLarge = Font.system(size: 38, weight: .bold, design: .serif)

    /// Display title: 32pt serif bold - for major headings
    static let displayTitle = Font.system(size: 32, weight: .bold, design: .serif)

    /// Display subtitle: 24pt serif regular - for secondary display text
    static let displaySubtitle = Font.system(size: 24, weight: .regular, design: .serif)

    // MARK: - Heading Styles (Serif)

    /// Large title: 34pt serif bold
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .serif)

    /// Title 1: 28pt serif bold
    static let title1 = Font.system(size: 28, weight: .bold, design: .serif)

    /// Title 2: 22pt serif semibold
    static let title2 = Font.system(size: 22, weight: .semibold, design: .serif)

    /// Title 3: 20pt serif semibold
    static let title3 = Font.system(size: 20, weight: .semibold, design: .serif)

    // MARK: - Body Styles (Elegant Serif)

    /// Body text: 17pt serif regular
    static let body = Font.system(size: 17, weight: .regular, design: .serif)

    /// Emphasized body: 17pt serif semibold
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold, design: .serif)

    /// Callout: 16pt serif regular
    static let callout = Font.system(size: 16, weight: .regular, design: .serif)

    // MARK: - Supporting Styles (System for UI elements)

    /// Subheadline: 15pt regular
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

    /// Footnote: 13pt regular
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)

    /// Caption: 12pt regular
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Caption 2: 11pt regular
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Scientific Names (Serif Italic)

    /// Scientific name body: 17pt serif (apply .italic() modifier)
    static let scientificBody = Font.system(size: 17, weight: .regular, design: .serif)

    /// Scientific name callout: 16pt serif (apply .italic() modifier)
    static let scientificCallout = Font.system(size: 16, weight: .regular, design: .serif)

    /// Scientific name footnote: 13pt serif (apply .italic() modifier)
    static let scientificFootnote = Font.system(size: 13, weight: .regular, design: .serif)

    // MARK: - Specialized

    /// Button label: 17pt semibold (system for clarity)
    static let buttonLabel = Font.system(size: 17, weight: .semibold, design: .default)

    /// Chip label: 13pt medium
    static let chipLabel = Font.system(size: 13, weight: .medium, design: .default)

    /// Section header: 12pt serif medium - literary style with tracking
    static let sectionHeader = Font.system(size: 12, weight: .medium, design: .serif)

    /// Chapter label: 11pt medium for meta labels
    static let chapterLabel = Font.system(size: 11, weight: .medium, design: .default)
}
