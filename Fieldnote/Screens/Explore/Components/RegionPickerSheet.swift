//
//  RegionPickerSheet.swift
//  Fieldnote
//
//  Region picker for the locale-aware Explore catalog: "Current Location" plus a
//  curated list of ecological/geographic regions backed by iNaturalist place IDs
//  (multi-state regions union their states' places). Selecting a region only
//  changes how Explore is ranked; it never touches an observation's stored region.
//  See LocaleAwareCatalogImplementationPlan.md (B3).
//

import SwiftUI

struct RegionPickerSheet: View {
    /// Whether to offer a "Current Location" row at the top.
    var includeCurrentLocation: Bool = true
    let onSelect: (ExploreRegion) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if includeCurrentLocation {
                    Section {
                        Button {
                            onSelect(.currentLocation)
                            dismiss()
                        } label: {
                            Label("Current Location", systemImage: "location.fill")
                                .foregroundColor(FieldColor.ink)
                        }
                    }
                }

                Section("Regions") {
                    ForEach(CatalogRegion.presets) { region in
                        Button {
                            onSelect(.region(region))
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(region.name)
                                        .foregroundColor(FieldColor.ink)
                                    if let subtitle = region.subtitle {
                                        Text(subtitle)
                                            .font(FieldType.caption2)
                                            .foregroundColor(FieldColor.fadedInk)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Region Picker") {
    RegionPickerSheet { _ in }
}
#endif
