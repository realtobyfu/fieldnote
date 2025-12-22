//
//  AppStore.swift
//  Fieldnote
//
//  Centralized app state with mock data
//

import Foundation
import SwiftUI

@MainActor
@Observable
class AppStore {
    var plants: [Plant] = []
    let catalogPlants: [CatalogPlant] = CatalogPlant.catalog

    init() {
        loadMockData()
    }

    // MARK: - Data Loading

    private func loadMockData() {
        plants = Plant.mockPlants
    }

    // MARK: - Catalog & Discovery

    /// Check if a catalog plant has been discovered by the user
    func isDiscovered(_ catalogPlant: CatalogPlant) -> Bool {
        plants.contains { $0.commonName.lowercased() == catalogPlant.commonName.lowercased() }
    }

    /// Get all undiscovered plants from the catalog
    var undiscoveredPlants: [CatalogPlant] {
        catalogPlants.filter { !isDiscovered($0) }
    }

    /// Get all discovered plants from the catalog
    var discoveredCatalogPlants: [CatalogPlant] {
        catalogPlants.filter { isDiscovered($0) }
    }

    // MARK: - Location Grouping

    /// Get all unique location names from encounters
    var uniqueLocations: [String] {
        let locations = plants.flatMap { plant in
            plant.encounters.compactMap { $0.locationName }
        }
        return Array(Set(locations)).sorted()
    }

    /// Group plants by their encounter locations (discovered only)
    var plantsByLocation: [(location: String, plants: [Plant])] {
        var locationMap: [String: Set<UUID>] = [:]

        for plant in plants {
            for encounter in plant.encounters {
                if let location = encounter.locationName {
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

    /// Get undiscovered catalog plants that match a habitat keyword
    func undiscoveredPlants(forHabitat habitat: String) -> [CatalogPlant] {
        let lowercasedHabitat = habitat.lowercased()
        return undiscoveredPlants.filter { plant in
            // Match habitat directly or infer from location name
            plant.habitat.lowercased().contains(lowercasedHabitat) ||
            habitatKeywords(for: lowercasedHabitat).contains { keyword in
                plant.habitat.lowercased().contains(keyword)
            }
        }
    }

    /// Map location names to likely habitat keywords
    private func habitatKeywords(for location: String) -> [String] {
        let location = location.lowercased()

        // Park-related locations
        if location.contains("park") || location.contains("garden") || location.contains("botanical") {
            return ["urban", "gardens", "meadows", "forests"]
        }

        // Forest/woodland locations
        if location.contains("forest") || location.contains("wood") || location.contains("trail") {
            return ["forests", "woodlands"]
        }

        // Wetland locations
        if location.contains("lake") || location.contains("pond") || location.contains("creek") ||
           location.contains("river") || location.contains("marsh") || location.contains("wetland") {
            return ["wetlands", "streams"]
        }

        // Meadow/field locations
        if location.contains("meadow") || location.contains("field") || location.contains("prairie") {
            return ["meadows", "grasslands"]
        }

        // Urban locations
        if location.contains("street") || location.contains("yard") || location.contains("campus") ||
           location.contains("neighborhood") || location.contains("downtown") {
            return ["urban", "gardens", "disturbed"]
        }

        // Default: return common habitats
        return ["meadows", "forests", "urban"]
    }

    /// Get mixed location data with both discovered and undiscovered plants
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

    /// Add a new plant to the store
    func addPlant(_ plant: Plant) {
        plants.append(plant)
    }

    /// Delete a plant from the store
    func deletePlant(_ plant: Plant) {
        plants.removeAll { $0.id == plant.id }
    }

    /// Update an existing plant
    func updatePlant(_ plant: Plant) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[index] = plant
        }
    }

    /// Find plant by ID
    func plant(withId id: UUID) -> Plant? {
        plants.first { $0.id == id }
    }

    // MARK: - Encounter Operations

    /// Add an encounter to an existing plant
    func addEncounter(_ encounter: Encounter, to plantId: UUID) {
        if let index = plants.firstIndex(where: { $0.id == plantId }) {
            plants[index].encounters.append(encounter)
        }
    }

    /// Delete an encounter from a plant
    func deleteEncounter(_ encounter: Encounter, from plantId: UUID) {
        if let plantIndex = plants.firstIndex(where: { $0.id == plantId }) {
            plants[plantIndex].encounters.removeAll { $0.id == encounter.id }
        }
    }

    // MARK: - Computed Collections

    /// All encounters across all plants, sorted by date (most recent first)
    var allEncounters: [Encounter] {
        plants.flatMap { $0.encounters }
            .sorted { $0.date > $1.date }
    }

    /// Recently encountered plants (last 7 days)
    var recentlyEncountered: [Plant] {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return plants.filter { plant in
            plant.encounters.contains { $0.date >= sevenDaysAgo }
        }
        .sorted { ($0.mostRecentEncounter?.date ?? .distantPast) > ($1.mostRecentEncounter?.date ?? .distantPast) }
    }

    /// Plants with low confidence (average < 0.7)
    var lowConfidencePlants: [Plant] {
        plants.filter { $0.averageConfidence < 0.7 }
            .sorted { $0.averageConfidence < $1.averageConfidence }
    }

    /// Plants with winter encounters (Dec, Jan, Feb)
    var winterFinds: [Plant] {
        plants.filter { plant in
            plant.encounters.contains { encounter in
                let month = Calendar.current.component(.month, from: encounter.date)
                return month == 12 || month == 1 || month == 2
            }
        }
    }

    // MARK: - Search & Filter

    /// Search plants by common name, scientific name, or family
    func searchPlants(_ query: String) -> [Plant] {
        guard !query.isEmpty else { return plants }

        let lowercasedQuery = query.lowercased()
        return plants.filter {
            $0.commonName.lowercased().contains(lowercasedQuery) ||
            $0.scientificName.lowercased().contains(lowercasedQuery) ||
            $0.family.lowercased().contains(lowercasedQuery)
        }
    }

    /// Filter plants by family
    func plants(inFamily family: String) -> [Plant] {
        guard !family.isEmpty && family != "All" else { return plants }
        return plants.filter { $0.family == family }
    }

    /// Get unique plant families for filtering
    var uniqueFamilies: [String] {
        Array(Set(plants.map { $0.family })).sorted()
    }
}
