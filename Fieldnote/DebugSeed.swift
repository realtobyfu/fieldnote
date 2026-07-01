//
//  DebugSeed.swift
//  Fieldnote
//
//  DEBUG-only sample data for previews/screenshots. Inert unless launched with
//  the env var SEED_SAMPLE_DATA=1 (and only if the library is empty).
//

#if DEBUG
import Foundation
import CoreLocation

@MainActor
enum DebugSeed {
    static func seedIfRequested(appStore: AppStore, gamification: GamificationService) {
        guard ProcessInfo.processInfo.environment["SEED_SAMPLE_DATA"] == "1" else { return }
        guard appStore.plants.isEmpty else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        func day(_ ago: Int) -> Date {
            (cal.date(byAdding: .day, value: -ago, to: today) ?? today).addingTimeInterval(9 * 3600)
        }

        struct Seed { let common: String; let sci: String; let family: String; let loc: String; let daysAgo: [Int] }
        let seeds: [Seed] = [
            .init(common: "Red Maple", sci: "Acer rubrum", family: "Sapindaceae", loc: "Riverside Park", daysAgo: [0, 4]),
            .init(common: "Goldenrod", sci: "Solidago canadensis", family: "Asteraceae", loc: "Lakeside Trail", daysAgo: [1, 3]),
            .init(common: "New England Aster", sci: "Symphyotrichum novae-angliae", family: "Asteraceae", loc: "Meadow Loop", daysAgo: [2, 6]),
            .init(common: "Eastern White Pine", sci: "Pinus strobus", family: "Pinaceae", loc: "Pine Ridge", daysAgo: [3]),
            .init(common: "Common Milkweed", sci: "Asclepias syriaca", family: "Apocynaceae", loc: "Meadow Loop", daysAgo: [4]),
            .init(common: "Black-eyed Susan", sci: "Rudbeckia hirta", family: "Asteraceae", loc: "Riverside Park", daysAgo: [5]),
            .init(common: "White Oak", sci: "Quercus alba", family: "Fagaceae", loc: "Pine Ridge", daysAgo: [6])
        ]

        for s in seeds {
            let plant = Plant(
                commonName: s.common, scientificName: s.sci, family: s.family,
                summary: "A lovely \(s.common.lowercased()) observed in the field.",
                traits: [], habitat: nil, nativeRange: nil
            )
            appStore.addPlant(plant)
            for d in s.daysAgo {
                let encounter = Encounter(
                    id: UUID(), date: day(d), locationName: s.loc, locationLabel: nil,
                    coordinates: nil, photoPlaceholder: "leaf.fill",
                    confidence: 0.75, notes: nil, conditions: [], photoFileName: nil
                )
                appStore.addEncounter(encounter, to: plant)
            }
        }

        gamification.reconcile()
    }
}
#endif
