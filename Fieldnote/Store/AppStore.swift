//
//  AppStore.swift
//  Fieldnote
//
//  Centralized app state with SwiftData persistence
//

import Foundation
import SwiftUI
import SwiftData
import CoreLocation

enum AppTab: Int {
    case journal
    case explore
    case capture
    case map
    case profile
}

/// Which place the Explore catalog is ranked for. This is a *view* preference —
/// it never touches the region stored on any observation. Defaults to following
/// the device's current (coarse) location. See LocaleAwareCatalogImplementationPlan.md.
enum ExploreRegion: Hashable {
    /// Use the device's current location (coarse cell).
    case currentLocation
    /// A user-chosen named region, backed by one or more iNaturalist place IDs.
    case region(CatalogRegion)
}

enum RegionDetectionState: Equatable {
    case idle
    case detecting
    case detected(CatalogRegion)
    case permissionDenied
    case servicesDisabled
    case unavailable
    case unsupported(placeName: String?)
}

enum LocalCatalogLoadState: Equatable {
    case idle
    case loading
    case loaded
    case unavailable
}

/// Outcome of resolving the device's location against the curated region set,
/// used to drive the Explore UI (auto-selection vs. a "not covered here" notice).
enum RegionCoverage: Equatable {
    /// Location hasn't been resolved yet, or Explore isn't following current
    /// location (an explicit region is selected).
    case unknown
    /// The device's location falls inside a curated region, which is now active.
    case covered(CatalogRegion)
    /// A location was resolved but it isn't inside any curated region. Carries a
    /// friendly place name for the notice, when one is available.
    case notCovered(placeName: String?)
}

/// A named discovery region defined by iNaturalist place IDs. A macro-region
/// (e.g. the Pacific Northwest) is the union of its states' place IDs, which
/// iNaturalist aggregates server-side in a single query. Place IDs verified
/// against the iNaturalist places API.
struct CatalogRegion: Identifiable, Hashable {
    let id: String
    let name: String
    /// Optional one-line context, e.g. "WA · OR".
    let subtitle: String?
    let placeIDs: [Int]

    init(id: String, name: String, subtitle: String? = nil, placeIDs: [Int]) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.placeIDs = placeIDs
    }

    /// Curated US region set. Multi-state regions union their states' place IDs.
    static let presets: [CatalogRegion] = [
        CatalogRegion(id: "california", name: "California", placeIDs: [14]),
        CatalogRegion(id: "pacific-northwest", name: "Pacific Northwest", subtitle: "WA · OR", placeIDs: [46, 10]),
        CatalogRegion(id: "desert-southwest", name: "Desert Southwest", subtitle: "AZ · NV", placeIDs: [40, 50]),
        CatalogRegion(id: "rocky-mountains", name: "Rocky Mountains", subtitle: "CO · UT", placeIDs: [34, 52]),
        CatalogRegion(id: "texas", name: "Texas", placeIDs: [18]),
        CatalogRegion(id: "florida", name: "Florida", placeIDs: [21]),
        CatalogRegion(id: "northeast", name: "Northeast US", subtitle: "NY · MA · VT", placeIDs: [48, 2, 47]),
        CatalogRegion(id: "hawaii", name: "Hawai\u{2018}i", placeIDs: [11])
    ]

    // MARK: - Location → region matching (auto-selection)

    /// Which curated region covers a given US state. Multi-state regions map each
    /// of their states here; the Northeast is broadened to the New England + NY
    /// cluster (shared flora) beyond the three representative states in its pack.
    private static let regionIDByStateCode: [String: String] = [
        "CA": "california",
        "WA": "pacific-northwest", "OR": "pacific-northwest",
        "AZ": "desert-southwest",  "NV": "desert-southwest",
        "CO": "rocky-mountains",   "UT": "rocky-mountains",
        "TX": "texas",
        "FL": "florida",
        "NY": "northeast", "MA": "northeast", "VT": "northeast",
        "CT": "northeast", "RI": "northeast", "NH": "northeast", "ME": "northeast",
        "HI": "hawaii"
    ]

    /// Full state names → two-letter codes, for the states we map. `CLPlacemark`'s
    /// `administrativeArea` returns a code in some locales and the full name in
    /// others, so we normalize both.
    private static let stateCodeByName: [String: String] = [
        "california": "CA", "washington": "WA", "oregon": "OR",
        "arizona": "AZ", "nevada": "NV", "colorado": "CO", "utah": "UT",
        "texas": "TX", "florida": "FL", "new york": "NY", "massachusetts": "MA",
        "vermont": "VT", "connecticut": "CT", "rhode island": "RI",
        "new hampshire": "NH", "maine": "ME", "hawaii": "HI", "hawai\u{2018}i": "HI"
    ]

    /// Normalizes a `CLPlacemark.administrativeArea` value to a two-letter US
    /// state code, or nil when it isn't one we recognize.
    static func normalizedStateCode(_ administrativeArea: String) -> String? {
        let trimmed = administrativeArea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count == 2 { return trimmed.uppercased() }
        return stateCodeByName[trimmed.lowercased()]
    }

    /// The curated region covering a reverse-geocoded placemark, or nil when the
    /// location isn't in one (including any location outside the US). Only US
    /// regions are curated today.
    static func matching(countryCode: String?, administrativeArea: String?) -> CatalogRegion? {
        if let code = countryCode, code.uppercased() != "US" { return nil }
        guard let administrativeArea,
              let state = normalizedStateCode(administrativeArea),
              let regionID = regionIDByStateCode[state] else { return nil }
        return presets.first { $0.id == regionID }
    }
}

