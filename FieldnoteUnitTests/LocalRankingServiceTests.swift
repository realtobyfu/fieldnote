//
//  LocalRankingServiceTests.swift
//  FieldnoteTests
//
//  Stage-1 ranking + identification reranking (A4/A5).
//

import Testing
import Foundation
@testable import Fieldnote

@Suite("LocalRankingService")
struct LocalRankingServiceTests {

    // MARK: - Helpers

    private func plant(
        _ common: String,
        scientific: String,
        inatID: Int? = nil,
        monthly: [Double]? = nil
    ) -> CatalogPlant {
        CatalogPlant(
            commonName: common,
            scientificName: scientific,
            family: "TestFamily",
            habitat: "test",
            traits: [],
            inaturalistTaxonID: inatID,
            monthlyAffinity: monthly
        )
    }

    private func count(
        taxonID: Int,
        scientific: String,
        count: Int
    ) -> INatSpeciesCount {
        INatSpeciesCount(
            taxonID: taxonID,
            scientificName: scientific,
            commonName: nil,
            count: count,
            defaultPhotoURL: nil,
            defaultPhotoLicense: nil
        )
    }

    // MARK: - Matching

    @Test("Joins counts to catalog by iNaturalist taxon ID")
    func matchesByTaxonID() {
        let catalog = [plant("Dandelion", scientific: "Taraxacum officinale", inatID: 47602)]
        // Different name spelling, but the taxon ID matches.
        let counts = [count(taxonID: 47602, scientific: "Taraxacum erythrospermum", count: 10)]

        let ranked = LocalRankingService().rank(catalog: catalog, counts: counts, month: 6)

        #expect(ranked.count == 1)
        #expect(ranked.first?.catalogPlant.commonName == "Dandelion")
        #expect(ranked.first?.nearbyObservationCount == 10)
    }

    @Test("Falls back to scientific-name key when no ID is present")
    func matchesByNameKey() {
        let catalog = [plant("Yarrow", scientific: "Achillea millefolium")]
        // Authorship suffix should not block the join.
        let counts = [count(taxonID: 1, scientific: "Achillea millefolium L.", count: 5)]

        let ranked = LocalRankingService().rank(catalog: catalog, counts: counts, month: 6)

        #expect(ranked.count == 1)
        #expect(ranked.first?.catalogPlant.commonName == "Yarrow")
    }

    @Test("Drops catalog entries with no local match")
    func dropsUnmatched() {
        let catalog = [
            plant("Yarrow", scientific: "Achillea millefolium"),
            plant("Ghost Plant", scientific: "Monotropa uniflora")
        ]
        let counts = [count(taxonID: 1, scientific: "Achillea millefolium", count: 5)]

        let ranked = LocalRankingService().rank(catalog: catalog, counts: counts, month: 6)

        #expect(ranked.map(\.catalogPlant.commonName) == ["Yarrow"])
    }

    @Test("Empty counts yields no items")
    func emptyCounts() {
        let catalog = [plant("Yarrow", scientific: "Achillea millefolium")]
        let ranked = LocalRankingService().rank(catalog: catalog, counts: [], month: 6)
        #expect(ranked.isEmpty)
    }

    // MARK: - Scoring

    @Test("Higher occurrence ranks ahead of lower occurrence")
    func higherOccurrenceRanksFirst() {
        let catalog = [
            plant("Common", scientific: "Aaa aaa"),
            plant("Rare", scientific: "Bbb bbb")
        ]
        let counts = [
            count(taxonID: 1, scientific: "Aaa aaa", count: 1000),
            count(taxonID: 2, scientific: "Bbb bbb", count: 2)
        ]

        let ranked = LocalRankingService().rank(catalog: catalog, counts: counts, month: 6)

        #expect(ranked.first?.catalogPlant.commonName == "Common")
        #expect(ranked.last?.catalogPlant.commonName == "Rare")
    }

    @Test("Occurrence is log-scaled so a huge weed doesn't swamp a strong-seasonal plant")
    func logScalingTempersWeeds() {
        // June-peaking plant with modest counts vs. a year-round weed with massive counts.
        var juneAffinity = Array(repeating: 0.1, count: 12)
        juneAffinity[5] = 1.0  // June

        let catalog = [
            plant("Weed", scientific: "Aaa aaa"),
            plant("JuneBloom", scientific: "Bbb bbb", monthly: juneAffinity)
        ]
        let counts = [
            count(taxonID: 1, scientific: "Aaa aaa", count: 100_000),
            count(taxonID: 2, scientific: "Bbb bbb", count: 300)
        ]

        let ranked = LocalRankingService().rank(catalog: catalog, counts: counts, month: 6)
        let weed = try? #require(ranked.first { $0.catalogPlant.commonName == "Weed" })
        let bloom = try? #require(ranked.first { $0.catalogPlant.commonName == "JuneBloom" })

        // The weed still leads, but the seasonal plant stays competitive rather than
        // being buried — its score should be a meaningful fraction of the weed's.
        if let weed, let bloom {
            #expect(bloom.rankScore > weed.rankScore * 0.5)
        }
    }

