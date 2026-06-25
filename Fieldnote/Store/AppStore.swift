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
}

@MainActor
@Observable
class AppStore {
    private var modelContext: ModelContext

    // Trigger to force SwiftUI to re-evaluate computed properties
    // @Observable only tracks direct property assignments, not computed property changes
    private(set) var refreshTrigger: Int = 0

    // Navigation state
    var selectedTab: AppTab = .journal

    // Last save error for UI feedback
    var lastError: Error?

    // Static catalog (not persisted, bundled with app)
    let catalogPlants: [CatalogPlant] = CatalogPlant.catalog

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

    /// Which place Explore ranks for. Changing this is a view preference and is
    /// deliberately *not* persisted onto any observation.
    var selectedRegionOverride: ExploreRegion = .currentLocation

    /// Radius (km) used for the nearby query — kept in one place for copy + query.
    let localCatalogRadiusKm = 25

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
        guard !isRefreshingLocalCatalog else { return }
        isRefreshingLocalCatalog = true
        defer { isRefreshingLocalCatalog = false }

        // 1. Build a locality profile for the chosen region.
        guard let profile = await resolveLocalityProfile() else {
            // No location available yet (permission not granted, no chosen region).
            // Leave any existing state in place.
            return
        }

        // 2. Reuse a fresh cache entry, else fetch from iNaturalist and store.
        let counts: [INatSpeciesCount]
        let fetchedAt: Date
        if let cached = await LocalCatalogCache.shared.freshEntry(for: profile.cacheKey) {
            counts = cached.counts
            fetchedAt = cached.fetchedAt
        } else {
            do {
                let fetched = try await fetchSpeciesCounts(for: profile)
                await LocalCatalogCache.shared.store(fetched, for: profile.cacheKey)
                counts = fetched
                fetchedAt = .now
            } catch {
                // Network/rate-limit failure: fall back to a stale cache if we
                // have one, otherwise keep existing state.
                if let stale = await LocalCatalogCache.shared.entry(for: profile.cacheKey) {
                    counts = stale.counts
                    fetchedAt = stale.fetchedAt
                } else {
                    print("refreshLocalCatalog: fetch failed and no cache: \(error)")
                    return
                }
            }
        }

        // 3. Rank the bundled catalog against the counts (pure, synchronous).
        let items = LocalRankingService().rank(
            catalog: catalogPlants,
            counts: counts,
            month: profile.currentMonth
        )

        // 4. Publish. Direct assignment is fine — these are stored properties.
        localityProfile = profile
        localCatalogItems = items
        catalogFreshnessDate = fetchedAt
    }

    /// Builds a `LocalityProfile` for the chosen Explore region. For
    /// `.currentLocation` we ask `LocationService` (one-shot, may return nil when
    /// permission isn't granted yet); for `.region` we use its iNaturalist places.
    private func resolveLocalityProfile() async -> LocalityProfile? {
        switch selectedRegionOverride {
        case .currentLocation:
            guard let coordinate = await LocationService.shared.requestCurrentLocation() else {
                return nil
            }
            // Reverse-geocode the coarse cell center (not the precise fix) for a
            // friendly label; geocoding failure is non-fatal.
            let profile = LocalityProfile.make(from: coordinate)
            let name = await LocationGeocoderService.shared.reverseGeocode(profile.coordinate)
            return LocalityProfile.make(from: coordinate, displayRegion: name)
        case .region(let region):
            return LocalityProfile.makeRegion(name: region.name, placeIDs: region.placeIDs)
        }
    }

    /// Fetches species counts for a profile: by place IDs for a named region,
    /// else by the coarse coordinate + radius for current location.
    private func fetchSpeciesCounts(for profile: LocalityProfile) async throws -> [INatSpeciesCount] {
        if let placeIDs = profile.placeIDs, !placeIDs.isEmpty {
            return try await INaturalistService.shared.speciesCounts(
                placeIDs: placeIDs,
                month: profile.currentMonth
            )
        }
        return try await INaturalistService.shared.speciesCounts(
            near: profile.coordinate,
            radiusKm: Double(localCatalogRadiusKm),
            month: profile.currentMonth
        )
    }

    /// Convenience for the region picker: switch region and refresh.
    func selectRegion(_ region: ExploreRegion) async {
        selectedRegionOverride = region
        // Clear current items so the UI shows a loading state for the new region.
        localCatalogItems = []
        await refreshLocalCatalog()
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

    /// The longer tail — reported in the region but less frequently.
    var moreToLookForItems: [LocalCatalogItem] {
        let leadIDs = Set(commonlyReportedItems.map { $0.id })
        return localCatalogItems
            .filter { !leadIDs.contains($0.id) }
            .prefix(12)
            .map { $0 }
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
