//
//  RegionPack.swift
//  Fieldnote
//
//  A versioned per-region manifest of ecological inputs, precomputed by the
//  Fieldnote backend (Milestone 2, 2B): iNaturalist counts + GBIF-normalized
//  names + monthly affinity. Ranking stays on-device — the pack carries the
//  inputs, `LocalRankingService` does the ranking. See Docs/BackendM2Spec.md.
//

import Foundation

/// One taxon's ecological inputs inside a region pack.
struct RegionPackTaxon: Codable, Hashable {
    /// Canonical GBIF identity (used by 2C); may be null when GBIF had no match.
    let gbifTaxonKey: Int?
    /// iNaturalist taxon ID — the join key into the on-device catalog today.
    let inaturalistTaxonID: Int
    /// GBIF-accepted scientific name.
    let acceptedScientificName: String
    /// Preferred common name, when available.
    let commonName: String?
    /// Research-grade observation count reported in the region.
    let nearbyObservationCount: Int
    /// Normalized month-of-year histogram (12 entries, 0...1). `nil` when the
    /// per-taxon histogram was unavailable — treated as neutral by the ranker.
    let monthlyAffinity: [Double]?

    // MARK: 2C display metadata (all optional; absent on 2B-era packs)

    /// Family name (from GBIF), for the display line + placeholder icon.
    let family: String?
    /// iNaturalist iconic taxon name (coarse for plants).
    let iconicTaxon: String?
    /// Short prose summary (iNaturalist wikipedia_summary, HTML-stripped).
    let summary: String?
    let wikipediaURL: String?
    /// Medium photo URL — only present when the license permits reuse.
    let defaultPhotoURL: String?
    let defaultPhotoAttribution: String?
    let defaultPhotoLicenseCode: String?
    /// Place-scoped establishment ("native" | "introduced" | "endemic").
    let establishmentMeans: String?

    // Optional keys tolerate 2B packs that predate these fields.
    enum CodingKeys: String, CodingKey {
        case gbifTaxonKey, inaturalistTaxonID, acceptedScientificName, commonName
        case nearbyObservationCount, monthlyAffinity
        case family, iconicTaxon, summary, wikipediaURL
        case defaultPhotoURL, defaultPhotoAttribution, defaultPhotoLicenseCode
        case establishmentMeans
    }

    init(
        gbifTaxonKey: Int?,
        inaturalistTaxonID: Int,
        acceptedScientificName: String,
        commonName: String?,
        nearbyObservationCount: Int,
        monthlyAffinity: [Double]?,
        family: String? = nil,
        iconicTaxon: String? = nil,
        summary: String? = nil,
        wikipediaURL: String? = nil,
        defaultPhotoURL: String? = nil,
        defaultPhotoAttribution: String? = nil,
        defaultPhotoLicenseCode: String? = nil,
        establishmentMeans: String? = nil
    ) {
        self.gbifTaxonKey = gbifTaxonKey
        self.inaturalistTaxonID = inaturalistTaxonID
        self.acceptedScientificName = acceptedScientificName
        self.commonName = commonName
        self.nearbyObservationCount = nearbyObservationCount
        self.monthlyAffinity = monthlyAffinity
        self.family = family
        self.iconicTaxon = iconicTaxon
        self.summary = summary
        self.wikipediaURL = wikipediaURL
        self.defaultPhotoURL = defaultPhotoURL
        self.defaultPhotoAttribution = defaultPhotoAttribution
        self.defaultPhotoLicenseCode = defaultPhotoLicenseCode
        self.establishmentMeans = establishmentMeans
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gbifTaxonKey = try c.decodeIfPresent(Int.self, forKey: .gbifTaxonKey)
        inaturalistTaxonID = try c.decode(Int.self, forKey: .inaturalistTaxonID)
        acceptedScientificName = try c.decode(String.self, forKey: .acceptedScientificName)
        commonName = try c.decodeIfPresent(String.self, forKey: .commonName)
        nearbyObservationCount = try c.decode(Int.self, forKey: .nearbyObservationCount)
        monthlyAffinity = try c.decodeIfPresent([Double].self, forKey: .monthlyAffinity)
        family = try c.decodeIfPresent(String.self, forKey: .family)
        iconicTaxon = try c.decodeIfPresent(String.self, forKey: .iconicTaxon)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        wikipediaURL = try c.decodeIfPresent(String.self, forKey: .wikipediaURL)
        defaultPhotoURL = try c.decodeIfPresent(String.self, forKey: .defaultPhotoURL)
        defaultPhotoAttribution = try c.decodeIfPresent(String.self, forKey: .defaultPhotoAttribution)
        defaultPhotoLicenseCode = try c.decodeIfPresent(String.self, forKey: .defaultPhotoLicenseCode)
        establishmentMeans = try c.decodeIfPresent(String.self, forKey: .establishmentMeans)
    }
}

