//
//  AppStore.swift
//  Fieldnote
//
//  Centralized app state with SwiftData persistence
//

import Foundation
import SwiftUI
import SwiftData

enum Tab: Int {
    case library
    case capture
    case explore
    case settings
}

@MainActor
@Observable
class AppStore {
    private var modelContext: ModelContext

    // Trigger to force SwiftUI to re-evaluate computed properties
    // @Observable only tracks direct property assignments, not computed property changes
    private(set) var refreshTrigger: Int = 0

    // Navigation state
    var selectedTab: Tab = .library

    // Last save error for UI feedback
    var lastError: Error?

    // Static catalog (not persisted, bundled with app)
    let catalogPlants: [CatalogPlant] = CatalogPlant.catalog

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

    // MARK: - Location Grouping

    var uniqueLocations: [String] {
        let locations = plants.flatMap { plant in
            plant.encounters.compactMap { $0.displayLocationName }
        }
        return Array(Set(locations)).sorted()
    }

    var plantsByLocation: [(location: String, plants: [Plant])] {
        var locationMap: [String: Set<UUID>] = [:]

        for plant in plants {
            for encounter in plant.encounters {
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
        plant.encounters.append(encounter)
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

    // MARK: - Computed Collections

    var allEncounters: [Encounter] {
        plants.flatMap { $0.encounters }
            .sorted { $0.date > $1.date }
    }

    var recentlyEncountered: [Plant] {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return plants.filter { plant in
            plant.encounters.contains { $0.date >= sevenDaysAgo }
        }
        .sorted { ($0.mostRecentEncounter?.date ?? .distantPast) > ($1.mostRecentEncounter?.date ?? .distantPast) }
    }

    var lowConfidencePlants: [Plant] {
        plants.filter { $0.averageConfidence < 0.7 }
            .sorted { $0.averageConfidence < $1.averageConfidence }
    }

    var winterFinds: [Plant] {
        plants.filter { plant in
            plant.encounters.contains { encounter in
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
        await PlantIllustrationStorageService.shared.deleteIllustration(filename: filename)
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
}