/// On-device Explore preference storage. Current-location profiles contain only
/// the rounded grid cell used by the catalog, never the device's precise fix.
struct ExplorePreferences {
    private enum Keys {
        static let selectedRegionID = "explore.selectedRegionID"
        static let currentLocationProfile = "explore.currentLocationProfile"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadRegion() -> ExploreRegion? {
        guard let regionID = defaults.string(forKey: Keys.selectedRegionID),
              regionID != "current-location",
              let region = CatalogRegion.presets.first(where: { $0.id == regionID }) else {
            return nil
        }
        return .region(region)
    }

    func save(region: ExploreRegion) {
        let regionID: String
        switch region {
        case .currentLocation:
            regionID = "current-location"
        case .region(let region):
            regionID = region.id
        }
        defaults.set(regionID, forKey: Keys.selectedRegionID)
    }

    func loadCurrentLocationProfile() -> LocalityProfile? {
        guard let data = defaults.data(forKey: Keys.currentLocationProfile) else { return nil }
        return try? JSONDecoder().decode(LocalityProfile.self, from: data)
    }

    func save(currentLocationProfile profile: LocalityProfile) {
        guard profile.placeIDs == nil,
              let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: Keys.currentLocationProfile)
    }
}

@MainActor
@Observable
class AppStore {
    private var modelContext: ModelContext
    private let explorePreferences: ExplorePreferences

    // Trigger to force SwiftUI to re-evaluate computed properties
    // @Observable only tracks direct property assignments, not computed property changes
    private(set) var refreshTrigger: Int = 0

    // Navigation state
    var selectedTab: AppTab = .journal

    // Last save error for UI feedback
    var lastError: Error?

    // The active catalog. Defaults to the bundled 50; when a region pack is
    // loaded, `refreshLocalCatalog()` replaces it with the region-scoped catalog
    // (bundled 50 + that region's pack-only taxa). Everything downstream —
    // discovery, journal progress, capture matching, Explore — reads
    // `catalogPlants`, so region scoping (including the "N / region total"
    // denominator) propagates from this one property.
    private(set) var regionCatalog: [CatalogPlant]?

    /// The catalog to display and rank: the region-scoped catalog when a pack is
    /// active, else the bundled 50.
    var catalogPlants: [CatalogPlant] { regionCatalog ?? CatalogPlant.catalog }

    // MARK: - Locale-aware catalog state (PR2 / Workstream B)

    /// Coarse "where + when" the local catalog was last ranked for. `nil` until
    /// the user opts into local discovery (location or a chosen region).
    private(set) var localityProfile: LocalityProfile?
    /// Catalog entries reported nearby, ranked by Stage-1 ecological score.
    private(set) var localCatalogItems: [LocalCatalogItem] = []
    /// When the underlying species counts were fetched, for "Updated N days ago".
    private(set) var catalogFreshnessDate: Date?
    /// True while a `refreshLocalCatalog()` pass is in flight (for spinners).
    private(set) var isRefreshingLocalCatalog = false
    /// Identifies the newest catalog request so an older response cannot overwrite
    /// a region the user selected while that response was in flight.
    private var activeLocalCatalogRequestID: UUID?
    /// Catalog loading is tracked separately from location detection so a network
    /// failure never presents itself as a location failure.
    private(set) var localCatalogLoadState: LocalCatalogLoadState = .idle
    /// One-time region detection feedback displayed by the region picker.
    private(set) var regionDetectionState: RegionDetectionState = .idle

