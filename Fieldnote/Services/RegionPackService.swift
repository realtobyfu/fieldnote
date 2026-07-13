//
//  RegionPackService.swift
//  Fieldnote
//
//  Fetches versioned region packs from the Fieldnote backend (2B), using an
//  `If-None-Match` conditional request against the cached version so an
//  unchanged pack costs a cheap `304`. Offline-first: on any failure the caller
//  falls back to the last cached pack, then to the bundled catalog.
//  See Docs/BackendM2Spec.md.
//

import Foundation

enum RegionPackError: LocalizedError {
    case notConfigured
    case invalidRequest
    case networkError
    case notFound
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "The backend is not configured."
        case .invalidRequest: return "Could not build the region-pack request."
        case .networkError: return "Network error fetching the region pack."
        case .notFound: return "No pack is available for this region yet."
        case .decodingFailed: return "Unexpected region-pack response."
        }
    }
}

/// The outcome of a conditional pack fetch.
enum RegionPackFetchResult {
    /// The server had a newer pack; it has been cached.
    case updated(RegionPack)
    /// The cached pack is current (server returned `304`).
    case notModified(RegionPack)
}

actor RegionPackService {
    static let shared = RegionPackService()

    private let session: URLSession
    private let cache: LocalCatalogCache

    init(session: URLSession = .shared, cache: LocalCatalogCache = .shared) {
        self.session = session
        self.cache = cache
    }

    /// Fetches the pack for a region, reusing the cached copy when the server
    /// reports it is unchanged. Throws only when there is no usable pack at all
    /// (no cache and the network failed) — the caller handles fallback.
    func fetchPack(regionID: String) async throws -> RegionPackFetchResult {
        guard let base = BackendConfig.baseURL else { throw RegionPackError.notConfigured }
        guard let url = URL(string: "\(base.absoluteString)/v1/regions/\(regionID)") else {
            throw RegionPackError.invalidRequest
        }

        let cached = await cache.regionPack(for: regionID)

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("Fieldnote/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        if let cached {
            // The Worker tags packs as "v{version}"; match that for a 304.
            request.setValue("\"v\(cached.version)\"", forHTTPHeaderField: "If-None-Match")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw RegionPackError.networkError
        }

        guard let http = response as? HTTPURLResponse else {
            throw RegionPackError.networkError
        }

        switch http.statusCode {
        case 200:
            let pack: RegionPack
            do {
                pack = try JSONDecoder.regionPack.decode(RegionPack.self, from: data)
            } catch {
                throw RegionPackError.decodingFailed
            }
            await cache.storeRegionPack(pack)
            return .updated(pack)

        case 304:
            guard let cached else {
                // 304 with no cache should not happen (we only send If-None-Match
                // when we have one), but treat it as a miss rather than crash.
                throw RegionPackError.networkError
            }
            return .notModified(cached)

        case 404:
            throw RegionPackError.notFound

        default:
            throw RegionPackError.networkError
        }
    }
}

extension JSONDecoder {
    /// Decoder for backend region packs (ISO-8601 `generatedAt`).
    static let regionPack: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
