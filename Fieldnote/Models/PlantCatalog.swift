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
    let nativeRange: String  // e.g., "Native to eastern North America"
    let summary: String
    let traits: [String]
    let defaultPlaceholder: String  // SF Symbol name

    init(
        id: UUID = UUID(),
        commonName: String,
        scientificName: String,
        family: String,
        habitat: String,
        nativeRange: String = "",
        summary: String = "",
        traits: [String],
        defaultPlaceholder: String = "leaf.fill"
    ) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.family = family
        self.habitat = habitat
        self.nativeRange = nativeRange
        self.summary = summary
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

// MARK: - Conversion

extension CatalogPlant {
    var asPlant: Plant {
        Plant(
            id: id,
            commonName: commonName,
            scientificName: scientificName,
            family: family,
            summary: shortDescription,
            traits: traits,
            encounters: []
        )
    }
}

extension CatalogPlant {
    var shortDescription: String {
        if !summary.isEmpty {
            return summary
        }

        if !traits.isEmpty {
            return traits.prefix(2).joined(separator: " · ")
        }

        return "Habitat: \(habitat)"
    }
}

// MARK: - Identification Matching

extension CatalogPlant {
    static func match(for result: PlantIdentificationResult, in catalog: [CatalogPlant]) -> CatalogPlant? {
        let common = normalize(result.commonName)
        let scientific = normalize(result.scientificName)

        if !common.isEmpty,
           let match = catalog.first(where: { normalize($0.commonName) == common }) {
            return match
        }

        if !scientific.isEmpty,
           let match = catalog.first(where: { normalize($0.scientificName) == scientific }) {
            return match
        }

        return nil
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "'", with: "")
    }
}
