//
//  PlantType.swift
//  Fieldnote
//
//  A user-friendly plant grouping derived from family + name, used for the
//  Collection filter instead of raw botanical families (which are jargon).
//  Classification is heuristic — good enough for browsing, not taxonomy.
//

import Foundation

enum PlantType: String, CaseIterable, Identifiable {
    case trees = "Trees"
    case wildflowers = "Wildflowers"
    case shrubs = "Shrubs"
    case conifers = "Conifers"
    case grasses = "Grasses"
    case ferns = "Ferns"
    case fungi = "Fungi"
    case other = "Other"

    var id: String { rawValue }
    var label: String { rawValue }

    /// SF Symbol used for chips / section headers.
    var icon: String {
        switch self {
        case .trees: return "tree.fill"
        case .wildflowers: return "camera.macro"
        case .shrubs: return "leaf.fill"
        case .conifers: return "tree"
        case .grasses: return "scribble"
        case .ferns: return "leaf.fill"
        case .fungi: return "circle.hexagongrid.fill"
        case .other: return "leaf"
        }
    }
}

// MARK: - Classification

extension PlantType {
    /// Derives a plant type from the common/scientific name and botanical family.
    /// Name keywords are matched on whole words to avoid false hits
    /// (e.g. "Fireweed" must not read as "fir").
    static func classify(commonName: String, scientificName: String, family: String) -> PlantType {
        let words = Set(
            (commonName + " " + scientificName)
                .lowercased()
                .split(whereSeparator: { !$0.isLetter })
                .map(String.init)
        )
        let fam = family.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        func nameHas(_ candidates: Set<String>) -> Bool { !words.isDisjoint(with: candidates) }

        if nameHas(fungiWords) || fungiFamilies.contains(fam) { return .fungi }
        if nameHas(fernWords) || fernFamilies.contains(fam) { return .ferns }
        if nameHas(coniferWords) || coniferFamilies.contains(fam) { return .conifers }
        if nameHas(grassWords) || grassFamilies.contains(fam) { return .grasses }
        if nameHas(treeWords) || treeFamilies.contains(fam) { return .trees }
        if nameHas(shrubWords) || shrubFamilies.contains(fam) { return .shrubs }

        // A known family with no woody/grass/fern signal => herbaceous flowering plant.
        if !fam.isEmpty && fam != "unknown" { return .wildflowers }
        return .other
    }

    // MARK: Name keywords (whole-word matched)

    private static let fungiWords: Set<String> = ["mushroom", "fungus", "toadstool", "bolete", "amanita", "puffball", "morel", "chanterelle"]
    private static let fernWords: Set<String> = ["fern", "bracken", "horsetail"]
    private static let coniferWords: Set<String> = ["pine", "spruce", "cedar", "juniper", "cypress", "fir", "yew", "hemlock", "larch", "redwood", "sequoia", "arborvitae", "tamarack"]
    private static let grassWords: Set<String> = ["grass", "sedge", "rush", "reed", "bamboo", "cattail", "bluestem", "fescue"]
    private static let treeWords: Set<String> = ["tree", "oak", "maple", "birch", "elm", "willow", "poplar", "aspen", "beech", "ash", "walnut", "hickory", "sycamore", "chestnut", "linden", "basswood", "magnolia", "cottonwood", "hawthorn", "buckeye", "catalpa", "ginkgo", "sweetgum"]
    private static let shrubWords: Set<String> = ["shrub", "bush", "azalea", "rhododendron", "lilac", "hydrangea", "viburnum", "holly", "blueberry", "huckleberry", "bramble", "honeysuckle", "sumac", "dogwood", "elderberry", "barberry", "spirea", "rose"]

    // MARK: Family mappings

    private static let coniferFamilies: Set<String> = ["pinaceae", "cupressaceae", "taxaceae", "araucariaceae", "podocarpaceae", "sciadopityaceae", "cephalotaxaceae"]
    private static let fernFamilies: Set<String> = ["polypodiaceae", "dryopteridaceae", "pteridaceae", "osmundaceae", "aspleniaceae", "dennstaedtiaceae", "athyriaceae", "blechnaceae", "equisetaceae", "onocleaceae", "thelypteridaceae"]
    private static let grassFamilies: Set<String> = ["poaceae", "cyperaceae", "juncaceae", "typhaceae"]
    private static let treeFamilies: Set<String> = ["fagaceae", "betulaceae", "juglandaceae", "ulmaceae", "platanaceae", "magnoliaceae", "altingiaceae", "hamamelidaceae"]
    private static let shrubFamilies: Set<String> = ["ericaceae", "adoxaceae", "caprifoliaceae", "berberidaceae"]
    private static let fungiFamilies: Set<String> = ["agaricaceae", "amanitaceae", "boletaceae", "russulaceae", "polyporaceae", "tricholomataceae"]
}

// MARK: - Plant convenience

extension Plant {
    /// The user-facing plant type, derived from family + name.
    var plantType: PlantType {
        PlantType.classify(commonName: commonName, scientificName: scientificName, family: family)
    }
}
