//
//  LocalDiscoveryPrompt.swift
//  Fieldnote
//
//  Compact entry point shown until the user chooses or detects a region.
//  See LocaleAwareCatalogImplementationPlan.md (B2).
//

import SwiftUI

struct LocalDiscoveryPrompt: View {
    let onChooseRegion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.md) {
            SectionHeader(title: "Discover Plants Nearby")
                .padding(.horizontal, FieldSpace.md)
                .accessibilityAddTraits(.isHeader)

            VintageCard {
                VStack(alignment: .leading, spacing: FieldSpace.md) {
                    HStack(alignment: .top, spacing: FieldSpace.sm) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(FieldColor.accent)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: FieldSpace.xs) {
                            Text("Explore plants in your region")
                                .font(.system(.body, design: .serif, weight: .semibold))
                                .foregroundStyle(FieldColor.vintageInk)

                            Text("Choose a region to see what’s common nearby and in season.")
                                .font(.caption)
                                .foregroundStyle(FieldColor.mutedInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)

                    Button(action: onChooseRegion) {
                        Label("Choose Region", systemImage: "map")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FieldSpace.sm)
                            .frame(minHeight: 44)
                            .background(FieldColor.accent)
                            .clipShape(.rect(cornerRadius: FieldRadius.button))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, FieldSpace.md)
        }
    }
}

#if DEBUG
#Preview("Local discovery · No region") {
    ScrollView {
        LocalDiscoveryPrompt(onChooseRegion: {})
        .padding(.vertical, FieldSpace.md)
    }
    .background(FieldColor.paper)
}

#Preview("Local discovery · Accessibility text") {
    ScrollView {
        LocalDiscoveryPrompt(onChooseRegion: {})
        .padding(.vertical, FieldSpace.md)
    }
    .background(FieldColor.paper)
    .dynamicTypeSize(.accessibility3)
}
#endif
