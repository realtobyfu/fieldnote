//
//  INaturalistService.swift
//  Fieldnote
//
//  iNaturalist API client for nearby + seasonal species counts.
//
//  Free and keyless. We send only a coarse cell (rounded coordinates) — never
//  precise encounter coordinates. See LocaleAwareCatalogImplementationPlan.md.
//

import Foundation
import CoreLocation

// MARK: - Domain Models

/// One taxon's "reported nearby" evidence from iNaturalist `species_counts`.
struct INatSpeciesCount: Codable, Hashable, Identifiable {
    /// iNaturalist taxon ID — the stable join key into the catalog.
    let taxonID: Int
    /// Accepted scientific name as iNaturalist reports it.
    let scientificName: String
    /// Preferred localized common name, when available.
    let commonName: String?
    /// Number of research-grade observations matching the query window.
    let count: Int
    /// Default photo URL, if iNaturalist provides one.
    let defaultPhotoURL: URL?
    /// License code for the default photo (e.g. "cc-by-nc"). Image reuse is a
    /// separate legal decision from occurrence evidence — store it, don't assume.
    let defaultPhotoLicense: String?

    var id: Int { taxonID }
}

/// One curated taxon photo from iNaturalist `taxa/{id}` (`taxon_photos`), kept
/// only when its license permits reuse. Attribution is iNaturalist's prebuilt
/// credit string, e.g. "(c) someone, some rights reserved (CC BY-NC)".
struct INatTaxonPhoto: Hashable, Identifiable {
    let photoID: Int
    /// Medium rendition — gallery thumbnails.
    let mediumURL: URL
    /// Large rendition — full-screen viewing. Falls back to `mediumURL` when absent.
    let largeURL: URL?
    let attribution: String?

    var id: Int { photoID }
}

// MARK: - Errors

enum INaturalistError: LocalizedError {
    case invalidRequest
    case networkError
    case rateLimited
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidRequest: return "Could not build the iNaturalist request"
        case .networkError: return "Network error contacting iNaturalist"
        case .rateLimited: return "iNaturalist rate limit reached — try again later"
        case .decodingFailed: return "Unexpected response from iNaturalist"
        }
    }
}

// MARK: - Service

