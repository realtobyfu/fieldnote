//
//  LocalCatalogCache.swift
//  Fieldnote
//
//  On-device cache of iNaturalist species counts, keyed by coarse cell + month.
//  Lets us respect iNaturalist's rate limits by fetching only when the cell or
//  month changes. See LocaleAwareCatalogImplementationPlan.md.
//

import Foundation

/// A cached species-counts response with the freshness metadata the UI shows.
struct CachedSpeciesCounts: Codable {
    let cacheKey: String
    let counts: [INatSpeciesCount]
    let fetchedAt: Date
}

actor LocalCatalogCache {
    static let shared = LocalCatalogCache()

    private let fileManager = FileManager.default

    /// How long a cached response stays fresh before we refetch.
    private let maxAge: TimeInterval = 60 * 60 * 24 * 7  // 7 days

    private var directory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("LocalCatalog", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func fileURL(for cacheKey: String) -> URL {
        // Sanitize the key (it contains "," and "@") into a safe filename.
        let safe = cacheKey
            .replacingOccurrences(of: ",", with: "_")
            .replacingOccurrences(of: "@", with: "-m")
        return directory.appendingPathComponent("\(safe).json")
    }

    // MARK: - Read

    /// Returns the cached entry for a key, regardless of freshness.
    func entry(for cacheKey: String) -> CachedSpeciesCounts? {
        let url = fileURL(for: cacheKey)
        guard let data = try? Data(contentsOf: url),
              let entry = try? JSONDecoder.iso.decode(CachedSpeciesCounts.self, from: data) else {
            return nil
        }
        return entry
    }

    /// Returns the cached entry only if it is still within `maxAge`.
    func freshEntry(for cacheKey: String, now: Date = .now) -> CachedSpeciesCounts? {
        guard let entry = entry(for: cacheKey) else { return nil }
        return now.timeIntervalSince(entry.fetchedAt) <= maxAge ? entry : nil
    }

    // MARK: - Write

    func store(_ counts: [INatSpeciesCount], for cacheKey: String, fetchedAt: Date = .now) {
        let entry = CachedSpeciesCounts(cacheKey: cacheKey, counts: counts, fetchedAt: fetchedAt)
        guard let data = try? JSONEncoder.iso.encode(entry) else { return }
        try? data.write(to: fileURL(for: cacheKey))
    }

    // MARK: - Region Packs (2B)

    /// Region packs are cached under their own key namespace so they don't
    /// collide with the raw species-count entries. The pack carries its own
    /// `version` + `generatedAt`, so freshness lives in the pack, not here.
    private func packCacheKey(for regionID: String) -> String { "pack-\(regionID)" }

    /// The last cached pack for a region, regardless of age. Used both to serve
    /// offline and to supply the `If-None-Match` version on the next fetch.
    func regionPack(for regionID: String) -> RegionPack? {
        let url = fileURL(for: packCacheKey(for: regionID))
        guard let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder.iso.decode(RegionPack.self, from: data) else {
            return nil
        }
        return pack
    }

    func storeRegionPack(_ pack: RegionPack) {
        guard let data = try? JSONEncoder.iso.encode(pack) else { return }
        try? data.write(to: fileURL(for: packCacheKey(for: pack.regionID)))
    }
}

private extension JSONDecoder {
    static let iso: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

private extension JSONEncoder {
    static let iso: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}
