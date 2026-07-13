//
//  PlantIDAPIService.swift
//  Fieldnote
//
//  Plant identification client. Talks to the Fieldnote backend proxy
//  (`POST /v1/identify`), which holds the paid Pl@ntNet key server-side and
//  returns a slimmed candidate list. The app ships only a low-trust bearer
//  token — never the Pl@ntNet key. See Docs/BackendM2Spec.md.
//

import UIKit
import CoreLocation

// MARK: - Proxy Response Models

/// Slimmed identify response from the Fieldnote backend. Decouples the app from
/// Pl@ntNet's raw schema — the Worker does the mapping.
struct IdentifyProxyResponse: Codable {
    let candidates: [IdentifyProxyCandidate]
    let remainingRequests: Int?
}

/// One slimmed candidate, mapping 1:1 onto `PlantIdentificationCandidate`.
struct IdentifyProxyCandidate: Codable {
    let scientificName: String
    let commonName: String
    let family: String
    let visualConfidence: Double
    let gbifTaxonKey: Int?
}

// MARK: - Candidate

/// A single visual identification candidate, carrying the raw provider score so
/// it can be reranked against a local + seasonal prior before being shown.
struct PlantIdentificationCandidate: Hashable {
    let commonName: String
    let scientificName: String
    let family: String
    /// Visual match likelihood from the provider, 0...1.
    let visualConfidence: Double
    /// GBIF taxon key when the provider supplied one (used for matching).
    let gbifTaxonKey: Int?

    var asResult: PlantIdentificationResult {
        PlantIdentificationResult(
            commonName: commonName,
            scientificName: scientificName,
            family: family,
            confidence: visualConfidence
        )
    }
}

// MARK: - API Service

actor PlantIDAPIService {
    static let shared = PlantIDAPIService()

    /// Backend identify endpoint, e.g. "https://api.fieldnote.app/v1/identify".
    private let identifyURL: URL?
    /// Low-trust per-app bearer token sent to the proxy.
    private let appToken: String?

    private init() {
        self.identifyURL = BackendConfig.baseURL?.appendingPathComponent("v1/identify")
        self.appToken = BackendConfig.appToken
    }

    /// Identifies a plant from an image, returning the single best visual match.
    /// Retained for callers that don't yet handle alternatives.
    func identify(image: UIImage, location: CLLocationCoordinate2D? = nil) async throws -> PlantIdentificationResult {
        let candidates = try await identifyCandidates(image: image, location: location)
        guard let top = candidates.first else {
            throw PlantIdentificationError.noResult
        }
        return top.asResult
    }

    /// Identifies a plant and returns the top visual candidates (highest score
    /// first), so the caller can rerank them with a local + seasonal prior and
    /// surface alternatives. See LocalRankingService.rerankCandidates.
    func identifyCandidates(
        image: UIImage,
        location: CLLocationCoordinate2D? = nil,
        maxResults: Int = 5
    ) async throws -> [PlantIdentificationCandidate] {
        // Backend must be configured (base URL + app token).
        guard let identifyURL, let appToken, !appToken.isEmpty else {
            throw PlantIdentificationError.invalidAPIKey
        }

        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PlantIdentificationError.imageProcessingFailed
        }

        // Create multipart form data — same fields the proxy forwards to Pl@ntNet.
        let boundary = UUID().uuidString
        var request = URLRequest(url: identifyURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(appToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20

        var body = Data()

        // Add organ field (auto-detect)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"organs\"\r\n\r\n".data(using: .utf8)!)
        body.append("auto\r\n".data(using: .utf8)!)

        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"images\"; filename=\"plant.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlantIdentificationError.networkError
        }

        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 401:
            // Bad/expired app token — configuration problem, not user error.
            throw PlantIdentificationError.invalidAPIKey
        case 429:
            throw PlantIdentificationError.rateLimited
        default:
            throw PlantIdentificationError.networkError
        }

        // Decode the slimmed proxy response.
        let decoded = try JSONDecoder().decode(IdentifyProxyResponse.self, from: data)

        let candidates = decoded.candidates
            .prefix(maxResults)
            .map { candidate in
                PlantIdentificationCandidate(
                    commonName: candidate.commonName,
                    scientificName: candidate.scientificName,
                    family: candidate.family,
                    visualConfidence: candidate.visualConfidence,
                    gbifTaxonKey: candidate.gbifTaxonKey
                )
            }

        guard !candidates.isEmpty else {
            throw PlantIdentificationError.noResult
        }

        return Array(candidates)
    }
}
