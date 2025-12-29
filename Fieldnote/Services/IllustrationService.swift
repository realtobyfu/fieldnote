//
//  IllustrationService.swift
//  Fieldnote
//
//  Maps plant names to bundled botanical illustration assets
//

import Foundation

struct IllustrationService {

    // MARK: - Direct Plant Name Mappings

    /// Maps common plant name variants to illustration asset names (1-1 only)
    private static let illustrationAliases: [String: String] = [
        "common_dandelion": "dandelion",
        "common_blue_violet": "wild_violet",
        "blue_violet": "wild_violet",
        "black_eyed_susan": "black-eyed_susan"
    ]

    // MARK: - Public API

    static func illustrationName(for commonName: String, family: String? = nil) -> String? {
        let normalized = commonName
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: " ", with: "_")

        if availableIllustrationSet.contains(normalized) {
            return normalized
        }

        if let alias = illustrationAliases[normalized],
           availableIllustrationSet.contains(alias) {
            return alias
        }

        return nil
    }

    static func hasIllustration(for commonName: String, family: String? = nil) -> Bool {
        illustrationName(for: commonName, family: family) != nil
    }

    static func genericFallback(for commonName: String) -> String {
        let name = commonName.lowercased()

        if name.contains("oak") || name.contains("maple") || name.contains("tree") {
            return "tree"
        } else if name.contains("fern") {
            return "fern"
        } else if name.contains("grass") || name.contains("sedge") {
            return "grass"
        } else {
            return "wildflower"
        }
    }

    // MARK: - Available Illustrations

    static let availableIllustrations: [String] = [
        // Trees
        "american_elm",
        "american_sycamore",
        "black_cherry",
        "eastern_hemlock",
        "eastern_red_cedar",
        "paper_birch",
        "red_maple",
        "red_oak",
        "sugar_maple",
        "weeping_willow",
        "white_pine",

        // Wildflowers
        "black-eyed_susan",
        "bloodroot",
        "cardinal_flower",
        "common_milkweed",
        "dandelion",
        "goldenrod",
        "purple_coneflower",
        "queen_annes_lace",
        "virginia_bluebells",
        "wild_bergamot",
        "wild_geranium",
        "white_clover",
        "wild_violet",

        // Shrubs
        "elderberry",
        "mountain_laurel",
        "winterberry",
        "witch_hazel",

        // Vines
        "american_wisteria",
        "poison_ivy",
        "trumpet_vine",
        "virginia_creeper",
        "wild_grape",

        // Ornamentals
        "eastern_redbud",
        "flowering_dogwood"
    ]

    private static let availableIllustrationSet = Set(availableIllustrations)
}