actor INaturalistService {
    static let shared = INaturalistService()

    private let baseURL = "https://api.inaturalist.org/v1/observations/species_counts"
    /// iNaturalist taxon ID for kingdom Plantae — scopes results to plants.
    private static let plantaeTaxonID = 47126

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches research-grade plant species counts reported near a coordinate
    /// in a given month.
    ///
    /// - Parameters:
    ///   - coordinate: A **coarse** cell center (already rounded by the caller).
    ///   - radiusKm: Search radius in kilometers (iNaturalist caps this).
    ///   - month: Calendar month 1...12 to constrain seasonality. `nil` = all year.
    ///   - locale: Locale used for `preferred_common_name`.
    ///   - limit: Max taxa to return (iNaturalist `per_page`, max 500).
    func speciesCounts(
        near coordinate: CLLocationCoordinate2D,
        radiusKm: Double = 25,
        month: Int? = nil,
        locale: Locale = .current,
        limit: Int = 200
    ) async throws -> [INatSpeciesCount] {
        try await speciesCounts(
            scope: [
                URLQueryItem(name: "lat", value: String(coordinate.latitude)),
                URLQueryItem(name: "lng", value: String(coordinate.longitude)),
                URLQueryItem(name: "radius", value: String(radiusKm))
            ],
            month: month,
            locale: locale,
            limit: limit
        )
    }

    /// Fetches research-grade plant species counts reported across one or more
    /// iNaturalist places, in a given month. A macro-region (e.g. the Pacific
    /// Northwest) is the union of its states' place IDs — iNaturalist accepts a
    /// comma-separated `place_id`, so the counts are aggregated server-side.
    ///
    /// - Parameters:
    ///   - placeIDs: iNaturalist place IDs whose observations to union.
    ///   - month: Calendar month 1...12 to constrain seasonality. `nil` = all year.
    ///   - locale: Locale used for `preferred_common_name`.
    ///   - limit: Max taxa to return (iNaturalist `per_page`, max 500).
    func speciesCounts(
        placeIDs: [Int],
        month: Int? = nil,
        locale: Locale = .current,
        limit: Int = 200
    ) async throws -> [INatSpeciesCount] {
        guard !placeIDs.isEmpty else { throw INaturalistError.invalidRequest }
        let joined = placeIDs.map(String.init).joined(separator: ",")
        return try await speciesCounts(
            scope: [URLQueryItem(name: "place_id", value: joined)],
            month: month,
            locale: locale,
            limit: limit
        )
    }

    /// Fetches the curated `taxon_photos` for a taxon, keeping only photos whose
    /// license permits reuse (all-rights-reserved photos come back with a null
    /// `license_code` and are dropped).
    func taxonPhotos(taxonID: Int, limit: Int = 8) async throws -> [INatTaxonPhoto] {
        guard let url = URL(string: "https://api.inaturalist.org/v1/taxa/\(taxonID)") else {
            throw INaturalistError.invalidRequest
        }

        let data = try await fetchData(from: url)

        let decoded: TaxaResponse
        do {
            decoded = try JSONDecoder().decode(TaxaResponse.self, from: data)
        } catch {
            throw INaturalistError.decodingFailed
        }

        let photos = (decoded.results.first?.taxonPhotos ?? []).compactMap { entry -> INatTaxonPhoto? in
            let photo = entry.photo
            guard photo.licenseCode != nil,
                  let medium = photo.bestMediumURL else { return nil }
            return INatTaxonPhoto(
                photoID: photo.id,
                mediumURL: medium,
                largeURL: photo.bestLargeURL,
                attribution: photo.attribution
            )
        }
        return Array(photos.prefix(max(limit, 1)))
    }

    /// Shared request/decode path. `scope` supplies the geographic constraint
    /// (lat/lng/radius or place_id); everything else is common.
    private func speciesCounts(
        scope: [URLQueryItem],
        month: Int?,
        locale: Locale,
        limit: Int
    ) async throws -> [INatSpeciesCount] {
        guard var components = URLComponents(string: baseURL) else {
            throw INaturalistError.invalidRequest
        }

        var query: [URLQueryItem] = [
            URLQueryItem(name: "taxon_id", value: String(Self.plantaeTaxonID)),
            URLQueryItem(name: "quality_grade", value: "research"),
            URLQueryItem(name: "per_page", value: String(min(max(limit, 1), 500))),
            URLQueryItem(name: "locale", value: locale.identifier)
        ]
        query.append(contentsOf: scope)
        if let month, (1...12).contains(month) {
            query.append(URLQueryItem(name: "month", value: String(month)))
        }
        components.queryItems = query

        guard let url = components.url else {
            throw INaturalistError.invalidRequest
        }

        let data = try await fetchData(from: url)

        let decoded: SpeciesCountsResponse
        do {
            decoded = try JSONDecoder().decode(SpeciesCountsResponse.self, from: data)
        } catch {
            throw INaturalistError.decodingFailed
        }

        return decoded.results.compactMap { result in
            guard let taxon = result.taxon, let name = taxon.name else { return nil }
            return INatSpeciesCount(
                taxonID: taxon.id,
                scientificName: name,
                commonName: taxon.preferredCommonName,
                count: result.count,
                defaultPhotoURL: taxon.defaultPhoto?.mediumURL.flatMap(URL.init(string:)),
                defaultPhotoLicense: taxon.defaultPhoto?.licenseCode
            )
        }
    }

    /// Shared GET + status handling for iNaturalist endpoints.
    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        // iNaturalist recommends identifying the client in the User-Agent.
        request.setValue("Fieldnote/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw INaturalistError.networkError
        }

        guard let http = response as? HTTPURLResponse else {
            throw INaturalistError.networkError
        }
        switch http.statusCode {
        case 200: break
        case 429: throw INaturalistError.rateLimited
        default: throw INaturalistError.networkError
        }
        return data
    }
}

// MARK: - Wire Models

private struct SpeciesCountsResponse: Decodable {
    let results: [Result]

    struct Result: Decodable {
        let count: Int
        let taxon: Taxon?
    }

    struct Taxon: Decodable {
        let id: Int
        let name: String?
        let preferredCommonName: String?
        let defaultPhoto: DefaultPhoto?

        enum CodingKeys: String, CodingKey {
            case id, name
            case preferredCommonName = "preferred_common_name"
            case defaultPhoto = "default_photo"
        }
    }

    struct DefaultPhoto: Decodable {
        let mediumURL: String?
        let licenseCode: String?

        enum CodingKeys: String, CodingKey {
            case mediumURL = "medium_url"
            case licenseCode = "license_code"
        }
    }
}

private struct TaxaResponse: Decodable {
    let results: [Result]

    struct Result: Decodable {
        let taxonPhotos: [TaxonPhotoEntry]?

        enum CodingKeys: String, CodingKey {
            case taxonPhotos = "taxon_photos"
        }
    }

    struct TaxonPhotoEntry: Decodable {
        let photo: Photo
    }

    struct Photo: Decodable {
        let id: Int
        let licenseCode: String?
        let attribution: String?
        let url: String?
        let mediumURL: String?
        let largeURL: String?

        enum CodingKeys: String, CodingKey {
            case id, attribution, url
            case licenseCode = "license_code"
            case mediumURL = "medium_url"
            case largeURL = "large_url"
        }

        /// Some responses omit the sized fields and only carry the square `url`;
        /// iNaturalist renditions differ only by the size token in the filename.
        var bestMediumURL: URL? {
            (mediumURL ?? url.map { $0.replacingOccurrences(of: "square", with: "medium") })
                .flatMap(URL.init(string:))
        }

        var bestLargeURL: URL? {
            (largeURL ?? url.map { $0.replacingOccurrences(of: "square", with: "large") })
                .flatMap(URL.init(string:))
        }
    }
}
