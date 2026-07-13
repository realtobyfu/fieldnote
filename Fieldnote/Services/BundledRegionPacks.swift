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
}
