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

    private var whyThisPlant: String? {
        item.explanationCodes.first?.label
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
