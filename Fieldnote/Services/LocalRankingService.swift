//
//  LocalRankingService.swift
//  Fieldnote
//
//  Stage-1 ecological ranking: turns iNaturalist species counts + the bundled
//  catalog into ranked, explainable local items. Pure and synchronous so it is
//  trivially unit-testable. The personal/editorial Stage-2 model is deferred to
//  Milestone 2. See LocaleAwareCatalogImplementationPlan.md.
//

import Foundation

// MARK: - Explanation Codes

/// Drives the user-facing "Why this plant?" copy. Wording avoids abundance
/// claims — we say "reported nearby," not "abundant."
enum ExplanationCode: Codable, Hashable {
    /// Strongly represented in the region's research-grade observations.
    case commonlyReported
    /// Present in the region, but less frequently reported.
    case alsoReported
    /// Seasonal affinity peaks around this month (only when we have that data).
    case seasonalPeak(monthName: String)
    /// High occurrence + recognizable — a good first find.
    case easyFirstFind

    var label: String {
        switch self {
        case .commonlyReported:
            return "Commonly reported in this region"
        case .alsoReported:
            return "Also reported in this region"
        case .seasonalPeak(let monthName):
            return "Often active around \(monthName)"
        case .easyFirstFind:
            return "A good first find"
        }
    }
}

// MARK: - Ranked Item

/// A catalog entry positioned for a specific locality + month, with the
/// evidence the UI needs to explain its placement.
struct LocalCatalogItem: Identifiable, Hashable {
    let catalogPlant: CatalogPlant
    let nearbyObservationCount: Int
    /// Stage-1 ecological score in 0...1.
    let rankScore: Double
    let explanationCodes: [ExplanationCode]

    var id: UUID { catalogPlant.id }
}

/// An identification candidate after local + seasonal reranking.
struct RankedCandidate: Identifiable, Hashable {
    let candidate: PlantIdentificationCandidate
    /// Visual confidence after the bounded local/seasonal adjustment.
    let combinedScore: Double
    /// Whether this taxon is also reported in the current locality.
    let hasLocalSupport: Bool
    let nearbyObservationCount: Int

    var id: String { candidate.scientificName }
}

// MARK: - Service

struct LocalRankingService {

    /// Weights for the signals available client-side in Milestone 1. The
    /// research model also reserves weight for recency, habitat, and climate
    /// fit — those are deferred, so we renormalize across the two we have.
    private let occurrenceWeight = 0.6
    private let seasonalWeight = 0.4

    /// Fraction of the (log-scaled) occurrence range above which an item is
    /// considered a confident "near you now" / "easy first find".
    private let strongOccurrenceThreshold = 0.66

    init() {}

    /// Ranks the catalog against nearby species counts for a month.
    ///
    /// - Parameters:
    ///   - catalog: The bundled catalog entries.
    ///   - counts: iNaturalist species counts for the locality + month.
    ///   - month: Calendar month 1...12 used for seasonal copy.
    /// - Returns: Items with a local match, sorted by `rankScore` descending.
    func rank(
        catalog: [CatalogPlant],
        counts: [INatSpeciesCount],
        month: Int
    ) -> [LocalCatalogItem] {
        guard !counts.isEmpty else { return [] }

        // Lookup tables for joining counts to catalog entries.
        let countsByTaxonID = Dictionary(
            counts.map { ($0.taxonID, $0) },
            uniquingKeysWith: { a, b in a.count >= b.count ? a : b }
        )
        let countsByNameKey = Dictionary(
            counts.map { (CatalogPlant.scientificNameKey($0.scientificName), $0) },
            uniquingKeysWith: { a, b in a.count >= b.count ? a : b }
        )

        // Log-scale occurrence so highly reported urban weeds don't dominate.
        let maxLogCount = counts.map { log1p(Double($0.count)) }.max() ?? 1
        let monthName = Self.monthName(month)

        var items: [LocalCatalogItem] = []
        for plant in catalog {
            guard let match = matchedCount(
                for: plant,
                byID: countsByTaxonID,
                byName: countsByNameKey
            ) else { continue }

            let occurrenceScore = maxLogCount > 0
                ? log1p(Double(match.count)) / maxLogCount
                : 0

            let seasonalScore = Self.seasonalScore(for: plant, month: month)

            let rankScore = occurrenceWeight * occurrenceScore
                + seasonalWeight * seasonalScore

            let codes = explanationCodes(
                plant: plant,
                occurrenceScore: occurrenceScore,
                month: month,
                monthName: monthName
            )

            items.append(LocalCatalogItem(
                catalogPlant: plant,
                nearbyObservationCount: match.count,
                rankScore: rankScore,
                explanationCodes: codes
            ))
        }

        return items.sorted { lhs, rhs in
            if lhs.rankScore != rhs.rankScore {
                return lhs.rankScore > rhs.rankScore
            }
            return lhs.nearbyObservationCount > rhs.nearbyObservationCount
        }
    }

