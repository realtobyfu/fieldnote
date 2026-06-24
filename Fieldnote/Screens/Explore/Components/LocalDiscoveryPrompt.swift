//
//  LocalDiscoveryPrompt.swift
//  Fieldnote
//
//  Pre-permission explainer that sells the value of local discovery before we
//  ask for location. Offers "Use Approximate Location" (triggers the system
//  prompt via a refresh) and "Choose a City/Region" (no permission needed).
//  See LocaleAwareCatalogImplementationPlan.md (B2).
//

import SwiftUI
import CoreLocation

struct LocalDiscoveryPrompt: View {
    /// Called when the user opts into using their (approximate) current location.
    let onUseLocation: () -> Void
    /// Called when the user picks a city, with that city's coarse coordinate.
    let onChooseRegion: (ExploreRegion) -> Void

    @State private var showCityPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.md) {
            SectionHeader(title: "Discover Plants Nearby")
                .padding(.horizontal, FieldSpace.md)

            VintageCard {
                VStack(alignment: .leading, spacing: FieldSpace.md) {
                    HStack(alignment: .top, spacing: FieldSpace.sm) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(FieldColor.accent)

                        VStack(alignment: .leading, spacing: FieldSpace.xs) {
                            Text("See what's growing around you")
                                .font(FieldType.bodyEmphasized)
                                .foregroundColor(FieldColor.vintageInk)

                            Text("See plants reported near you and what is active this season. We only ever send a rough area — never your exact spot.")
                                .font(FieldType.caption)
                                .foregroundColor(FieldColor.mutedInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(spacing: FieldSpace.sm) {
                        Button {
                            onUseLocation()
                        } label: {
                            Label("Use Approximate Location", systemImage: "location.fill")
                                .font(FieldType.buttonLabel)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, FieldSpace.sm)
                                .background(FieldColor.accent)
                                .cornerRadius(FieldRadius.button)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showCityPicker = true
                        } label: {
                            Label("Choose a City / Region", systemImage: "map")
                                .font(FieldType.buttonLabel)
                                .foregroundColor(FieldColor.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, FieldSpace.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: FieldRadius.button)
                                        .stroke(FieldColor.accent, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, FieldSpace.md)
        }
        .sheet(isPresented: $showCityPicker) {
            RegionPickerSheet(includeCurrentLocation: false) { region in
                onChooseRegion(region)
            }
        }
    }
}
