//
//  Plant.swift
//  Fieldnote
//
//  Core plant model with encounters
//

import SwiftData
import Foundation

@Model
final class Plant: Identifiable, Hashable {
    @Attribute(.unique) var id: UUID
    var commonName: String
    var scientificName: String
    var family: String
    var summary: String
    var traits: [String]
    var habitat: String?
    var nativeRange: String?
    var customIllustrationFileName: String?

    @Relationship(deleteRule: .cascade, inverse: \Encounter.plant)
    var encounters: [Encounter] = []

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        commonName: String,
        scientificName: String,
        family: String,
        summary: String = "",
        traits: [String] = [],
        habitat: String? = nil,
        nativeRange: String? = nil,
        encounters: [Encounter] = [],
        customIllustrationFileName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.family = family
        self.summary = summary
        self.traits = traits
        self.habitat = habitat
        self.nativeRange = nativeRange
        self.encounters = encounters
        self.customIllustrationFileName = customIllustrationFileName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        for encounter in encounters {
            encounter.plant = self
        }
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

    /// Short description for display
    var shortDescription: String {
        if !summary.isEmpty {
            return summary
        }

        if !traits.isEmpty {
            return traits.prefix(2).joined(separator: " · ")
        }

        return "Family: \(family)"
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
