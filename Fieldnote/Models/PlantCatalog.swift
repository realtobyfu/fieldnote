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

    // MARK: Locale-aware identity (optional; see LocaleAwareCatalogImplementationPlan.md)

    /// Canonical GBIF taxon key, when known. Stable across name changes.
    let gbifTaxonKey: Int?
    /// iNaturalist taxon ID, used to join against `observations/species_counts`.
    let inaturalistTaxonID: Int?
    /// Per-month seasonal affinity, 12 entries (Jan...Dec), normalized 0...1.
    /// `nil` when no seasonal data has been computed for this taxon yet.
    let monthlyAffinity: [Double]?

    init(
        id: UUID = UUID(),
        commonName: String,
        scientificName: String,
        family: String,
        habitat: String,
        nativeRange: String = "",
        summary: String = "",
        traits: [String],
        defaultPlaceholder: String = "leaf.fill",
        gbifTaxonKey: Int? = nil,
        inaturalistTaxonID: Int? = nil,
        monthlyAffinity: [Double]? = nil
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
        self.gbifTaxonKey = gbifTaxonKey
        self.inaturalistTaxonID = inaturalistTaxonID
        self.monthlyAffinity = monthlyAffinity
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
            summary: summary.isEmpty ? shortDescription : summary,
            traits: traits,
            habitat: habitat,
            nativeRange: nativeRange.isEmpty ? nil : nativeRange,
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

// MARK: - Locale Join

extension CatalogPlant {
    /// Normalized scientific name used to join external taxa (e.g. iNaturalist)
    /// to this catalog entry when no provider ID is present.
    var scientificNameKey: String {
        Self.scientificNameKey(scientificName)
    }

    /// Normalizes a scientific name to a join key: lowercased, trimmed, and
    /// reduced to genus + species so authorship and subspecies don't block a match.
    /// "Taraxacum officinale F.H.Wigg." -> "taraxacum officinale"
    static func scientificNameKey(_ value: String) -> String {
        let cleaned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "×", with: "")
        let words = cleaned.split(separator: " ").map(String.init)
        return words.prefix(2).joined(separator: " ")
    }

    /// Finds the catalog entry matching an external taxon, preferring the stable
    /// iNaturalist ID and falling back to the normalized scientific-name key.
    static func match(
        inaturalistTaxonID taxonID: Int?,
        scientificName: String,
        in catalog: [CatalogPlant]
    ) -> CatalogPlant? {
        if let taxonID,
           let byID = catalog.first(where: { $0.inaturalistTaxonID == taxonID }) {
            return byID
        }

        let key = scientificNameKey(scientificName)
        guard !key.isEmpty else { return nil }
        return catalog.first { $0.scientificNameKey == key }
    }
}