    /// Which place Explore ranks for. Changing this is a view preference and is
    /// deliberately *not* persisted onto any observation.
    var selectedRegionOverride: ExploreRegion?

    /// Result of matching the device's location against the curated regions,
    /// driving auto-selection and the "not covered here" notice. Updated whenever
    /// the local catalog refreshes while following current location.
    private(set) var regionCoverage: RegionCoverage = .unknown

    /// Radius (km) used for the nearby query — kept in one place for copy + query.
    let localCatalogRadiusKm = 25

    init(modelContext: ModelContext, userDefaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        let explorePreferences = ExplorePreferences(defaults: userDefaults)
        self.explorePreferences = explorePreferences
        self.selectedRegionOverride = explorePreferences.loadRegion()
    }

    // MARK: - Plants (from SwiftData)

    var plants: [Plant] {
        // Access trigger to establish observation dependency
        _ = refreshTrigger
        let descriptor = FetchDescriptor<Plant>(
            sortBy: [SortDescriptor(\.commonName)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Catalog & Discovery

    func isDiscovered(_ catalogPlant: CatalogPlant) -> Bool {
        plants.contains { $0.commonName.lowercased() == catalogPlant.commonName.lowercased() }
    }

    var undiscoveredPlants: [CatalogPlant] {
        catalogPlants.filter { !isDiscovered($0) }
    }

    var discoveredCatalogPlants: [CatalogPlant] {
        catalogPlants.filter { isDiscovered($0) }
    }

    /// User-saved plants whose common name doesn't match any catalog entry.
    var customPlants: [Plant] {
        let catalogNames = Set(catalogPlants.map { $0.commonName.lowercased() })
        return plants.filter { !catalogNames.contains($0.commonName.lowercased()) }
    }

    // MARK: - Location Grouping

    var uniqueLocations: [String] {
        let locations = plants.flatMap { plant in
            (plant.encounters ?? []).compactMap { $0.displayLocationName }
        }
        return Array(Set(locations)).sorted()
    }

    var plantsByLocation: [(location: String, plants: [Plant])] {
        var locationMap: [String: Set<UUID>] = [:]

        for plant in plants {
            for encounter in plant.encounters ?? [] {
                if let location = encounter.displayLocationName {
                    locationMap[location, default: []].insert(plant.id)
                }
            }
        }

        return locationMap.map { (location, plantIds) in
            let plantsAtLocation = plants.filter { plantIds.contains($0.id) }
            return (location: location, plants: plantsAtLocation)
        }
        .sorted { $0.plants.count > $1.plants.count }
    }

    func undiscoveredPlants(forHabitat habitat: String) -> [CatalogPlant] {
        let lowercasedHabitat = habitat.lowercased()
        return undiscoveredPlants.filter { plant in
            plant.habitat.lowercased().contains(lowercasedHabitat) ||
            habitatKeywords(for: lowercasedHabitat).contains { keyword in
                plant.habitat.lowercased().contains(keyword)
            }
        }
    }

    private func habitatKeywords(for location: String) -> [String] {
        let location = location.lowercased()

        if location.contains("park") || location.contains("garden") || location.contains("botanical") {
            return ["urban", "gardens", "meadows", "forests"]
        }
        if location.contains("forest") || location.contains("wood") || location.contains("trail") {
            return ["forests", "woodlands"]
        }
        if location.contains("lake") || location.contains("pond") || location.contains("creek") ||
           location.contains("river") || location.contains("marsh") || location.contains("wetland") {
            return ["wetlands", "streams"]
        }
        if location.contains("meadow") || location.contains("field") || location.contains("prairie") {
            return ["meadows", "grasslands"]
        }
        if location.contains("street") || location.contains("yard") || location.contains("campus") ||
           location.contains("neighborhood") || location.contains("downtown") {
            return ["urban", "gardens", "disturbed"]
        }
        return ["meadows", "forests", "urban"]
    }

    // MARK: - Nearby Habitat Detection

    /// Infer habitat type from nearby place names
    func inferHabitatType(from places: [SelectedLocation]) -> String? {
        let placeNames = places.map { $0.name.lowercased() }
        let combinedText = placeNames.joined(separator: " ")

        // Priority order: specific habitat types
        if combinedText.contains("wetland") || combinedText.contains("marsh") ||
           combinedText.contains("lake") || combinedText.contains("creek") ||
           combinedText.contains("pond") || combinedText.contains("river") {
            return "wetlands"
        }
        if combinedText.contains("forest") || combinedText.contains("woods") ||
           combinedText.contains("trail") || combinedText.contains("nature reserve") {
            return "forests"
        }
        if combinedText.contains("meadow") || combinedText.contains("prairie") ||
           combinedText.contains("field") || combinedText.contains("grassland") {
            return "meadows"
        }
        if combinedText.contains("park") || combinedText.contains("garden") ||
           combinedText.contains("botanical") {
            return "urban"
        }

        return "urban"  // Default for unrecognized areas
    }

    /// Get undiscovered plants matching a habitat type
    func undiscoveredPlantsNearby(habitatType: String) -> [CatalogPlant] {
        undiscoveredPlants.filter { plant in
            plant.habitat.lowercased().contains(habitatType.lowercased())
        }
    }

    var mixedPlantsByLocation: [(location: String, discovered: [Plant], undiscovered: [CatalogPlant])] {
        plantsByLocation.map { locationGroup in
            let undiscovered = undiscoveredPlants(forHabitat: locationGroup.location)
            return (
                location: locationGroup.location,
                discovered: locationGroup.plants,
                undiscovered: Array(undiscovered.prefix(10))
            )
        }
    }

    // MARK: - Plant Operations

    func addPlant(_ plant: Plant) {
        modelContext.insert(plant)
        save()
        refreshTrigger += 1
    }

    func deletePlant(_ plant: Plant) {
        modelContext.delete(plant)
        save()
        refreshTrigger += 1
    }

    func plant(withId id: UUID) -> Plant? {
        plants.first { $0.id == id }
    }

    func plant(withCommonName name: String) -> Plant? {
        plants.first { $0.commonName.lowercased() == name.lowercased() }
    }

    // MARK: - Encounter Operations

    func addEncounter(_ encounter: Encounter, to plant: Plant) {
        encounter.plant = plant
        if plant.encounters == nil {
            plant.encounters = []
        }
        plant.encounters?.append(encounter)
        plant.updatedAt = Date()
        modelContext.insert(encounter)
        save()
        refreshTrigger += 1
    }

    func deleteEncounter(_ encounter: Encounter) {
        modelContext.delete(encounter)
        save()
        refreshTrigger += 1
    }

    // MARK: - Save

    private func save() {
        do {
            try modelContext.save()
            lastError = nil
        } catch {
            lastError = error
            print("Failed to save: \(error)")
        }
    }

    // MARK: - Refresh

    /// Force a refresh of all data by incrementing the trigger
    func refresh() async {
        // Small delay for visual feedback
        try? await Task.sleep(nanoseconds: 300_000_000)
        refreshTrigger += 1
        await refreshLocalCatalog()
    }

    // MARK: - Locale-aware Catalog Refresh (PR2 / Workstream B)

    /// Resolves the current Explore region into a `LocalityProfile`, fetches (or
    /// reuses a cached) iNaturalist species count, and ranks the bundled catalog
    /// against it. Resilient by design: on any failure the existing state is left
    /// untouched so the screen never regresses to empty.
    func refreshLocalCatalog() async {
        guard let requestedRegion = selectedRegionOverride else {
            localCatalogLoadState = .idle
            return
        }

        let requestID = UUID()
        activeLocalCatalogRequestID = requestID
        isRefreshingLocalCatalog = true
        localCatalogLoadState = .loading
        defer {
            if activeLocalCatalogRequestID == requestID {
                isRefreshingLocalCatalog = false
            }
        }

        // 1. Build a locality profile for the chosen region.
        guard let profile = await resolveLocalityProfile(for: requestedRegion),
              activeLocalCatalogRequestID == requestID,
              selectedRegionOverride == requestedRegion else {
            if activeLocalCatalogRequestID == requestID {
                localCatalogLoadState = .unavailable
            }
            return
        }
        guard !Task.isCancelled else {
            if activeLocalCatalogRequestID == requestID {
                localCatalogLoadState = .idle
            }
            return
        }
        localityProfile = profile

        // 2. Resolve the ranking inputs: a precomputed region pack (2B) for named
        //    regions, else the live iNaturalist species-count path.
        guard let inputs = await resolveRankingInputs(for: profile, region: requestedRegion),
              activeLocalCatalogRequestID == requestID,
              selectedRegionOverride == requestedRegion else {
            if activeLocalCatalogRequestID == requestID {
                localCatalogLoadState = .unavailable
            }
            return
        }
        guard !Task.isCancelled else {
            if activeLocalCatalogRequestID == requestID {
                localCatalogLoadState = .idle
            }
            return
        }

        // 3. Rank the catalog against the counts (pure, synchronous).
        let items = LocalRankingService().rank(
            catalog: inputs.catalog,
            counts: inputs.counts,
            month: profile.currentMonth
        )

        guard activeLocalCatalogRequestID == requestID,
              selectedRegionOverride == requestedRegion else { return }

        // 4. Publish. Direct assignment is fine — these are stored properties.
        //    `regionCatalog` becomes the ranked catalog: the region-scoped set on
        //    the pack path, the bundled 50 on the live path. This drives the
        //    discovery denominator and every `catalogPlants` reader.
        localityProfile = profile
        localCatalogItems = items
        catalogFreshnessDate = inputs.fetchedAt
        regionCatalog = inputs.catalog
        localCatalogLoadState = .loaded
    }

    /*
     The request token above intentionally allows a newer selection to begin while
     an older fetch is suspended. Only the newest request is allowed to publish.
     */

    /// The pieces `LocalRankingService.rank` needs, sourced from whichever path
    /// applies to the current region.
    private struct RankingInputs {
        let counts: [INatSpeciesCount]
        /// The catalog to rank — bundled, with pack-refreshed affinity folded in
        /// on the region-pack path.
        let catalog: [CatalogPlant]
        let fetchedAt: Date
    }

    /// Chooses the data source for the chosen region. Named regions use the
    /// precomputed backend pack when the backend is configured, falling back to
    /// the live iNaturalist path when no pack is available. `.currentLocation`
    /// always uses the live path (2B Phase 1).
    private func resolveRankingInputs(
        for profile: LocalityProfile,
        region requestedRegion: ExploreRegion
    ) async -> RankingInputs? {
        if case .region(let region) = requestedRegion {
            if let packInputs = await regionPackInputs(regionID: region.id) {
                return packInputs
            }
            // No pack at any layer (no backend, no cache, no bundled fixture):
            // fall through to the live iNaturalist path.
        }
        return await liveSpeciesCountInputs(for: profile)
    }

    /// Region-pack inputs, most-fresh first: a live backend pack (when configured),
    /// then the last cached pack, then the bundled fixture pack. Returns nil only
    /// when no pack exists at any layer, so the caller can fall back to live iNat.
    private func regionPackInputs(regionID: String) async -> RankingInputs? {
        let pack: RegionPack
        if BackendConfig.baseURL != nil {
            do {
                switch try await RegionPackService.shared.fetchPack(regionID: regionID) {
                case .updated(let fetched): pack = fetched
                case .notModified(let cached): pack = cached
                }
            } catch {
                guard let fallback = await LocalCatalogCache.shared.regionPack(for: regionID)
                    ?? BundledRegionPacks.pack(for: regionID) else {
                    return nil
                }
                pack = fallback
            }
        } else {
            // No backend: use the last cached pack, else the shipped fixture.
            guard let fallback = await LocalCatalogCache.shared.regionPack(for: regionID)
                ?? BundledRegionPacks.pack(for: regionID) else {
                return nil
            }
            pack = fallback
        }

        // Merge against the bundled base (never the current region's catalog) so
        // switching regions doesn't accumulate taxa from a previously loaded pack.
        return RankingInputs(
            counts: pack.speciesCounts,
            catalog: pack.catalogPlants(mergedWith: CatalogPlant.catalog),
            fetchedAt: pack.generatedAt
        )
    }

    /// Live iNaturalist path: reuse a fresh cache entry, else fetch and store,
    /// else fall back to a stale cache. Returns nil when nothing is available.
    private func liveSpeciesCountInputs(for profile: LocalityProfile) async -> RankingInputs? {
        // The live path (current location, Phase 1) ranks the bundled 50 — no pack,
        // so no catalog expansion. Always merge/rank against the bundled base.
        let base = CatalogPlant.catalog
        if let cached = await LocalCatalogCache.shared.freshEntry(for: profile.cacheKey) {
            return RankingInputs(counts: cached.counts, catalog: base, fetchedAt: cached.fetchedAt)
        }
        do {
            let fetched = try await fetchSpeciesCounts(for: profile)
            await LocalCatalogCache.shared.store(fetched, for: profile.cacheKey)
            return RankingInputs(counts: fetched, catalog: base, fetchedAt: .now)
        } catch {
            if let stale = await LocalCatalogCache.shared.entry(for: profile.cacheKey) {
                return RankingInputs(counts: stale.counts, catalog: base, fetchedAt: stale.fetchedAt)
            }
            print("refreshLocalCatalog: fetch failed and no cache: \(error)")
            return nil
        }
    }

    /// Builds a `LocalityProfile` for the chosen Explore region. For
    /// `.currentLocation` we ask `LocationService` (one-shot, may return nil when
    /// permission isn't granted yet); for `.region` we use its iNaturalist places.
    private func resolveLocalityProfile(for requestedRegion: ExploreRegion) async -> LocalityProfile? {
        switch requestedRegion {
        case .currentLocation:
            let locationService = LocationService.shared
            if let coordinate = await locationService.requestCurrentLocation() {
                // Reverse-geocode the coarse cell center (not the precise fix) for a
                // friendly label + the state used to match a curated region.
                let profile = LocalityProfile.make(from: coordinate)
                let place = await LocationGeocoderService.shared.reverseGeocodeDetailed(profile.coordinate)
                guard selectedRegionOverride == requestedRegion else { return nil }

                // Auto-select the curated region the location falls in. Persisting
                // it means the choice is remembered next launch (the user can still
                // switch, including back to Current Location to re-detect).
                if let matched = CatalogRegion.matching(
                    countryCode: place?.countryCode,
                    administrativeArea: place?.administrativeArea
                ) {
                    selectedRegionOverride = .region(matched)
                    explorePreferences.save(region: .region(matched))
                    regionCoverage = .covered(matched)
                    return LocalityProfile.makeRegion(name: matched.name, placeIDs: matched.placeIDs)
                }

                // Reverse-geocoding placed us outside every curated region — surface
                // the notice. If geocoding failed outright (no state resolved), we
                // can't claim "not covered", so stay `.unknown` and just rank near-you.
                regionCoverage = place?.administrativeArea == nil
                    ? .unknown
                    : .notCovered(placeName: place?.displayName)
                let resolvedProfile = LocalityProfile.make(from: coordinate, displayRegion: place?.displayName)
                explorePreferences.save(currentLocationProfile: resolvedProfile)
                return resolvedProfile
            }

            // A transient location failure should not make returning users pick
            // their region again. Only reuse the coarse saved cell while system
            // location access is still authorized; revoking access disables it.
            guard locationService.hasAuthorizedAccess,
                  let savedProfile = explorePreferences.loadCurrentLocationProfile() else {
                return nil
            }
            return LocalityProfile.make(
                from: savedProfile.coordinate,
                displayRegion: savedProfile.displayRegion
            )
        case .region(let region):
            regionCoverage = .covered(region)
            return LocalityProfile.makeRegion(name: region.name, placeIDs: region.placeIDs)
        }
    }

    /// Fetches species counts for a profile: by place IDs for a named region,
    /// else by the coarse coordinate + radius for current location.
    ///
    /// We fetch an **annual** baseline (no `month` filter) so "Commonly Reported
    /// in {Region}" reflects the region's flora, not whatever happened to be
    /// reported in the current calendar month. A truthful seasonal section would
    /// need real phenology data, not iNaturalist's observation-month proxy (which
    /// is biased by when people are outside).
    private func fetchSpeciesCounts(for profile: LocalityProfile) async throws -> [INatSpeciesCount] {
        if let placeIDs = profile.placeIDs, !placeIDs.isEmpty {
            return try await INaturalistService.shared.speciesCounts(placeIDs: placeIDs)
        }
        return try await INaturalistService.shared.speciesCounts(
            near: profile.coordinate,
            radiusKm: Double(localCatalogRadiusKm)
        )
    }

    /// Convenience for the region picker: switch region and refresh.
    func selectRegion(_ region: ExploreRegion) async {
        selectedRegionOverride = region
        explorePreferences.save(region: region)
        // Clear current items so the UI shows a loading state for the new region.
        localityProfile = nil
        localCatalogItems = []
        regionCatalog = nil
        localCatalogLoadState = .loading
        await refreshLocalCatalog()
    }

    /// Resets transient detection feedback whenever the picker is opened while
    /// preserving actionable system-level permission states.
    func prepareRegionPicker() {
        switch LocationService.shared.accessState {
        case .denied:
            regionDetectionState = .permissionDenied
        case .servicesDisabled:
            regionDetectionState = .servicesDisabled
        case .notDetermined, .authorized:
            regionDetectionState = .idle
        }
    }

    /// Uses location once to map the device to one of the curated regions. The
    /// detected region becomes the same persistent preference as a manual choice.
    func detectRegion() async {
        regionDetectionState = .detecting

        do {
            let coordinate = try await LocationService.shared.requestCurrentLocationResult()
            guard !Task.isCancelled else { return }

            let coarseProfile = LocalityProfile.make(from: coordinate)
            guard let place = await LocationGeocoderService.shared.reverseGeocodeDetailed(
                coarseProfile.coordinate
            ) else {
                guard !Task.isCancelled else { return }
                regionDetectionState = .unavailable
                return
            }
            guard !Task.isCancelled else { return }

            guard let region = CatalogRegion.matching(
                countryCode: place.countryCode,
                administrativeArea: place.administrativeArea
            ) else {
                regionCoverage = .notCovered(placeName: place.displayName)
                regionDetectionState = .unsupported(placeName: place.displayName)
                return
            }

            regionCoverage = .covered(region)
            regionDetectionState = .detected(region)
            await selectRegion(.region(region))
        } catch let error as LocationRequestError {
            guard !Task.isCancelled else { return }
            switch error {
            case .permissionDenied:
                regionDetectionState = .permissionDenied
            case .servicesDisabled:
                regionDetectionState = .servicesDisabled
            case .unavailable:
                regionDetectionState = .unavailable
            }
        } catch {
            guard !Task.isCancelled else { return }
            regionDetectionState = .unavailable
        }
    }

    // MARK: - Locale-aware Catalog Derived Views

    /// Whether we have a locality + ranked items to drive the ecology-led sections.
    var hasLocalCatalog: Bool {
        localityProfile != nil && !localCatalogItems.isEmpty
    }

    /// Display name of the region currently driving Explore (e.g. "Hawai‘i").
    var localeRegionName: String? {
        localityProfile?.displayRegion
    }

    /// Catalog entries strongly reported in the region — the lead section.
    var commonlyReportedItems: [LocalCatalogItem] {
        localCatalogItems
            .filter { $0.explanationCodes.contains(.commonlyReported) }
            .prefix(12)
            .map { $0 }
    }

    /// The longer tail — reported in the region but less frequently, excluding
    /// anything already surfaced in the lead or seasonal sections.
    var moreToLookForItems: [LocalCatalogItem] {
        let shownIDs = Set(commonlyReportedItems.map { $0.id })
            .union(activeThisMonthItems.map { $0.id })
        return localCatalogItems
            .filter { !shownIDs.contains($0.id) }
            .prefix(12)
            .map { $0 }
    }

    /// Items whose seasonal affinity peaks around the current month — the
    /// "Active in {Month}" section. Empty until catalog plants carry
    /// `monthlyAffinity` data, so the section hides itself gracefully.
    var activeThisMonthItems: [LocalCatalogItem] {
        localCatalogItems
            .filter { item in
                item.explanationCodes.contains { code in
                    if case .seasonalPeak = code { return true } else { return false }
                }
            }
            .prefix(12)
            .map { $0 }
    }

    /// Standalone name of the current month for the seasonal section title.
    var currentMonthName: String? {
        localityProfile.map { LocalRankingService.monthName($0.currentMonth) }
    }

    /// Human-readable "Updated 2 days ago" string for the freshness pill.
    var catalogFreshnessLabel: String? {
        guard let date = catalogFreshnessDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Updated \(formatter.localizedString(for: date, relativeTo: .now))"
    }

    // MARK: - Computed Collections

    var allEncounters: [Encounter] {
        plants.flatMap { $0.encounters ?? [] }
            .sorted { $0.date > $1.date }
    }

    var recentlyEncountered: [Plant] {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return plants.filter { plant in
            (plant.encounters ?? []).contains { $0.date >= sevenDaysAgo }
        }
        .sorted { ($0.mostRecentEncounter?.date ?? .distantPast) > ($1.mostRecentEncounter?.date ?? .distantPast) }
    }

    var lowConfidencePlants: [Plant] {
        plants.filter { $0.averageConfidence < 0.7 }
            .sorted { $0.averageConfidence < $1.averageConfidence }
    }

    var winterFinds: [Plant] {
        plants.filter { plant in
            (plant.encounters ?? []).contains { encounter in
                let month = Calendar.current.component(.month, from: encounter.date)
                return month == 12 || month == 1 || month == 2
            }
        }
    }

    // MARK: - Search & Filter

    func searchPlants(_ query: String) -> [Plant] {
        guard !query.isEmpty else { return plants }

        let lowercasedQuery = query.lowercased()
        return plants.filter {
            $0.commonName.lowercased().contains(lowercasedQuery) ||
            $0.scientificName.lowercased().contains(lowercasedQuery) ||
            $0.family.lowercased().contains(lowercasedQuery)
        }
    }

    func searchCatalog(_ query: String) -> [CatalogPlant] {
        guard !query.isEmpty else { return catalogPlants }

        let lowercasedQuery = query.lowercased()
        return catalogPlants.filter {
            $0.commonName.lowercased().contains(lowercasedQuery) ||
            $0.scientificName.lowercased().contains(lowercasedQuery) ||
            $0.family.lowercased().contains(lowercasedQuery)
        }
    }

    func plants(inFamily family: String) -> [Plant] {
        guard !family.isEmpty && family != "All" else { return plants }
        return plants.filter { $0.family == family }
    }

    var uniqueFamilies: [String] {
        Array(Set(plants.map { $0.family })).sorted()
    }

    // MARK: - Custom Illustrations

    var plantsWithCustomIllustrations: [Plant] {
        plants.filter { $0.customIllustrationFileName?.isEmpty == false }
    }

    func removeCustomIllustration(from plant: Plant) async {
        guard let filename = plant.customIllustrationFileName else { return }
        do {
            try await PlantIllustrationStorageService.shared.deleteIllustration(filename: filename)
        } catch {
            print("Failed to delete illustration: \(error)")
        }
        plant.customIllustrationFileName = nil
        save()
        refreshTrigger += 1
    }

    // MARK: - Recent Locations

    /// Get unique recent locations from encounters, sorted by most recent use
    var recentLocations: [SelectedLocation] {
        var seenNames = Set<String>()
        var locations: [SelectedLocation] = []

        // Get all encounters sorted by date (most recent first)
        let sortedEncounters = allEncounters.sorted { $0.date > $1.date }

        for encounter in sortedEncounters {
            guard let location = SelectedLocation.from(encounter: encounter) else { continue }

            // Deduplicate by name (case-insensitive)
            let normalizedName = location.name.lowercased()
            if !seenNames.contains(normalizedName) {
                seenNames.insert(normalizedName)
                locations.append(location)
            }

            // Limit to 10 recent locations
            if locations.count >= 10 { break }
        }

        return locations
    }

    /// Check if any encounters have location data (for showing map button)
    var hasLocationsWithCoordinates: Bool {
        allEncounters.contains { $0.coordinates != nil }
    }

    /// Get locations with coordinates grouped for map display
    var locationsWithCoordinates: [LocationCluster] {
        var clusters: [String: LocationCluster] = [:]

        for plant in plants {
            for encounter in plant.encounters ?? [] {
                guard let coordinate = encounter.coordinates,
                      let locationName = encounter.displayLocationName else { continue }

                let key = locationName.lowercased()
                if var cluster = clusters[key] {
                    if !cluster.plantIds.contains(plant.id) {
                        cluster.plantIds.insert(plant.id)
                        cluster.plants.append(plant)
                    }
                    clusters[key] = cluster
                } else {
                    clusters[key] = LocationCluster(
                        name: locationName,
                        coordinate: coordinate,
                        category: LocationCategory.infer(from: locationName),
                        plants: [plant],
                        plantIds: [plant.id]
                    )
                }
            }
        }

        return Array(clusters.values).sorted { $0.plants.count > $1.plants.count }
    }
}

// MARK: - Location Cluster Model

struct LocationCluster: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: LocationCategory
    var plants: [Plant]
    var plantIds: Set<UUID>

    var plantCount: Int { plants.count }

    static func == (lhs: LocationCluster, rhs: LocationCluster) -> Bool {
        lhs.id == rhs.id
    }
}