/// The full manifest for one region, as served at `/v1/regions/{regionID}`.
struct RegionPack: Codable, Hashable {
    let regionID: String
    /// Monotonic version — bumped each pipeline run, used for `If-None-Match`.
    let version: Int
    let generatedAt: Date
    let placeIDs: [Int]
    let source: String
    let taxa: [RegionPackTaxon]
}

extension RegionPack {
    /// Adapts pack taxa to the `INatSpeciesCount` shape the existing Stage-1
    /// ranker consumes, so the tested ranking path is reused unchanged. Taxa not
    /// in the bundled catalog simply don't join (surfacing them as first-class
    /// records is deferred to 2C).
    var speciesCounts: [INatSpeciesCount] {
        taxa.map { taxon in
            INatSpeciesCount(
                taxonID: taxon.inaturalistTaxonID,
                scientificName: taxon.acceptedScientificName,
                commonName: taxon.commonName,
                count: taxon.nearbyObservationCount,
                defaultPhotoURL: nil,
                defaultPhotoLicense: nil
            )
        }
    }

    /// Returns `catalog` with each plant's `monthlyAffinity` refreshed from the
    /// matching pack taxon, when the pack has affinity for it. The pack is the
    /// server-refreshed source of truth for seasonality; bundled affinity is the
    /// fallback for taxa the pack didn't carry. Join is by iNaturalist ID, then
    /// normalized scientific name — the same rule the ranker uses.
    func catalogWithFreshAffinity(_ catalog: [CatalogPlant]) -> [CatalogPlant] {
        let affinityByTaxonID: [Int: [Double]] = taxa.reduce(into: [:]) { acc, t in
            if let affinity = t.monthlyAffinity, affinity.count == 12 {
                acc[t.inaturalistTaxonID] = affinity
            }
        }
        let affinityByNameKey: [String: [Double]] = taxa.reduce(into: [:]) { acc, t in
            if let affinity = t.monthlyAffinity, affinity.count == 12 {
                acc[CatalogPlant.scientificNameKey(t.acceptedScientificName)] = affinity
            }
        }

        return catalog.map { plant in
            let fresh = plant.inaturalistTaxonID.flatMap { affinityByTaxonID[$0] }
                ?? affinityByNameKey[plant.scientificNameKey]
            guard let fresh else { return plant }
            return plant.withMonthlyAffinity(fresh)
        }
    }
}

extension CatalogPlant {
    /// A copy with `monthlyAffinity` replaced. Used to fold server-refreshed
    /// seasonality from a region pack into the bundled catalog before ranking.
    func withMonthlyAffinity(_ affinity: [Double]) -> CatalogPlant {
        CatalogPlant(
            id: id,
            commonName: commonName,
            scientificName: scientificName,
            family: family,
            habitat: habitat,
            nativeRange: nativeRange,
            summary: summary,
            traits: traits,
            defaultPlaceholder: defaultPlaceholder,
            gbifTaxonKey: gbifTaxonKey,
            inaturalistTaxonID: inaturalistTaxonID,
            monthlyAffinity: affinity,
            source: source,
            photoURL: photoURL,
            photoAttribution: photoAttribution
        )
    }
}

