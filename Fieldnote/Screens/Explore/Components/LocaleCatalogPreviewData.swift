//
//  LocaleCatalogPreviewData.swift
//  Fieldnote
//
//  Sample locale-aware data for SwiftUI previews of the new Explore components.
//  DEBUG-only — never compiled into release.
//

#if DEBUG
import Foundation

enum LocaleCatalogPreviewData {
    /// A spread of ranked items with varied "Why this plant?" explanations.
    static let items: [LocalCatalogItem] = {
        let plants = Array(CatalogPlant.catalog.prefix(8))
        let codes: [[ExplanationCode]] = [
            [.nearbyNow(radiusKm: 25), .easyFirstFind],
            [.reportedThisMonth(monthName: "June"), .seasonalPeak(monthName: "June")],
            [.nearbyNow(radiusKm: 25)],
            [.reportedThisMonth(monthName: "June")],
            [.seasonalPeak(monthName: "June")],
            [.easyFirstFind],
            [.nearbyNow(radiusKm: 25), .seasonalPeak(monthName: "June")],
            [.reportedThisMonth(monthName: "June")]
        ]
        let counts = [1240, 360, 880, 45, 210, 670, 1530, 120]
        let maxCount = Double(counts.max() ?? 1)
        return plants.enumerated().map { index, plant in
            let count = counts[index % counts.count]
            return LocalCatalogItem(
                catalogPlant: plant,
                nearbyObservationCount: count,
                rankScore: Double(count) / maxCount,
                explanationCodes: codes[index % codes.count]
            )
        }
    }()

    /// Treat the first two sample plants as already discovered.
    static func isDiscovered(_ plant: CatalogPlant) -> Bool {
        items.prefix(2).contains { $0.catalogPlant.id == plant.id }
    }
}
#endif