    @Test("Scores are bounded in 0...1")
    func scoresBounded() {
        let catalog = [plant("X", scientific: "Aaa aaa")]
        let counts = [count(taxonID: 1, scientific: "Aaa aaa", count: 50)]
        let ranked = LocalRankingService().rank(catalog: catalog, counts: counts, month: 6)
        let score = ranked.first?.rankScore ?? -1
        #expect(score >= 0 && score <= 1)
    }

    // MARK: - Explanations

    @Test("Strong occurrence yields commonlyReported + easyFirstFind copy")
    func strongOccurrenceExplanations() {
        let catalog = [
            plant("Top", scientific: "Aaa aaa"),
            plant("Low", scientific: "Bbb bbb")
        ]
        let counts = [
            count(taxonID: 1, scientific: "Aaa aaa", count: 1000),
            count(taxonID: 2, scientific: "Bbb bbb", count: 1)
        ]

        let ranked = LocalRankingService().rank(catalog: catalog, counts: counts, month: 6)
        let top = try? #require(ranked.first { $0.catalogPlant.commonName == "Top" })

        if let top {
            #expect(top.explanationCodes.contains(.commonlyReported))
            #expect(top.explanationCodes.contains(.easyFirstFind))
        }
    }

    @Test("Weak occurrence uses alsoReported copy, not commonlyReported")
    func weakOccurrenceExplanations() {
        let catalog = [
            plant("Top", scientific: "Aaa aaa"),
            plant("Low", scientific: "Bbb bbb")
        ]
        let counts = [
            count(taxonID: 1, scientific: "Aaa aaa", count: 1000),
            count(taxonID: 2, scientific: "Bbb bbb", count: 1)
        ]

        let ranked = LocalRankingService().rank(catalog: catalog, counts: counts, month: 6)
        let low = try? #require(ranked.first { $0.catalogPlant.commonName == "Low" })

        if let low {
            #expect(low.explanationCodes.contains(.alsoReported))
            #expect(!low.explanationCodes.contains(.commonlyReported))
        }
    }

    @Test("Seasonal peak code appears in the plant's peak month only")
    func seasonalPeakExplanation() {
        var juneAffinity = Array(repeating: 0.1, count: 12)
        juneAffinity[5] = 1.0

        let catalog = [plant("JuneBloom", scientific: "Aaa aaa", monthly: juneAffinity)]
        let counts = [count(taxonID: 1, scientific: "Aaa aaa", count: 50)]

        let june = LocalRankingService().rank(catalog: catalog, counts: counts, month: 6)
        let january = LocalRankingService().rank(catalog: catalog, counts: counts, month: 1)

        #expect(june.first?.explanationCodes.contains(.seasonalPeak(monthName: "June")) == true)
        #expect(january.first?.explanationCodes.contains(.seasonalPeak(monthName: "January")) == false)
    }

    // MARK: - Reranking

    @Test("Local support boosts a candidate but visual signal stays dominant")
    func rerankKeepsVisualDominant() {
        let local = plant("LocalCommon", scientific: "Bbb bbb")
        let counts = [count(taxonID: 1, scientific: "Bbb bbb", count: 1000)]
        let localItems = LocalRankingService().rank(catalog: [local], counts: counts, month: 6)

        // Strong visual match with no local support vs. weak visual match that IS local.
        let strongVisual = PlantIdentificationCandidate(
            commonName: "StrongVisual", scientificName: "Aaa aaa",
            family: "F", visualConfidence: 0.9, gbifTaxonKey: nil
        )
        let weakLocal = PlantIdentificationCandidate(
            commonName: "LocalCommon", scientificName: "Bbb bbb",
            family: "F", visualConfidence: 0.5, gbifTaxonKey: nil
        )

        let ranked = LocalRankingService().rerankCandidates(
            [strongVisual, weakLocal], localItems: localItems, month: 6
        )

        // The 0.9 visual match must not be overtaken by a 0.5 local match — the
        // bounded prior can't rescue a much weaker visual candidate.
        #expect(ranked.first?.candidate.scientificName == "Aaa aaa")
        // The local candidate is flagged as locally supported.
        let localRanked = ranked.first { $0.candidate.scientificName == "Bbb bbb" }
        #expect(localRanked?.hasLocalSupport == true)
        #expect(localRanked?.nearbyObservationCount == 1000)
    }

    @Test("Local support breaks ties between equal visual matches")
    func rerankBreaksTiesByLocal() {
        let local = plant("LocalCommon", scientific: "Bbb bbb")
        let counts = [count(taxonID: 1, scientific: "Bbb bbb", count: 1000)]
        let localItems = LocalRankingService().rank(catalog: [local], counts: counts, month: 6)

        let noSupport = PlantIdentificationCandidate(
            commonName: "Elsewhere", scientificName: "Aaa aaa",
            family: "F", visualConfidence: 0.8, gbifTaxonKey: nil
        )
        let supported = PlantIdentificationCandidate(
            commonName: "LocalCommon", scientificName: "Bbb bbb",
            family: "F", visualConfidence: 0.8, gbifTaxonKey: nil
        )

        let ranked = LocalRankingService().rerankCandidates(
            [noSupport, supported], localItems: localItems, month: 6
        )

        #expect(ranked.first?.candidate.scientificName == "Bbb bbb")
    }
}
