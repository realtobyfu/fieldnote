//
//  LocalCatalogSection.swift
//  Fieldnote
//
//  Ecology-led Explore sections driven by the locale-aware ranking. Each card
//  carries a "Why this plant?" line built from the item's explanation codes.
//  Wording stays at "reported nearby" — never abundance.
//  See LocaleAwareCatalogImplementationPlan.md (B3).
//

import SwiftUI

struct LocalCatalogSection: View {
    let title: String
    let items: [LocalCatalogItem]
    let isDiscovered: (CatalogPlant) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            HStack {
                SectionHeader(title: title)
                Spacer()
                if !items.isEmpty {
                    Text("\(items.count)")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }
            .padding(.horizontal, FieldSpace.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: FieldSpace.sm) {
                    ForEach(items) { item in
                        NavigationLink(value: item.catalogPlant) {
                            LocalCatalogCard(
                                item: item,
                                isDiscovered: isDiscovered(item.catalogPlant)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, FieldSpace.md)
            }
        }
    }
}

// MARK: - Card

/// A catalog card annotated with the locale-aware "Why this plant?" reason.
struct LocalCatalogCard: View {
    let item: LocalCatalogItem
    let isDiscovered: Bool

    /// The card's "Why this plant?" line. We skip the occurrence codes
    /// (commonly/also reported) — the section header already says that — and only
    /// surface a genuinely additive reason like a seasonal peak or a first find.
    private var whyThisPlant: String? {
        item.explanationCodes.first { code in
            switch code {
            case .commonlyReported, .alsoReported: return false
            case .seasonalPeak, .easyFirstFind: return true
            }
        }?.label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            ZStack(alignment: .topTrailing) {
                if isDiscovered {
                    BotanicalIllustrationView(
                        item.catalogPlant.commonName,
                        family: item.catalogPlant.family,
                        size: .card
                    )
                } else {
                    UndiscoveredIllustrationView(
                        item.catalogPlant.commonName,
                        family: item.catalogPlant.family,
                        size: .card
                    )
                }
            }
            .frame(width: 140, height: 100)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if isDiscovered {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(FieldColor.accent)
                        .background(
                            Circle()
                                .fill(FieldColor.surface)
                                .frame(width: 18, height: 18)
                        )
                        .padding(FieldSpace.xs)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.catalogPlant.commonName)
                    .font(FieldType.callout)
                    .foregroundColor(isDiscovered ? FieldColor.vintageInk : FieldColor.fadedInk)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)

                if let whyThisPlant {
                    HStack(alignment: .top, spacing: 3) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 9))
                            .foregroundColor(FieldColor.accent)
                            .padding(.top, 1)
                        Text(whyThisPlant)
                            .font(FieldType.caption2)
                            .foregroundColor(FieldColor.mutedInk)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(height: 30, alignment: .top)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Why this plant? \(whyThisPlant)")
                }
            }
        }
        .frame(width: 140)
    }
}

#if DEBUG
#Preview("Local Catalog Section") {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.xl) {
                LocalCatalogSection(
                    title: "Near You Now",
                    items: LocaleCatalogPreviewData.items,
                    isDiscovered: LocaleCatalogPreviewData.isDiscovered
                )
                LocalCatalogSection(
                    title: "Reported This Month",
                    items: Array(LocaleCatalogPreviewData.items.reversed()),
                    isDiscovered: LocaleCatalogPreviewData.isDiscovered
                )
            }
            .padding(.vertical, FieldSpace.md)
        }
        .background(FieldColor.paper)
        .navigationDestination(for: CatalogPlant.self) { _ in EmptyView() }
    }
}

#Preview("Local Catalog Card") {
    HStack(spacing: FieldSpace.md) {
        if let discovered = LocaleCatalogPreviewData.items.first {
            LocalCatalogCard(item: discovered, isDiscovered: true)
        }
        if let undiscovered = LocaleCatalogPreviewData.items.last {
            LocalCatalogCard(item: undiscovered, isDiscovered: false)
        }
    }
    .padding()
    .background(FieldColor.paper)
}
#endif
