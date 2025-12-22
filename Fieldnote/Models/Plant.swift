//
//  Plant.swift
//  Fieldnote
//
//  Core plant model with encounters
//

import Foundation

struct Plant: Identifiable, Codable, Hashable {
    let id: UUID
    let commonName: String
    let scientificName: String
    let family: String
    let traits: [String]
    var encounters: [Encounter]

    init(
        id: UUID = UUID(),
        commonName: String,
        scientificName: String,
        family: String,
        traits: [String] = [],
        encounters: [Encounter] = []
    ) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.family = family
        self.traits = traits
        self.encounters = encounters
    }

    // MARK: - Computed Properties

    /// Number of encounters for this plant
    var encounterCount: Int {
        encounters.count
    }

    /// Most recent encounter (by date)
    var mostRecentEncounter: Encounter? {
        encounters.max(by: { $0.date < $1.date })
    }

    /// Average confidence across all encounters (0.0...1.0)
    var averageConfidence: Double {
        guard !encounters.isEmpty else { return 0.0 }
        let sum = encounters.reduce(0.0) { $0 + $1.confidence }
        return sum / Double(encounters.count)
    }

    /// Placeholder for display (from most recent encounter)
    var displayPlaceholder: String {
        mostRecentEncounter?.photoPlaceholder ?? "leaf.fill"
    }

    /// Date of most recent encounter
    var lastSeenDate: Date? {
        mostRecentEncounter?.date
    }
}

// MARK: - Hashable Conformance

extension Plant {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Plant, rhs: Plant) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Encounter Hashable Conformance

extension Encounter: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Encounter, rhs: Encounter) -> Bool {
        lhs.id == rhs.id
    }
}
