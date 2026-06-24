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
        guard var components = URLComponents(string: baseURL) else {
            throw INaturalistError.invalidRequest
        }

        var query: [URLQueryItem] = [
            URLQueryItem(name: "taxon_id", value: String(Self.plantaeTaxonID)),
            URLQueryItem(name: "quality_grade", value: "research"),
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude)),
            URLQueryItem(name: "radius", value: String(radiusKm)),
            URLQueryItem(name: "per_page", value: String(min(max(limit, 1), 500))),
            URLQueryItem(name: "locale", value: locale.identifier)
        ]
        if let month, (1...12).contains(month) {
            query.append(URLQueryItem(name: "month", value: String(month)))
        }
        components.queryItems = query

        guard let url = components.url else {
            throw INaturalistError.invalidRequest
        }

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
