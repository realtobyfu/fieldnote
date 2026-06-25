//
//  LocaleCatalogModelTests.swift
//  FieldnoteUnitTests
//
//  CatalogPlant join keys (A1) and LocalityProfile coarsening (A3).
//

import Testing
import Foundation
import CoreLocation
@testable import Fieldnote

@Suite("CatalogPlant locale join")
struct CatalogPlantJoinTests {

    private func plant(_ scientific: String, inatID: Int? = nil) -> CatalogPlant {
        CatalogPlant(
            commonName: "C",
            scientificName: scientific,
            family: "F",
            habitat: "h",
            traits: [],
            inaturalistTaxonID: inatID
        )
    }

    @Test("Scientific-name key strips authorship and subspecies to genus + species")
    func nameKeyReducesToBinomial() {
        #expect(CatalogPlant.scientificNameKey("Taraxacum officinale F.H.Wigg.") == "taraxacum officinale")
        #expect(CatalogPlant.scientificNameKey("Achillea millefolium L.") == "achillea millefolium")
        #expect(CatalogPlant.scientificNameKey("Quercus") == "quercus")
        #expect(CatalogPlant.scientificNameKey("  Rosa   canina  ") == "rosa canina")
    }

    @Test("Match prefers iNaturalist ID over name")
    func matchPrefersID() {
        let catalog = [
            plant("Aaa aaa", inatID: 100),
            plant("Bbb bbb", inatID: 200)
        ]
        // Name says "Aaa aaa" but ID 200 should win.
        let match = CatalogPlant.match(
            inaturalistTaxonID: 200,
            scientificName: "Aaa aaa",
            in: catalog
        )
        #expect(match?.scientificName == "Bbb bbb")
    }

    @Test("Match falls back to name key when ID is absent or unknown")
    func matchFallsBackToName() {
        let catalog = [plant("Achillea millefolium", inatID: nil)]
        let match = CatalogPlant.match(
            inaturalistTaxonID: nil,
            scientificName: "Achillea millefolium subsp. lanulosa",
            in: catalog
        )
        #expect(match?.scientificName == "Achillea millefolium")
    }

    @Test("No match returns nil")
    func noMatch() {
        let catalog = [plant("Achillea millefolium")]
        let match = CatalogPlant.match(
            inaturalistTaxonID: 999,
            scientificName: "Monotropa uniflora",
            in: catalog
        )
        #expect(match == nil)
    }

    @Test("New locale fields default to nil and don't disturb existing data")
    func optionalFieldsDefaultNil() {
        let p = plant("Rosa canina")
        #expect(p.gbifTaxonKey == nil)
        #expect(p.inaturalistTaxonID == nil)
        #expect(p.monthlyAffinity == nil)
    }
}

@Suite("LocalityProfile coarsening")
struct LocalityProfileTests {

    @Test("Snaps coordinates to the coarse grid")
    func snapsToGrid() {
        let precise = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let profile = LocalityProfile.make(from: precise)

        // 0.1-degree grid: 37.7749 -> 37.8, -122.4194 -> -122.4
        #expect(abs(profile.latitude - 37.8) < 0.0001)
        #expect(abs(profile.longitude - (-122.4)) < 0.0001)
        // The precise coordinate must not survive in the stored profile.
        #expect(profile.latitude != precise.latitude)
    }

    @Test("Derives hemisphere from latitude")
    func hemisphere() {
        let north = LocalityProfile.make(from: .init(latitude: 40, longitude: 0))
        let south = LocalityProfile.make(from: .init(latitude: -33, longitude: 151))
        #expect(north.hemisphere == .northern)
        #expect(south.hemisphere == .southern)
    }

    @Test("Cache key is the cell/region identity (annual counts, not month-keyed)")
    func cacheKeyIsCellIdentity() {
        var june = DateComponents()
        june.year = 2026; june.month = 6; june.day = 15
        let date = Calendar(identifier: .gregorian).date(from: june)!

        let profile = LocalityProfile.make(
            from: .init(latitude: 37.8, longitude: -122.4),
            now: date,
            calendar: Calendar(identifier: .gregorian)
        )
        #expect(profile.currentMonth == 6)
        #expect(profile.cacheKey == profile.coarseCellID)
    }

    @Test("Region cache key derives from sorted place IDs")
    func regionCacheKey() {
        let profile = LocalityProfile.makeRegion(name: "Pacific Northwest", placeIDs: [46, 10])
        #expect(profile.cacheKey == "place:10,46")
        #expect(profile.placeIDs == [10, 46])
    }

    @Test("Nearby coordinates collapse to the same cell")
    func nearbyCoordsShareCell() {
        let a = LocalityProfile.make(from: .init(latitude: 37.78, longitude: -122.41))
        let b = LocalityProfile.make(from: .init(latitude: 37.82, longitude: -122.43))
        #expect(a.coarseCellID == b.coarseCellID)
    }
}
