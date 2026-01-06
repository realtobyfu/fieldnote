//
//  WikipediaPlantService.swift
//  Fieldnote
//
//  Fetches plant data from Wikipedia to enrich uncatalogued plants
//

import Foundation

struct PlantEnrichmentResult {
    let summary: String
    let imageURL: URL?
    let habitat: String?
    let nativeRange: String?
    let wikiURL: URL?
}

struct WikipediaPlantService {

    private static let baseURL = "https://en.wikipedia.org/w/api.php"

    // MARK: - Public API

    /// Fetch enrichment data for a plant from Wikipedia
    /// Tries scientific name first, falls back to common name
    static func fetchPlantData(scientificName: String, commonName: String) async -> PlantEnrichmentResult? {
        print("DEBUG Wikipedia: Starting enrichment for scientific='\(scientificName)', common='\(commonName)'")

        // Try scientific name first (more specific)
        if !scientificName.isEmpty {
            print("DEBUG Wikipedia: Trying scientific name: \(scientificName)")
            if let result = await fetchByTitle(scientificName) {
                print("DEBUG Wikipedia: SUCCESS with scientific name!")
                print("DEBUG Wikipedia: Summary length: \(result.summary.count)")
                print("DEBUG Wikipedia: Habitat: \(result.habitat ?? "nil")")
                print("DEBUG Wikipedia: NativeRange: \(result.nativeRange ?? "nil")")
                return result
            }
            print("DEBUG Wikipedia: Scientific name returned nil")
        }

        // Fall back to common name
        if !commonName.isEmpty {
            print("DEBUG Wikipedia: Trying common name search: \(commonName)")
            if let result = await searchAndFetch(query: commonName) {
                print("DEBUG Wikipedia: SUCCESS with common name!")
                print("DEBUG Wikipedia: Summary length: \(result.summary.count)")
                print("DEBUG Wikipedia: Habitat: \(result.habitat ?? "nil")")
                print("DEBUG Wikipedia: NativeRange: \(result.nativeRange ?? "nil")")
                return result
            }
            print("DEBUG Wikipedia: Common name search returned nil")
        }

        print("DEBUG Wikipedia: FAILED - No enrichment data found")
        return nil
    }

    // MARK: - Private Methods

