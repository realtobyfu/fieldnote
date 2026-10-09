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
        VStack(alignment: .leading, spacing: 16) {
            Text("Start with a place").font(FieldBook.heading)
                .accessibilityAddTraits(.isHeader)
            Text("Choose an area to explore the plants reported there.")
                .font(.body).foregroundStyle(FieldColor.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onChooseRegion) {
                Label("Choose an area", systemImage: "map")
                    .font(.body.weight(.medium)).foregroundStyle(FieldBook.cover)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
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
