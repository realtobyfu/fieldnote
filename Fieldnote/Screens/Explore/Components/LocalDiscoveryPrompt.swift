//
//  LocalDiscoveryPrompt.swift
//  Fieldnote
//
//  Fallback shown when automatic local discovery could not resolve a location.
//  It offers a retry/settings route and a named region that needs no permission.
//  See LocaleAwareCatalogImplementationPlan.md (B2).
//

import SwiftUI

enum LocalDiscoveryLocationAction {
    case retry
    case openSettings

    var title: String {
        switch self {
        case .retry: "Try Approximate Location Again"
        case .openSettings: "Open Location Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .retry: "location.fill"
        case .openSettings: "gear"
        }
    }
}

struct LocalDiscoveryPrompt: View {
    let locationAction: LocalDiscoveryLocationAction
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
                            Label(locationAction.title, systemImage: locationAction.systemImage)
                                .font(FieldType.buttonLabel)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, FieldSpace.sm)
                                .frame(minHeight: 44)
                                .background(FieldColor.accent)
                                .clipShape(.rect(cornerRadius: FieldRadius.button))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showCityPicker = true
                        } label: {
                            Label("Choose a City / Region", systemImage: "map")
                                .font(FieldType.buttonLabel)
                                .foregroundStyle(FieldColor.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, FieldSpace.sm)
                                .frame(minHeight: 44)
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

#if DEBUG
#Preview("Local discovery · Retry") {
    ScrollView {
        LocalDiscoveryPrompt(
            locationAction: .retry,
            onUseLocation: {},
            onChooseRegion: { _ in }
        )
        .padding(.vertical, FieldSpace.md)
    }
    .background(FieldColor.paper)
}

#Preview("Local discovery · Settings required") {
    ScrollView {
        LocalDiscoveryPrompt(
            locationAction: .openSettings,
            onUseLocation: {},
            onChooseRegion: { _ in }
        )
        .padding(.vertical, FieldSpace.md)
    }
    .background(FieldColor.paper)
}
#endif
