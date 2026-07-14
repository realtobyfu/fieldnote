//
//  BundledRegionPacks.swift
//  Fieldnote
//
//  Point-in-time region packs shipped in the app bundle (Resources/RegionPacks/),
//  generated from iNaturalist + GBIF (see backend/fixtures). They are the final
//  offline fallback for a named region: when the backend is unconfigured or
//  unreachable and there's no cached pack, the region catalog still expands past
//  the bundled 50 instead of silently collapsing back to it. A live pack, when
//  available, always supersedes these. See RegionalizedCatalogPlan.md.
//

import Foundation

enum BundledRegionPacks {
    private static let regionIDs = [
        "california",
        "pacific-northwest",
        "desert-southwest",
        "rocky-mountains",
        "texas",
        "florida",
        "northeast",
        "hawaii"
    ]

    private static let completeSummariesByScientificName: [String: String] = {
        regionIDs.reduce(into: [:]) { summaries, regionID in
            guard let pack = pack(for: regionID) else { return }
            for taxon in pack.taxa {
                guard let summary = taxon.summary, !summary.isEmpty else { continue }
                summaries[CatalogPlant.scientificNameKey(taxon.acceptedScientificName)] = summary
            }
        }
    }()

    /// Loads the shipped pack for a region ID, or `nil` if none is bundled.
    static func pack(for regionID: String) -> RegionPack? {
        guard let url = Bundle.main.url(
            forResource: regionID,
            withExtension: "json",
            subdirectory: "RegionPacks"
        ) ?? Bundle.main.url(forResource: regionID, withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.regionPack.decode(RegionPack.self, from: data)
    }

    /// Replaces only legacy, pipeline-truncated prose. User-authored summaries
    /// and already-complete catalog text are returned unchanged by the caller.
    static func completeSummary(forScientificName scientificName: String) -> String? {
        completeSummariesByScientificName[CatalogPlant.scientificNameKey(scientificName)]
    }
}
