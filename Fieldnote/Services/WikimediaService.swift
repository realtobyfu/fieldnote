//
//  WikimediaService.swift
//  Fieldnote
//
//  Fetches plant images from Wikipedia/Wikimedia Commons
//

import UIKit

actor WikimediaService {
    static let shared = WikimediaService()

    private let baseURL = "https://en.wikipedia.org/api/rest_v1/page/summary"

    // MARK: - Public API

    /// Fetch a plant image from Wikipedia and save it as the plant's custom illustration
    /// Returns true if successful, false otherwise
    func fetchAndSaveIllustration(for plant: Plant) async -> Bool {
        print("DEBUG WikimediaService: Starting fetch for '\(plant.commonName)'")

        // Try scientific name first, then common name
        var imageURL: URL?

        if !plant.scientificName.isEmpty && plant.scientificName != "Species unknown" {
            imageURL = await fetchImageURL(query: plant.scientificName)
        }

        if imageURL == nil && !plant.commonName.isEmpty {
            imageURL = await fetchImageURL(query: plant.commonName)
        }

        guard let url = imageURL else {
            print("DEBUG WikimediaService: No image found for '\(plant.commonName)'")
            return false
        }

        // Download the image
        guard let image = await downloadImage(from: url) else {
            print("DEBUG WikimediaService: Failed to download image from \(url)")
            return false
        }

        // Save the image
        do {
            let filename = try await PlantIllustrationStorageService.shared.saveIllustration(
                image,
                for: plant.id
            )

            // Update plant on main actor
            await MainActor.run {
                plant.customIllustrationFileName = filename
                plant.illustrationSource = .wikipedia
            }

            print("DEBUG WikimediaService: Successfully saved illustration for '\(plant.commonName)'")
            return true
        } catch {
            print("DEBUG WikimediaService: Failed to save illustration: \(error)")
            return false
        }
    }

    /// Fetch just the image for preview/display purposes (doesn't save)
    func fetchPlantImage(scientificName: String?, commonName: String) async -> UIImage? {
        var imageURL: URL?

        if let scientific = scientificName, !scientific.isEmpty {
            imageURL = await fetchImageURL(query: scientific)
        }

        if imageURL == nil && !commonName.isEmpty {
            imageURL = await fetchImageURL(query: commonName)
        }

        guard let url = imageURL else { return nil }
        return await downloadImage(from: url)
    }

    // MARK: - Private Methods

    /// Fetch the image URL from Wikipedia's REST API
    private func fetchImageURL(query: String) async -> URL? {
        // Format the query for Wikipedia URL (spaces become underscores)
        let formattedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")

        guard let encodedQuery = formattedQuery.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/\(encodedQuery)") else {
            print("DEBUG WikimediaService: Failed to build URL for '\(query)'")
            return nil
        }

        print("DEBUG WikimediaService: Fetching from \(url)")

        do {
            var request = URLRequest(url: url)
            request.setValue("Fieldnote/1.0 (iOS Plant Identification App)", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }

            // Handle redirects - Wikipedia often redirects to the correct article
            if httpResponse.statusCode == 302 || httpResponse.statusCode == 301 {
                // Try following redirect manually if needed
                print("DEBUG WikimediaService: Got redirect for '\(query)'")
            }

            guard httpResponse.statusCode == 200 else {
                print("DEBUG WikimediaService: HTTP \(httpResponse.statusCode) for '\(query)'")
                return nil
            }

            return parseImageURL(from: data)
        } catch {
            print("DEBUG WikimediaService: Network error: \(error)")
            return nil
        }
    }

    /// Parse the REST API response to extract image URL
    private func parseImageURL(from data: Data) -> URL? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            // The REST API returns either 'thumbnail' or 'originalimage'
            // Prefer originalimage for better quality, but limit size
            if let original = json["originalimage"] as? [String: Any],
               let source = original["source"] as? String,
               let url = URL(string: source) {
                print("DEBUG WikimediaService: Found original image: \(source)")
                return url
            }

            // Fallback to thumbnail if original isn't available
            if let thumbnail = json["thumbnail"] as? [String: Any],
               let source = thumbnail["source"] as? String,
               let url = URL(string: source) {
                print("DEBUG WikimediaService: Found thumbnail: \(source)")
                return url
            }

            print("DEBUG WikimediaService: No image in response")
            return nil
        } catch {
            print("DEBUG WikimediaService: JSON parse error: \(error)")
            return nil
        }
    }

    /// Download an image from a URL
    private func downloadImage(from url: URL) async -> UIImage? {
        do {
            var request = URLRequest(url: url)
            request.setValue("Fieldnote/1.0 (iOS Plant Identification App)", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            // Create image and optionally resize if too large
            guard let image = UIImage(data: data) else {
                return nil
            }

            // Resize if the image is very large (> 2000px on any side)
            let maxDimension: CGFloat = 2000
            if image.size.width > maxDimension || image.size.height > maxDimension {
                return resizeImage(image, maxDimension: maxDimension)
            }

            return image
        } catch {
            print("DEBUG WikimediaService: Download error: \(error)")
            return nil
        }
    }

    /// Resize an image to fit within a maximum dimension
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let ratio = min(maxDimension / image.size.width, maxDimension / image.size.height)
        let newSize = CGSize(
            width: image.size.width * ratio,
            height: image.size.height * ratio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
