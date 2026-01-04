//
//  PlantPhotoService.swift
//  Fieldnote
//
//  Maps plant names to bundled plant photo assets (separate from illustrations)
//

import Foundation

struct PlantPhotoService {

    // MARK: - Direct Plant Name Mappings

    /// Maps common plant names to base photo keys
    private static let photoMap: [String: String] = [
        // Wildflowers and herbaceous plants
        "dandelion": "dandelion",
        "common dandelion": "dandelion",

        "black-eyed susan": "black-eyed_susan",
        "black eyed susan": "black-eyed_susan",

        "purple coneflower": "purple_coneflower",

        "white clover": "white_clover",
        "clover": "white_clover",

        "wild violet": "wild_violet",
        "violet": "wild_violet",
        "common blue violet": "wild_violet",
        "blue violet": "wild_violet",

        "queen anne's lace": "queen_annes_lace",
        "queen annes lace": "queen_annes_lace",

        "common milkweed": "common_milkweed",
        "milkweed": "common_milkweed",

        // Trees
        "american elm": "american_elm",
        "elm": "american_elm",

        "eastern hemlock": "eastern_hemlock",
        "hemlock": "eastern_hemlock",

        "eastern redbud": "eastern_redbud",
        "flowering dogwood": "flowering_dogwood",
        "mountain laurel": "mountain_laurel",
        "black cherry": "black_cherry",

        "american wisteria": "american_wisteria",
        "wisteria": "american_wisteria",

        "bloodroot": "bloodroot",
        "cardinal flower": "cardinal_flower",
        "goldenrod": "goldenrod",
        "wild bergamot": "wild_bergamot",
        "wild geranium": "wild_geranium",
        "virginia bluebells": "virginia_bluebells",
        "trumpet vine": "trumpet_vine",
        "wild grape": "wild_grape",

        "elderberry": "elderberry",
        "witch hazel": "witch_hazel",

        "buttonbush": "button_bush",
        "button bush": "button_bush",

        "dutchman's breeches": "dutchmans_breeches",
        "dutchmans breeches": "dutchmans_breeches",

        "joe pye weed": "joe_pye_weed",
        "joe-pye weed": "joe_pye_weed",

        "spicebush": "northern_spicebush",
        "northern spicebush": "northern_spicebush",

        "rhododendron": "rhododendron",

        "trillium": "trillium",

        "viburnum": "viburnum",

        "paper birch": "paper_birch",
        "birch": "paper_birch",

        "white pine": "white_pine",
        "pine": "white_pine",

        "weeping willow": "weeping_willow",
        "willow": "weeping_willow",

        "red maple": "red_maple",
        "sugar maple": "sugar_maple",
        "maple": "maple"
    ]

