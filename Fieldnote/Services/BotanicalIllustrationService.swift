//
//  BotanicalIllustrationService.swift
//  Fieldnote
//
//  Maps plant names to bundled botanical illustration assets
//

import Foundation

struct BotanicalIllustrationService {

    // MARK: - Direct Plant Name Mappings

    /// Maps common plant names to asset names
    private static let illustrationMap: [String: String] = [
        // Common wildflowers
        "dandelion": "dandelion",
        "common dandelion": "dandelion",
        "clover": "clover",
        "white clover": "clover",
        "red clover": "clover",
        "violet": "violet",
        "common violet": "violet",
        "wild violet": "violet",
        "daisy": "daisy",
        "common daisy": "daisy",
        "oxeye daisy": "daisy",

        // Garden flowers
        "rose": "rose",
        "wild rose": "rose",
        "lavender": "lavender",
        "sunflower": "sunflower",
        "poppy": "poppy",
        "foxglove": "foxglove",
        "lily": "lily",
        "chamomile": "chamomile",

        // Trees
        "oak": "oak",
        "white oak": "oak",
        "red oak": "oak",
        "maple": "maple",
        "sugar maple": "maple",
        "red maple": "maple",
        "birch": "birch",
        "pine": "pine",
        "white pine": "pine",
        "willow": "willow",
        "weeping willow": "willow",

        // Herbs
        "mint": "mint",
        "peppermint": "mint",
        "spearmint": "mint",
        "basil": "herb",
        "thyme": "herb",
        "rosemary": "herb",
        "sage": "herb",

        // Other plants
        "fern": "fern",
        "boston fern": "fern",
        "ivy": "ivy",
        "english ivy": "ivy",
        "moss": "moss",
        "mushroom": "mushroom",
    ]

    // MARK: - Family-Based Fallbacks

    /// Maps plant families to fallback illustration assets
    private static let familyFallbacks: [String: String] = [
        "asteraceae": "wildflower",      // Daisy family
        "rosaceae": "rose",              // Rose family
        "fabaceae": "clover",            // Legume family
        "poaceae": "grass",              // Grass family
        "fagaceae": "oak",               // Beech/Oak family
        "lamiaceae": "herb",             // Mint family
        "apiaceae": "herb",              // Carrot family
        "brassicaceae": "wildflower",    // Mustard family
        "solanaceae": "wildflower",      // Nightshade family
        "liliaceae": "lily",             // Lily family
        "orchidaceae": "wildflower",     // Orchid family
        "pinaceae": "pine",              // Pine family
        "betulaceae": "birch",           // Birch family
        "salicaceae": "willow",          // Willow family
        "polypodiaceae": "fern",         // Fern family
    ]

    // MARK: - Public API

    /// Get the illustration asset name for a plant
    /// - Parameters:
    ///   - commonName: The plant's common name
    ///   - family: Optional plant family for fallback matching
    /// - Returns: Asset name if found, nil otherwise
    static func illustrationName(for commonName: String, family: String? = nil) -> String? {
        let normalized = commonName.lowercased().trimmingCharacters(in: .whitespaces)

        // Try direct match first
        if let name = illustrationMap[normalized] {
            return name
        }

        // Try partial matching (plant name contains a key or key contains plant name)
        for (key, value) in illustrationMap {
            if normalized.contains(key) || key.contains(normalized) {
                return value
            }
        }

        // Try family-based fallback
        if let family = family?.lowercased() {
            if let fallback = familyFallbacks[family] {
                return fallback
            }
        }

        return nil
    }

    /// Check if a specific illustration asset exists for a plant
    static func hasIllustration(for commonName: String, family: String? = nil) -> Bool {
        illustrationName(for: commonName, family: family) != nil
    }

    /// Get a generic fallback illustration based on plant type hints
    static func genericFallback(for commonName: String) -> String {
        let name = commonName.lowercased()

        if name.contains("tree") || name.contains("oak") || name.contains("maple") {
            return "tree"
        } else if name.contains("grass") || name.contains("sedge") {
            return "grass"
        } else if name.contains("fern") {
            return "fern"
        } else if name.contains("mushroom") || name.contains("fungus") {
            return "mushroom"
        } else if name.contains("herb") || name.contains("mint") {
            return "herb"
        } else {
            return "wildflower"
        }
    }

    // MARK: - Available Illustrations

    /// List of all bundled illustration asset names
    static let availableIllustrations: [String] = [
        // Specific plants
        "dandelion", "clover", "violet", "daisy", "rose",
        "lavender", "sunflower", "poppy", "foxglove", "lily",
        "chamomile", "oak", "maple", "birch", "pine", "willow",
        "mint", "fern", "ivy", "moss", "mushroom",

        // Generic fallbacks
        "wildflower", "tree", "grass", "herb", "shrub"
    ]
}
