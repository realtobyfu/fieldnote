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
        "black_eyed_susan": "black-eyed_susan",
        "spicebush": "northern_spicebush",
        "joe_pye_weed": "joe-pye_weed",
        "joe_pye-weed": "joe-pye_weed",
        "dutchmans_breeches": "dutchman's_breeches"
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

    // MARK: - Attribution

    /// Attribution for the illustration a plant resolves to, or `nil` when the
    /// illustration is an original Fieldnote (AI-generated) plate — which is
    /// intentionally left uncredited. Keyed by resolved asset name so the credit
    /// tracks the image, not the plant.
    static func credit(for commonName: String, family: String? = nil) -> IllustrationCredit? {
        guard let assetName = illustrationName(for: commonName, family: family) else {
            return nil
        }
        return illustrationCredits[assetName]
    }

    /// Credits for reproductions of real, human-authored public-domain plates,
    /// keyed by asset name. Assets absent from this map are original
    /// Fieldnote illustrations and are deliberately uncredited.
    ///
    /// Assets NOT in this map are original Fieldnote (AI-generated) illustrations
    /// and are deliberately uncredited. Add a row here ONLY when a species' real,
    /// human-authored public-domain plate has actually replaced its AI asset —
    /// crediting an AI image would be a false attribution.
    ///
    /// The 10 entries below are the pilot batch: each bundled asset is now a real
    /// public-domain plate (sourced from Wikimedia Commons, July 2026); `sourceURL`
    /// links the exact scan. Where the individual plate engraver is uncredited we
    /// name the work's author instead (Bigelow's American Medical Botany; the three
    /// Britton & Brown engravings) and never invent an engraver. See
    /// Docs/IllustrationSourcing.md.
    static let illustrationCredits: [String: IllustrationCredit] = [
        "red_oak": IllustrationCredit(
            creator: "Charles Edward Faxon",
            title: "Quercus rubra",
            publication: "The Silva of North America",
            year: 1895,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:Silva_of_North_America._Volume_VIII,_Cupulfer%C3%A6_(quercus),_The_-_DPLA_-_b9f64d18c757dc555a1796e78beca693_(page_185).jpg"),
            license: .publicDomain
        ),
        "red_maple": IllustrationCredit(
            creator: "Charles Edward Faxon",
            title: "Acer rubrum",
            publication: "The Silva of North America",
            year: 1895,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:Silva_of_North_America._Volume_II,_Cyrillaceae_-_sapindaceae,_The_-_DPLA_-_96d7c6e80c6075e323cf6c3a7ea4cd74_(page_156).jpg"),
            license: .publicDomain
        ),
        "dandelion": IllustrationCredit(
            creator: "Walther Otto Müller",
            publication: "Köhler's Medizinal-Pflanzen",
            year: 1887,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:Taraxacum_officinale_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-135.jpg"),
            license: .publicDomain
        ),
        "common_milkweed": IllustrationCredit(
            creator: "Charles Frederick Millspaugh",
            publication: "American Medicinal Plants",
            year: 1887,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:American_medicinal_plants_(Plate_134)_(6025430995).jpg"),
            license: .publicDomain
        ),
        "purple_coneflower": IllustrationCredit(
            creator: "Abraham Jacobus Wendel",
            publication: "Witte, Flora",
            year: 1868,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:WitteHeinrichFlora1868-012-Echinacea_purpurea.png"),
            license: .publicDomain
        ),
        "bloodroot": IllustrationCredit(
            creator: "Jacob Bigelow",
            publication: "American Medical Botany",
            year: 1817,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:American_medical_botany_(Pl._VII)_BHL2955660.jpg"),
            license: .publicDomain
        ),
        "flowering_dogwood": IllustrationCredit(
            creator: "Britton & Brown",
            publication: "An Illustrated Flora of the Northern United States and Canada",
            year: 1913,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:Cornus_florida_BrittonBrown.png"),
            license: .publicDomain
        ),
        "black-eyed_susan": IllustrationCredit(
            creator: "Britton & Brown",
            publication: "An Illustrated Flora of the Northern United States and Canada",
            year: 1913,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:Rudbeckia_hirta-linedrawing.png"),
            license: .publicDomain
        ),
        "trillium": IllustrationCredit(
            creator: "Abraham Jacobus Wendel",
            publication: "Witte, Flora",
            year: 1868,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:WitteHeinrichFlora1868-043-Trillium_grandiflorum.png"),
            license: .publicDomain
        ),
        "cardinal_flower": IllustrationCredit(
            creator: "Britton & Brown",
            publication: "An Illustrated Flora of the Northern United States and Canada",
            year: 1913,
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:Lobelia_cardinalis_L._Cardinalflower.tiff"),
            license: .publicDomain
        )
    ]

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
        "dutchman's_breeches",
        "goldenrod",
        "joe-pye_weed",
        "purple_coneflower",
        "trillium",
        "queen_annes_lace",
        "virginia_bluebells",
        "wild_bergamot",
        "wild_geranium",
        "white_clover",
        "wild_violet",

        // Shrubs
        "button_bush",
        "elderberry",
        "mountain_laurel",
        "northern_spicebush",
        "rhododendron",
        "viburnum",
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