    // MARK: - Identification Reranking

    /// How much local support and seasonality may nudge a candidate, as a
    /// fraction. Kept small so the visual signal stays dominant: a locally
    /// common plant should not rescue a morphologically implausible match.
    private let maxLocalBoost = 0.3
    private let maxSeasonalBoost = 0.2

    /// Reranks visual identification candidates using the local + seasonal prior.
    /// `combinedScore = visualConfidence × localPrior × seasonalPrior`, with the
    /// priors bounded near 1 so visual likelihood dominates (research §291).
    func rerankCandidates(
        _ candidates: [PlantIdentificationCandidate],
        localItems: [LocalCatalogItem],
        month: Int
    ) -> [RankedCandidate] {
        let itemsByKey = Dictionary(
            localItems.map { (CatalogPlant.scientificNameKey($0.catalogPlant.scientificName), $0) },
            uniquingKeysWith: { a, _ in a }
        )

        let ranked = candidates.map { candidate -> RankedCandidate in
            let key = CatalogPlant.scientificNameKey(candidate.scientificName)
            let local = itemsByKey[key]

            let localPrior = 1.0 + (local?.rankScore ?? 0) * maxLocalBoost

            let seasonal = local.map {
                Self.seasonalScore(for: $0.catalogPlant, month: month)
            } ?? 0.5
            // Centered at the neutral 0.5 so missing data neither helps nor hurts.
            let seasonalPrior = 1.0 + (seasonal - 0.5) * maxSeasonalBoost

            let combined = candidate.visualConfidence * localPrior * seasonalPrior

            return RankedCandidate(
                candidate: candidate,
                combinedScore: combined,
                hasLocalSupport: local != nil,
                nearbyObservationCount: local?.nearbyObservationCount ?? 0
            )
        }

        return ranked.sorted { $0.combinedScore > $1.combinedScore }
    }

    // MARK: - Matching

    private func matchedCount(
        for plant: CatalogPlant,
        byID: [Int: INatSpeciesCount],
        byName: [String: INatSpeciesCount]
    ) -> INatSpeciesCount? {
        if let id = plant.inaturalistTaxonID, let hit = byID[id] {
            return hit
        }
        return byName[plant.scientificNameKey]
    }

    // MARK: - Seasonality

    /// Returns the plant's affinity for `month` (0...1). Neutral 0.5 when no
    /// seasonal data exists yet, so absence of data never penalizes a plant.
    static func seasonalScore(for plant: CatalogPlant, month: Int) -> Double {
        guard let affinity = plant.monthlyAffinity,
              affinity.count == 12,
              (1...12).contains(month) else {
            return 0.5
        }
        return affinity[month - 1]
    }

    // MARK: - Explanations

    private func explanationCodes(
        plant: CatalogPlant,
        occurrenceScore: Double,
        month: Int,
        monthName: String
    ) -> [ExplanationCode] {
        var codes: [ExplanationCode] = []

        if occurrenceScore >= strongOccurrenceThreshold {
            codes.append(.commonlyReported)
        } else {
            codes.append(.alsoReported)
        }

        if let affinity = plant.monthlyAffinity,
           affinity.count == 12,
           let peak = affinity.max(),
           peak > 0,
           affinity[month - 1] >= peak * 0.85 {
            codes.append(.seasonalPeak(monthName: monthName))
        }

        if occurrenceScore >= strongOccurrenceThreshold {
            codes.append(.easyFirstFind)
        }

        return codes
    }

    // MARK: - Helpers

    static func monthName(_ month: Int) -> String {
        guard (1...12).contains(month) else { return "" }
        let formatter = DateFormatter()
        return formatter.standaloneMonthSymbols[month - 1]
    }
}
