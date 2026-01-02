//
//  PlantIDAPIService.swift
//  Fieldnote
//
//  Pl@ntNet API client for plant identification
//

import UIKit
import CoreLocation

// MARK: - Pl@ntNet Response Models

/// Top-level response from Pl@ntNet identification endpoint
struct PlantNetResponse: Codable {
    let results: [PlantNetResult]
    let remainingIdentificationRequests: Int?
}

/// Individual identification result
struct PlantNetResult: Codable {
    let score: Double
    let species: PlantNetSpecies
}

/// Species information
struct PlantNetSpecies: Codable {
    let scientificNameWithoutAuthor: String
    let scientificNameAuthorship: String?
    let genus: PlantNetTaxon?
    let family: PlantNetTaxon?
    let commonNames: [String]?
}

/// Taxonomic unit (genus, family)
struct PlantNetTaxon: Codable {
    let scientificNameWithoutAuthor: String
    let scientificNameAuthorship: String?
}

// MARK: - API Service

actor PlantIDAPIService {
    static let shared = PlantIDAPIService()

    private let apiKey: String
    private let baseURL = "https://my-api.plantnet.org/v2/identify/all"

    private init() {
        // Load API key from Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            print("DEBUG: Found Config.plist at: \(path)")
            if let config = NSDictionary(contentsOfFile: path) {
                print("DEBUG: Config.plist contents: \(config)")
                if let key = config["PLANT_ID_API_KEY"] as? String {
                    print("DEBUG: Found API key (length: \(key.count))")
                    self.apiKey = key
                } else {
                    print("DEBUG: PLANT_ID_API_KEY not found in plist")
                    self.apiKey = ""
                }
            } else {
                print("DEBUG: Could not read Config.plist contents")
                self.apiKey = ""
            }
        } else {
            print("DEBUG: Config.plist not found in bundle")
            self.apiKey = ""
        }
    }

    /// Identifies a plant from an image using the Pl@ntNet API
    func identify(image: UIImage, location: CLLocationCoordinate2D? = nil) async throws -> PlantIdentificationResult {
        // Validate API key is configured
        guard !apiKey.isEmpty else {
            throw PlantIdentificationError.invalidAPIKey
        }

        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PlantIdentificationError.imageProcessingFailed
        }

        // Build URL with API key as query parameter
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw PlantIdentificationError.networkError
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "api-key", value: apiKey)
        ]
        guard let url = urlComponents.url else {
            throw PlantIdentificationError.networkError
        }

        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
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

        print("DEBUG: Pl@ntNet Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("DEBUG: Pl@ntNet Response Body: \(responseString.prefix(500))")
        }

        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 401:
            print("DEBUG: 401 Unauthorized - API key may be invalid")
            throw PlantIdentificationError.invalidAPIKey
        case 404:
            // Pl@ntNet returns 404 when no plant is found
            throw PlantIdentificationError.noResult
        case 429:
            throw PlantIdentificationError.rateLimited
        default:
            print("DEBUG: Unexpected status code: \(httpResponse.statusCode)")
            throw PlantIdentificationError.networkError
        }

        // Decode response
        let decoded = try JSONDecoder().decode(PlantNetResponse.self, from: data)

        // Get top result
        guard let top = decoded.results.first, top.score >= 0.1 else {
            throw PlantIdentificationError.noResult
        }

        // Map to local result type
        return PlantIdentificationResult(
            commonName: top.species.commonNames?.first ?? top.species.scientificNameWithoutAuthor,
            scientificName: top.species.scientificNameWithoutAuthor,
            family: top.species.family?.scientificNameWithoutAuthor ?? "",
            confidence: top.score
        )
    }
}
