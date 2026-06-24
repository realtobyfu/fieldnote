//
//  BadgeCatalog.swift
//  Fieldnote
//
//  Static badge definitions (Wave 2). Evaluated against a live stats snapshot by
//  GamificationService; unlock state lives in Achievement rows. Mirrors the
//  CatalogPlant.catalog pattern (bundled definitions, persisted user state).
//

import Foundation

enum BadgeCriterion {
    case totalFinds(Int)
    case uniqueSpecies(Int)
    case uniqueFamilies(Int)
    case uniqueLocations(Int)
    case collectionPercent(Int)
    case streak(Int)
    case seasonalFinds(season: String, count: Int)
}

struct BadgeDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let criterion: BadgeCriterion

    /// Numeric target used for progress display.
    var target: Int {
        switch criterion {
        case .totalFinds(let n), .uniqueSpecies(let n), .uniqueFamilies(let n),
             .uniqueLocations(let n), .collectionPercent(let n), .streak(let n):
            return n
        case .seasonalFinds(_, let n):
            return n
        }
    }
}

enum BadgeCatalog {
    static let all: [BadgeDefinition] = [
        .init(id: "first_find", title: "First Light", detail: "Log your first observation", symbol: "leaf.fill", criterion: .totalFinds(1)),
        .init(id: "ten_finds", title: "Field Notes", detail: "Log 10 observations", symbol: "books.vertical.fill", criterion: .totalFinds(10)),
        .init(id: "fifty_finds", title: "Dedicated Observer", detail: "Log 50 observations", symbol: "text.book.closed.fill", criterion: .totalFinds(50)),
        .init(id: "species_5", title: "Curious Eye", detail: "Discover 5 species", symbol: "sparkles", criterion: .uniqueSpecies(5)),
        .init(id: "species_25", title: "Naturalist", detail: "Discover 25 species", symbol: "leaf.circle.fill", criterion: .uniqueSpecies(25)),
        .init(id: "families_5", title: "Branching Out", detail: "Record 5 plant families", symbol: "tree.fill", criterion: .uniqueFamilies(5)),
        .init(id: "families_10", title: "Taxonomist", detail: "Record 10 plant families", symbol: "tree.circle.fill", criterion: .uniqueFamilies(10)),
        .init(id: "locations_3", title: "Wanderer", detail: "Observe at 3 locations", symbol: "mappin.and.ellipse", criterion: .uniqueLocations(3)),
        .init(id: "locations_10", title: "Cartographer", detail: "Observe at 10 locations", symbol: "map.fill", criterion: .uniqueLocations(10)),
        .init(id: "collection_25", title: "Collector", detail: "Discover 25% of the catalog", symbol: "circle.dotted", criterion: .collectionPercent(25)),
        .init(id: "collection_50", title: "Curator", detail: "Discover half the catalog", symbol: "circle.lefthalf.filled", criterion: .collectionPercent(50)),
        .init(id: "collection_100", title: "Completionist", detail: "Discover the entire catalog", symbol: "circle.fill", criterion: .collectionPercent(100)),
        .init(id: "streak_7", title: "Steadfast", detail: "A 7-day observation streak", symbol: "laurel.leading", criterion: .streak(7)),
        .init(id: "streak_30", title: "Devoted", detail: "A 30-day observation streak", symbol: "rosette", criterion: .streak(30)),
        .init(id: "winter_botanist", title: "Winter Botanist", detail: "Find 5 plants in winter", symbol: "snowflake", criterion: .seasonalFinds(season: "Winter", count: 5))
    ]
}