    /// Fetch Wikipedia page directly by title
    private static func fetchByTitle(_ title: String) async -> PlantEnrichmentResult? {
        let formattedTitle = title.replacingOccurrences(of: " ", with: "_")
        print("DEBUG Wikipedia fetchByTitle: \(formattedTitle)")

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "titles", value: formattedTitle),
            URLQueryItem(name: "prop", value: "extracts|pageimages|categories"),
            URLQueryItem(name: "exintro", value: "1"),
            URLQueryItem(name: "explaintext", value: "1"),
            URLQueryItem(name: "piprop", value: "original"),
            URLQueryItem(name: "cllimit", value: "20"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "origin", value: "*")
        ]

        guard let url = components.url else {
            print("DEBUG Wikipedia: Failed to build URL")
            return nil
        }
        print("DEBUG Wikipedia URL: \(url)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG Wikipedia HTTP status: \(httpResponse.statusCode)")
            }
            return parseWikipediaResponse(data, searchTitle: title)
        } catch {
            print("DEBUG Wikipedia fetch error: \(error)")
            return nil
        }
    }

    /// Search Wikipedia and fetch the top result
    private static func searchAndFetch(query: String) async -> PlantEnrichmentResult? {
        print("DEBUG Wikipedia searchAndFetch: \(query)")
        // First, search for the page
        var searchComponents = URLComponents(string: baseURL)!
        searchComponents.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "search"),
            URLQueryItem(name: "srsearch", value: "\(query) plant"),
            URLQueryItem(name: "srlimit", value: "1"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "origin", value: "*")
        ]

        guard let searchURL = searchComponents.url else {
            print("DEBUG Wikipedia: Failed to build search URL")
            return nil
        }
        print("DEBUG Wikipedia search URL: \(searchURL)")

        do {
            let (data, _) = try await URLSession.shared.data(from: searchURL)

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let queryResult = json["query"] as? [String: Any],
                  let search = queryResult["search"] as? [[String: Any]],
                  let firstResult = search.first,
                  let title = firstResult["title"] as? String else {
                print("DEBUG Wikipedia: Search returned no results or failed to parse")
                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("DEBUG Wikipedia search response: \(jsonStr.prefix(500))")
                }
                return nil
            }

            print("DEBUG Wikipedia: Search found title: \(title)")
            // Now fetch the full page content
            return await fetchByTitle(title)
        } catch {
            print("DEBUG Wikipedia search error: \(error)")
            return nil
        }
    }

    /// Parse Wikipedia API response into PlantEnrichmentResult
    private static func parseWikipediaResponse(_ data: Data, searchTitle: String) -> PlantEnrichmentResult? {
        print("DEBUG Wikipedia parseResponse for: \(searchTitle)")
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let query = json["query"] as? [String: Any],
                  let pages = query["pages"] as? [String: Any] else {
                print("DEBUG Wikipedia: Failed to parse JSON structure")
                return nil
            }

            // Get the first (and usually only) page
            guard let pageData = pages.values.first as? [String: Any],
                  let pageId = pageData["pageid"] as? Int,
                  pageId > 0 else {
                print("DEBUG Wikipedia: No valid page found (pageId missing or -1)")
                return nil
            }
            print("DEBUG Wikipedia: Found page ID \(pageId)")

            // Extract summary
            let extract = pageData["extract"] as? String ?? ""
            let summary = cleanSummary(extract)
            print("DEBUG Wikipedia: Extract length=\(extract.count), cleaned summary length=\(summary.count)")

            // Skip if summary is too short (likely not a real article)
            guard summary.count > 50 else {
                print("DEBUG Wikipedia: Summary too short (\(summary.count) chars), skipping")
                return nil
            }

            // Extract image URL
            var imageURL: URL?
            if let original = pageData["original"] as? [String: Any],
               let source = original["source"] as? String {
                imageURL = URL(string: source)
            }

            // Extract categories for habitat inference
            var habitat: String?
            var nativeRange: String?

            if let categories = pageData["categories"] as? [[String: Any]] {
                let categoryTitles = categories.compactMap { $0["title"] as? String }
                habitat = inferHabitat(from: categoryTitles, summary: summary)
                nativeRange = inferNativeRange(from: summary)
            } else {
                habitat = inferHabitat(from: [], summary: summary)
                nativeRange = inferNativeRange(from: summary)
            }

            // Build Wikipedia URL
            let pageTitle = (pageData["title"] as? String ?? searchTitle).replacingOccurrences(of: " ", with: "_")
            let wikiURL = URL(string: "https://en.wikipedia.org/wiki/\(pageTitle)")

            print("DEBUG Wikipedia: Building result - summary=\(summary.prefix(100))...")
            print("DEBUG Wikipedia: habitat=\(habitat ?? "nil"), nativeRange=\(nativeRange ?? "nil")")

            return PlantEnrichmentResult(
                summary: summary,
                imageURL: imageURL,
                habitat: habitat,
                nativeRange: nativeRange,
                wikiURL: wikiURL
            )
        } catch {
            print("DEBUG Wikipedia parse error: \(error)")
            return nil
        }
    }

    /// Clean up Wikipedia extract text
    private static func cleanSummary(_ text: String) -> String {
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Limit to first 2-3 sentences for a reasonable summary
        let sentences = cleaned.components(separatedBy: ". ")
        if sentences.count > 3 {
            cleaned = sentences.prefix(3).joined(separator: ". ")
            if !cleaned.hasSuffix(".") {
                cleaned += "."
            }
        }

        // Limit total length
        if cleaned.count > 500 {
            cleaned = String(cleaned.prefix(500))
            if let lastPeriod = cleaned.lastIndex(of: ".") {
                cleaned = String(cleaned[...lastPeriod])
            } else {
                cleaned += "..."
            }
        }

        return cleaned
    }

    /// Infer habitat from Wikipedia categories and summary text
    private static func inferHabitat(from categories: [String], summary: String) -> String? {
        let combined = (categories.joined(separator: " ") + " " + summary).lowercased()

        // Check for habitat keywords
        if combined.contains("wetland") || combined.contains("marsh") ||
           combined.contains("swamp") || combined.contains("aquatic") {
            return "wetlands"
        }
        if combined.contains("forest") || combined.contains("woodland") ||
           combined.contains("deciduous") || combined.contains("coniferous") {
            return "forests"
        }
        if combined.contains("meadow") || combined.contains("prairie") ||
           combined.contains("grassland") || combined.contains("field") {
            return "meadows"
        }
        if combined.contains("garden") || combined.contains("ornamental") ||
           combined.contains("cultivated") || combined.contains("urban") {
            return "urban"
        }
        if combined.contains("mountain") || combined.contains("alpine") {
            return "mountains"
        }
        if combined.contains("coastal") || combined.contains("beach") ||
           combined.contains("dune") {
            return "coastal"
        }

        return nil
    }

    /// Extract native range information from summary text
    private static func inferNativeRange(from summary: String) -> String? {
        let lowercased = summary.lowercased()

        // Common patterns for native range
        let patterns = [
            "native to ",
            "indigenous to ",
            "originates from ",
            "originally from ",
            "found throughout ",
            "endemic to "
        ]

        for pattern in patterns {
            if let range = lowercased.range(of: pattern) {
                let startIndex = summary.index(range.lowerBound, offsetBy: 0, limitedBy: summary.endIndex) ?? summary.startIndex
                let substring = String(summary[startIndex...])

                // Extract until end of sentence
                if let periodIndex = substring.firstIndex(of: ".") {
                    var result = String(substring[..<periodIndex])
                    // Capitalize first letter
                    if let firstChar = result.first {
                        result = String(firstChar).uppercased() + String(result.dropFirst())
                    }
                    // Limit length
                    if result.count <= 100 {
                        return result
                    }
                }
            }
        }

        return nil
    }
}