    /// Ordered photo asset names per plant key (exact-match only)
    private static let photoAssetsByPlant: [String: [String]] = [
        "american_elm": [
            "american_elm_photo_01",
            "american_elm_photo_02",
            "american_elm_photo_03"
        ],
        "american_wisteria": [
            "american_wisteria_photo_01",
            "american_wisteria_photo_02"
        ],
        "black_cherry": [
            "black_cherry_photo_01",
            "black_cherry_photo_02"
        ],
        "black-eyed_susan": [
            "black-eyed_susan_photo_01",
            "black-eyed_susan_photo_02"
        ],
        "bloodroot": [
            "bloodroot_photo_01",
            "bloodroot_photo_02"
        ],
        "cardinal_flower": [
            "cardinal_flower_photo_01",
            "cardinal_flower_photo_02",
            "cardinal_flower_photo_03"
        ],
        "common_milkweed": [
            "common_milkweed_photo_01",
            "common_milkweed_photo_02"
        ],
        "dandelion": [
            "dandelion_photo_01",
            "dandelion_photo_02"
        ],
        "eastern_hemlock": [
            "eastern_hemlock_photo_01",
            "eastern_hemlock_photo_02"
        ],
        "eastern_redbud": [
            "eastern_redbud_photo_01",
            "eastern_redbud_photo_02"
        ],
        "elderberry": [
            "elderberry_photo_01",
            "elderberry_photo_02"
        ],
        "flowering_dogwood": [
            "flowering_dogwood_photo_01",
            "flowering_dogwood_photo_02"
        ],
        "goldenrod": [
            "goldenrod_photo_01",
            "goldenrod_photo_02"
        ],
        "mountain_laurel": [
            "mountain_laurel_photo_01",
            "mountain_laurel_photo_02",
            "mountain_laurel_photo_03"
        ],
        "paper_birch": [
            "paper_birch_photo_01",
            "paper_birch_photo_02"
        ],
        "purple_coneflower": [
            "purple_coneflower_photo_01",
            "purple_coneflower_photo_02"
        ],
        "queen_annes_lace": [
            "queen_annes_lace_photo_01",
            "queen_annes_lace_photo_2"
        ],
        "red_maple": [
            "red_maple_photo_02",
            "red_maple_photo_03"
        ],
        "sugar_maple": [
            "sugar_maple_photo_02",
            "sugar_maple_photo_03"
        ],
        "trumpet_vine": [
            "trumpet_vine_photo_01",
            "trumpet_vine_photo_02"
        ],
        "virginia_bluebells": [
            "virginia_bluebells_photo_01",
            "virginia_bluebells_photo_02"
        ],
        "weeping_willow": [
            "weeping_willow_photo_01",
            "weeping_willow_photo_02"
        ],
        "white_clover": [
            "white_clover_photo_01",
            "white_clover_photo_02"
        ],
        "white_pine": [
            "white_pine_photo_01",
            "white_pine_photo_02"
        ],
        "wild_bergamot": [
            "wild_bergamot_photo_01",
            "wild_bergamot_photo_02"
        ],
        "wild_geranium": [
            "wild_geranium_photo_01",
            "wild_geranium_photo_02"
        ],
        "wild_grape": [
            "wild_grape_photo_01",
            "wild_grape_photo_02"
        ],
        "wild_violet": [
            "wild_violet_photo_1",
            "wild_violet_photo_2"
        ],
        "witch_hazel": [
            "witch_hazel_photo_01",
            "witch_hazel_photo_02"
        ],
        "button_bush": [
            "button_bush_photo_01",
            "button_bush_photo_02"
        ],
        "dutchmans_breeches": [
            "dutchman's_breeches_photo_01",
            "dutchman's_breeches_photo_02"
        ],
        "joe_pye_weed": [
            "joe-pye_weed_photo_01",
            "joe-pye_weed_photo_02"
        ],
        "northern_spicebush": [
            "northern_spicebush_photo_01",
            "northern_spicebush_photo_02"
        ],
        "rhododendron": [
            "rhododendron_photo_01",
            "rhododendron_photo_02",
            "rhododendron_photo_03"
        ],
        "trillium": [
            "trillium_photo_01",
            "trillium_photo_02"
        ],
        "viburnum": [
            "viburnum_photo_01",
            "viburnum_photo_02"
        ],
        "maple": [
            "red_maple_photo_02",
            "red_maple_photo_03",
            "sugar_maple_photo_02",
            "sugar_maple_photo_03"
        ]
    ]

    // MARK: - Public API

    /// Get photo asset names for a plant (exact-match only)
    /// - Parameter commonName: The plant's common name
    /// - Returns: Ordered list of asset names, or empty array if not available
    static func photoNames(for commonName: String) -> [String] {
        let normalized = commonName.lowercased().trimmingCharacters(in: .whitespaces)

        guard let baseKey = photoMap[normalized] else {
            return []
        }

        return photoAssetsByPlant[baseKey] ?? []
    }

    /// Check if a specific photo asset exists for a plant
    static func hasPhoto(for commonName: String) -> Bool {
        !photoNames(for: commonName).isEmpty
    }

    // MARK: - Available Photos

    /// List of all bundled photo asset names
    static let availablePhotos: [String] = photoAssetsByPlant.values.flatMap { $0 }.sorted()
}
