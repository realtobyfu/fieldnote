//
//  LocalCatalogSection.swift
//  Fieldnote
//
//  Ecology-led Explore sections driven by the locale-aware ranking.
//  Section placement carries the local context so cards can stay compact.
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

/// A compact catalog card used in locale-aware horizontal sections.
struct LocalCatalogCard: View {
    let item: LocalCatalogItem
    let isDiscovered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            ZStack(alignment: .topTrailing) {
                CatalogThumbnail(
                    catalogPlant: item.catalogPlant,
                    isDiscovered: isDiscovered,
                    size: .card
                )
            }
            .frame(width: 140, height: 100)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: FieldRadius.sm))
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

            Text(item.catalogPlant.commonName)
                .font(FieldType.callout)
                .foregroundStyle(isDiscovered ? FieldColor.vintageInk : FieldColor.fadedInk)
                .lineLimit(2)
                .frame(height: 40, alignment: .top)
        }
        .frame(width: 140)
    }
}

#if DEBUG
#Preview("Local catalog section · Compact cards") {
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

#Preview("Local catalog card · Discovery states") {
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
