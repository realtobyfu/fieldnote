//
//  ExploreView.swift
//  Fieldnote
//
//  Curated sections view for exploring plants with discovery catalog
//

import SwiftUI

struct ExploreView: View {
    @Environment(\.appStore) private var store
    @State private var searchQuery = ""
    @State private var showRegionPicker = false
    /// True once we've kicked off a local-catalog load this session, so the
    /// pre-permission prompt doesn't flash while the first fetch is in flight.
    @State private var didRequestLocalCatalog = false

    var body: some View {
        Group {
            if let appStore = store {
                exploreContent(appStore: appStore)
            } else {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app.")
                )
            }
        }
        .background(FieldColor.paper)
        .navigationTitle("Explore")
        .searchable(text: $searchQuery, prompt: "Search plants")
        .navigationDestination(for: Plant.self) { plant in
            PlantDetailView(plant: plant)
        }
        .navigationDestination(for: CatalogPlant.self) { catalogPlant in
            CatalogPlantDetailView(catalogPlant: catalogPlant)
        }
    }

    private var trimmedQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private func exploreContent(appStore: AppStore) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.xl) {
                if trimmedQuery.isEmpty {
                    browseSections(appStore: appStore)
                } else {
                    searchResults(appStore: appStore)
                }
            }
            .padding(.vertical, FieldSpace.md)
        }
        .refreshable {
            await appStore.refresh()
        }
        .task {
            // Attempt a locale-aware load once Explore appears. Resilient: if no
            // location is available, state stays empty and we show the prompt.
            guard !didRequestLocalCatalog else { return }
            didRequestLocalCatalog = true
            await appStore.refreshLocalCatalog()
        }
        .sheet(isPresented: $showRegionPicker) {
            RegionPickerSheet { region in
                Task { await appStore.selectRegion(region) }
            }
        }
    }

    @ViewBuilder
    private func browseSections(appStore: AppStore) -> some View {
        if appStore.hasLocalCatalog {
            localCatalogSections(appStore: appStore)
        } else if !didRequestLocalCatalog || appStore.isRefreshingLocalCatalog {
            // First load in flight — fall through to the standard sections so
            // nothing flashes; the local sections appear once ranked.
            standardSections(appStore: appStore)
        } else {
            // No locality resolved (permission not granted, no region chosen):
            // offer the value prompt, then the standard sections below it.
            LocalDiscoveryPrompt(
                onUseLocation: {
                    Task { await appStore.selectRegion(.currentLocation) }
                },
                onChooseRegion: { region in
                    Task { await appStore.selectRegion(region) }
                }
            )
            standardSections(appStore: appStore)
        }
    }

    /// Ecology-led ordering when a locality exists: Commonly Reported → More to
    /// Look For → the existing Recently Encountered / custom / full catalog.
    @ViewBuilder
    private func localCatalogSections(appStore: AppStore) -> some View {
        regionHeader(appStore: appStore)

        // For current location the data is a local radius, so say "Near You"
        // rather than a reverse-geocoded state name over local data. A chosen
        // region names the place: "Common in Hawai‘i".
        let scope = appStore.selectedRegionOverride == .currentLocation
            ? "Near You"
            : "in \(regionName(appStore: appStore))"

        let common = appStore.commonlyReportedItems
        if !common.isEmpty {
            LocalCatalogSection(
                title: "Common \(scope)",
                items: common,
                isDiscovered: appStore.isDiscovered
            )
        }

        // Seasonal — only shows when catalog plants carry monthlyAffinity data
        // that peaks around now. Hidden otherwise.
        let active = appStore.activeThisMonthItems
        if !active.isEmpty {
            LocalCatalogSection(
                title: appStore.currentMonthName.map { "Active in \($0)" } ?? "Active This Season",
                items: active,
                isDiscovered: appStore.isDiscovered
            )
        }

        let more = appStore.moreToLookForItems
        if !more.isEmpty {
            LocalCatalogSection(
                title: "More to Look For \(scope)",
                items: more,
                isDiscovered: appStore.isDiscovered
            )
        }

        standardSections(appStore: appStore)
    }

    /// The pre-existing browse experience, used as a fallback so nothing regresses.
    @ViewBuilder
    private func standardSections(appStore: AppStore) -> some View {
        ExploreSection(
            title: "Recently Encountered",
            plants: appStore.recentlyEncountered
        )

        let customPlants = appStore.customPlants
        if !customPlants.isEmpty {
            ExploreSection(
                title: "Your Custom Plants",
                plants: customPlants
            )
        }

        FullCatalogSection(
            catalogPlants: appStore.catalogPlants,
            isDiscovered: appStore.isDiscovered
        )
    }

    /// Region picker + freshness pill shown above the locale-aware sections.
    @ViewBuilder
    private func regionHeader(appStore: AppStore) -> some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            Button {
                showRegionPicker = true
            } label: {
                HStack(spacing: FieldSpace.xs) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(regionName(appStore: appStore))
                        .font(FieldType.callout)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(FieldColor.accent)
                .padding(.vertical, FieldSpace.xs)
                .padding(.horizontal, FieldSpace.sm)
                .background(
                    Capsule().stroke(FieldColor.accent.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if let freshness = appStore.catalogFreshnessLabel {
                Text(freshness)
                    .font(FieldType.caption2)
                    .foregroundColor(FieldColor.fadedInk)
            }
        }
        .padding(.horizontal, FieldSpace.md)
    }

    private func regionName(appStore: AppStore) -> String {
        if case .region(let region) = appStore.selectedRegionOverride {
            return region.name
        }
        return appStore.localityProfile?.displayRegion ?? "Current Location"
    }

    @ViewBuilder
    private func searchResults(appStore: AppStore) -> some View {
        let matchedPlants = appStore.searchPlants(trimmedQuery)
        let matchedCatalog = appStore.searchCatalog(trimmedQuery)

        if matchedPlants.isEmpty && matchedCatalog.isEmpty {
            ContentUnavailableView.search(text: trimmedQuery)
                .padding(.top, FieldSpace.xl)
        } else {
            if !matchedPlants.isEmpty {
                ExploreSection(
                    title: "Your Plants",
                    plants: matchedPlants
                )
            }

            if !matchedCatalog.isEmpty {
                CatalogSection(
                    title: "Catalog",
                    catalogPlants: matchedCatalog
                )
            }
        }
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    ExploreView()
//}
