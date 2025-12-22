//
//  FieldType.swift
//  Fieldnote
//
//  Typography system for the Fieldnote design system
//

import SwiftUI

struct FieldType {
    // MARK: - Heading Styles

    /// Large title: 34pt bold
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)

    /// Title 1: 28pt bold
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)

    /// Title 2: 22pt semibold
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)

    /// Title 3: 20pt semibold
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: - Body Styles

    /// Body text: 17pt regular
    static let body = Font.system(size: 17, weight: .regular, design: .default)

    /// Emphasized body: 17pt semibold
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold, design: .default)

    /// Callout: 16pt regular
    static let callout = Font.system(size: 16, weight: .regular, design: .default)

    // MARK: - Supporting Styles

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

    /// Button label: 17pt semibold
    static let buttonLabel = Font.system(size: 17, weight: .semibold, design: .default)

    /// Chip label: 13pt medium
    static let chipLabel = Font.system(size: 13, weight: .medium, design: .default)

    /// Section header: 11pt semibold uppercase (apply .uppercase() modifier)
    static let sectionHeader = Font.system(size: 11, weight: .semibold, design: .default)
}
