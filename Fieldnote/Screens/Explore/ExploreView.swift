//
//  ExploreView.swift
//  Fieldnote
//
//  Curated sections view for exploring plants with discovery catalog
//

import SwiftUI
import UIKit

struct ExploreView: View {
    @Environment(\.appStore) private var store
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(TabBarVisibility.self) private var tabBar: TabBarVisibility?
    @State private var searchQuery = ""
    @State private var isSearchPresented = false
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
        .modifier(
            PresentedSearchModifier(
                text: $searchQuery,
                isPresented: $isSearchPresented
            )
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !isSearchPresented {
                    Button {
                        isSearchPresented = true
                    } label: {
                        Label("Search plants", systemImage: "magnifyingglass")
                    }
                    .accessibilityIdentifier("explore.search")
                }
            }
        }
        .onChange(of: isSearchPresented) { _, presented in
            tabBar?.suppressed = presented
            if !presented {
                searchQuery = ""
            }
        }
        .onDisappear {
            tabBar?.suppressed = false
        }
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, showRegionPicker {
                appStore.prepareRegionPicker()
            }
        }
        .sheet(isPresented: $showRegionPicker) {
            RegionPickerSheet(
                selectedRegion: appStore.selectedRegionOverride,
                detectionState: appStore.regionDetectionState,
                onDetect: { await appStore.detectRegion() },
                onOpenSettings: openLocationSettings,
                onSelect: { region in
                    Task { await appStore.selectRegion(region) }
                }
            )
        }
    }

    @ViewBuilder
    private func browseSections(appStore: AppStore) -> some View {
        if appStore.hasLocalCatalog {
            localCatalogSections(appStore: appStore)
        } else if appStore.selectedRegionOverride != nil {
            regionHeader(appStore: appStore)
            localCatalogStatus(appStore: appStore)
            standardSections(appStore: appStore)
        } else {
            LocalDiscoveryPrompt {
                presentRegionPicker(appStore: appStore)
            }
            standardSections(appStore: appStore)
        }
    }

    private func presentRegionPicker(appStore: AppStore) {
        appStore.prepareRegionPicker()
        showRegionPicker = true
    }

    private func openLocationSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(settingsURL)
    }

    /// Ecology-led ordering when a locality exists: Commonly Reported → More to
    /// Look For → the existing Recently Encountered / custom / full catalog.
    @ViewBuilder
    private func localCatalogSections(appStore: AppStore) -> some View {
        regionHeader(appStore: appStore)

        // For current location the data is a local radius, so say "Near You"
        // rather than a reverse-geocoded state name over local data. A chosen
        // region names the place: "Common in Hawai‘i".
        let scope = appStore.selectedRegionOverride == .some(.currentLocation)
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
                presentRegionPicker(appStore: appStore)
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
        if case .some(.region(let region)) = appStore.selectedRegionOverride {
            return region.name
        }
        return appStore.localityProfile?.displayRegion ?? "Current Location"
    }

    @ViewBuilder
    private func localCatalogStatus(appStore: AppStore) -> some View {
        switch appStore.localCatalogLoadState {
        case .loading:
            HStack(spacing: FieldSpace.sm) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading plants for \(regionName(appStore: appStore))…")
                    .font(.caption)
                    .foregroundStyle(FieldColor.fadedInk)
            }
            .padding(.horizontal, FieldSpace.md)
            .accessibilityElement(children: .combine)
        case .unavailable:
            HStack(alignment: .top, spacing: FieldSpace.sm) {
                Image(systemName: "wifi.exclamationmark")
                    .foregroundStyle(FieldColor.errorRed)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: FieldSpace.xs) {
                    Text("Region catalog unavailable")
                        .font(.callout)
                        .foregroundStyle(FieldColor.ink)
                    Text("We couldn’t update \(regionName(appStore: appStore)). Your full catalog is still available below.")
                        .font(.caption)
                        .foregroundStyle(FieldColor.fadedInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Try Again") {
                        Task { await appStore.refreshLocalCatalog() }
                    }
                    .font(.caption)
                    .foregroundStyle(FieldColor.accent)
                    .frame(minHeight: 44, alignment: .leading)
                }
            }
            .padding(FieldSpace.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FieldColor.errorRed.opacity(0.08), in: .rect(cornerRadius: FieldRadius.card))
            .padding(.horizontal, FieldSpace.md)
        case .idle, .loaded:
            EmptyView()
        }
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

/// iOS 26 renders a dormant bottom search affordance whenever `.searchable`
/// exists in the hierarchy. Install it only for the explicit search session so
/// Explore's resting state has a single, reachable search entry point.
private struct PresentedSearchModifier: ViewModifier {
    @Binding var text: String
    @Binding var isPresented: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isPresented {
            content.searchable(
                text: $text,
                isPresented: $isPresented,
                prompt: "Search plants"
            )
        } else {
            content
        }
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    ExploreView()
//}
