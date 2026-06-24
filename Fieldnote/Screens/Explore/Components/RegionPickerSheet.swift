//
//  RegionPickerSheet.swift
//  Fieldnote
//
//  Minimal region picker for the locale-aware Explore catalog: "Current
//  Location" plus a short curated list of cities (enough to prove the travel
//  case in Milestone 1). Selecting a region only changes how Explore is ranked;
//  it never touches the region stored on an observation.
//  See LocaleAwareCatalogImplementationPlan.md (B3).
//

import SwiftUI

/// A few well-known cities spread across hemispheres so different selections
/// visibly change the Explore screen. Coordinates are city centers; the locality
/// layer rounds them to a coarse cell before any network call.
struct PresetRegion: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double

    var asExploreRegion: ExploreRegion {
        .chosen(latitude: latitude, longitude: longitude, name: name)
    }

    static let presets: [PresetRegion] = [
        PresetRegion(name: "San Francisco, CA", latitude: 37.77, longitude: -122.42),
        PresetRegion(name: "New York, NY", latitude: 40.71, longitude: -74.01),
        PresetRegion(name: "Seattle, WA", latitude: 47.61, longitude: -122.33),
        PresetRegion(name: "Austin, TX", latitude: 30.27, longitude: -97.74),
        PresetRegion(name: "London, UK", latitude: 51.51, longitude: -0.13),
        PresetRegion(name: "Berlin, DE", latitude: 52.52, longitude: 13.40),
        PresetRegion(name: "Sydney, AU", latitude: -33.87, longitude: 151.21),
        PresetRegion(name: "Cape Town, ZA", latitude: -33.92, longitude: 18.42)
    ]
}

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

                Section("Cities") {
                    ForEach(PresetRegion.presets) { region in
                        Button {
                            onSelect(region.asExploreRegion)
                            dismiss()
                        } label: {
                            HStack {
                                Text(region.name)
                                    .foregroundColor(FieldColor.ink)
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