// MARK: - Region catalog projection (2C)

extension RegionPackTaxon {
    /// Deterministic UUID derived from the iNaturalist taxon ID, so a pack-only
    /// record keeps a stable identity across refreshes and app launches (SwiftUI
    /// selection/diffing) without needing a server-assigned UUID.
    var stableID: UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012x", inaturalistTaxonID))
            ?? UUID()
    }

    /// Renders this pack taxon as a first-class `CatalogPlant`. Used only for taxa
    /// that aren't already in the bundled catalog; bundled records are authoritative.
    func asCatalogPlant() -> CatalogPlant {
        let displayName = (commonName?.isEmpty == false ? commonName! : acceptedScientificName)
        let native: String
        switch establishmentMeans {
        case "native", "endemic": native = "Native to this region"
        case "introduced": native = "Introduced to this region"
        default: native = ""
        }
        return CatalogPlant(
            id: stableID,
            commonName: displayName,
            scientificName: acceptedScientificName,
            family: family ?? "",
            habitat: "",
            nativeRange: native,
            summary: summary ?? "",
            traits: [],
            defaultPlaceholder: CatalogPlant.placeholderSymbol(forFamily: family),
            gbifTaxonKey: gbifTaxonKey,
            inaturalistTaxonID: inaturalistTaxonID,
            monthlyAffinity: monthlyAffinity,
            source: .regional,
            photoURL: defaultPhotoURL,
            photoAttribution: defaultPhotoAttribution
        )
    }
}

extension RegionPack {
    /// The region-scoped catalog: **the plants actually reported in this region**,
    /// ordered by observation count. Each pack taxon becomes a catalog record —
    /// reusing the richer hand-authored `bundled` entry (with pack-refreshed
    /// seasonality) when the taxon is one of them, otherwise a fresh regional
    /// record from the pack's enriched fields.
    ///
    /// Crucially, this is *pack-driven*: bundled plants that aren't reported in the
    /// region (e.g. White Pine in the desert) do **not** appear here. The bundled
    /// catalog stays the fallback for regions with no pack. Join/dedupe by
    /// iNaturalist ID, then normalized scientific-name key.
    func catalogPlants(mergedWith bundled: [CatalogPlant]) -> [CatalogPlant] {
        let bundledByTaxonID: [Int: CatalogPlant] = bundled.reduce(into: [:]) { acc, p in
            if let id = p.inaturalistTaxonID { acc[id] = p }
        }
        let bundledByNameKey: [String: CatalogPlant] = bundled.reduce(into: [:]) { acc, p in
            acc[p.scientificNameKey] = p
        }

        var seenTaxonIDs = Set<Int>()
        var seenNameKeys = Set<String>()
        var result: [CatalogPlant] = []

        for taxon in taxa.sorted(by: { $0.nearbyObservationCount > $1.nearbyObservationCount }) {
            let nameKey = CatalogPlant.scientificNameKey(taxon.acceptedScientificName)
            guard seenTaxonIDs.insert(taxon.inaturalistTaxonID).inserted,
                  seenNameKeys.insert(nameKey).inserted else { continue }

            if let bundledMatch = bundledByTaxonID[taxon.inaturalistTaxonID] ?? bundledByNameKey[nameKey] {
                // Reported here AND one of the bundled 50: keep the richer record,
                // refreshing its seasonality from the pack when available.
                if let affinity = taxon.monthlyAffinity, affinity.count == 12 {
                    result.append(bundledMatch.withMonthlyAffinity(affinity))
                } else {
                    result.append(bundledMatch)
                }
            } else {
                // A new plant this region reports that isn't in the bundled catalog.
                result.append(taxon.asCatalogPlant())
            }
        }

        return result
    }
}
