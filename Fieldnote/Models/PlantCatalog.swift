//
//  PlantCatalog.swift
//  Fieldnote
//
//  Predefined plant catalog that users can discover
//

import Foundation

struct CatalogPlant: Identifiable, Codable, Hashable {
    let id: UUID
    let commonName: String
    let scientificName: String
    let family: String
    let habitat: String  // e.g., "forests", "meadows", "urban", "wetlands"
    let traits: [String]
    let defaultPlaceholder: String  // SF Symbol name

    init(
        id: UUID = UUID(),
        commonName: String,
        scientificName: String,
        family: String,
        habitat: String,
        traits: [String],
        defaultPlaceholder: String = "leaf.fill"
    ) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.family = family
        self.habitat = habitat
        self.traits = traits
        self.defaultPlaceholder = defaultPlaceholder
    }
}

// MARK: - Hashable

extension CatalogPlant {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CatalogPlant, rhs: CatalogPlant) -> Bool {
        lhs.id == rhs.id
    }
}
