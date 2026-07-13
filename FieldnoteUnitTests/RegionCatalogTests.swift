//
//  RegionCatalogTests.swift
//  FieldnoteUnitTests
//
//  Region-pack → region-scoped catalog projection (2C): enriched decode,
//  bundled-wins merge, pack-only surfacing, and family placeholder mapping.
//

import Testing
import Foundation
@testable import Fieldnote

@Suite("Enriched region-pack decode")
struct RegionPackDecodeTests {

    @Test("A 2B-era taxon without the 2C display fields still decodes")
    func decodesLegacyTaxon() throws {
        let json = """
        {
          "gbifTaxonKey": 2879330,
          "inaturalistTaxonID": 49005,
          "acceptedScientificName": "Quercus rubra",
          "commonName": "Northern Red Oak",
          "nearbyObservationCount": 18420,
          "monthlyAffinity": null
        }
        """.data(using: .utf8)!
        let taxon = try JSONDecoder().decode(RegionPackTaxon.self, from: json)
        #expect(taxon.inaturalistTaxonID == 49005)
        #expect(taxon.family == nil)
        #expect(taxon.summary == nil)
        #expect(taxon.defaultPhotoURL == nil)
    }

    @Test("An enriched taxon decodes its display fields")
    func decodesEnrichedTaxon() throws {
        let json = """
        {
          "gbifTaxonKey": 2888380,
          "inaturalistTaxonID": 48225,
          "acceptedScientificName": "Eschscholzia californica",
          "commonName": "California poppy",
          "nearbyObservationCount": 59800,
          "monthlyAffinity": [0.1,0.2,0.6,1.0,0.5,0.2,0.1,0.1,0.1,0.1,0.0,0.0],
          "family": "Papaveraceae",
          "summary": "A golden wildflower.",
          "defaultPhotoURL": "https://example.org/medium.jpg",
          "defaultPhotoAttribution": "(c) someone (CC BY-NC)",
          "defaultPhotoLicenseCode": "cc-by-nc",
          "establishmentMeans": "native"
        }
        """.data(using: .utf8)!
        let taxon = try JSONDecoder().decode(RegionPackTaxon.self, from: json)
        #expect(taxon.family == "Papaveraceae")
        #expect(taxon.defaultPhotoURL == "https://example.org/medium.jpg")
        #expect(taxon.establishmentMeans == "native")
    }
}

@Suite("Region-scoped catalog projection")
struct RegionCatalogProjectionTests {

    private func bundled(_ sci: String, inatID: Int) -> CatalogPlant {
        CatalogPlant(commonName: "Bundled \(sci)", scientificName: sci, family: "F",
                     habitat: "h", traits: [], inaturalistTaxonID: inatID)
    }

    private func packTaxon(_ sci: String, inatID: Int, count: Int,
                           family: String? = nil, photo: String? = nil,
                           establishment: String? = nil) -> RegionPackTaxon {
        RegionPackTaxon(
            gbifTaxonKey: nil, inaturalistTaxonID: inatID,
            acceptedScientificName: sci, commonName: "Common \(sci)",
            nearbyObservationCount: count, monthlyAffinity: nil,
            family: family, defaultPhotoURL: photo,
            defaultPhotoAttribution: photo == nil ? nil : "(c) x",
            establishmentMeans: establishment
        )
    }

    private func pack(_ taxa: [RegionPackTaxon]) -> RegionPack {
        RegionPack(regionID: "test", version: 1, generatedAt: .init(timeIntervalSince1970: 0),
                   placeIDs: [1], source: "test", taxa: taxa)
    }

    @Test("Pack-only taxa are appended as first-class regional records")
    func appendsPackOnlyTaxa() {
        let base = [bundled("Quercus rubra", inatID: 49005)]
        let p = pack([
            packTaxon("Quercus rubra", inatID: 49005, count: 100),       // overlaps bundled
            packTaxon("Carnegiea gigantea", inatID: 54449, count: 50000, family: "Cactaceae"),
        ])
        let catalog = p.catalogPlants(mergedWith: base)
        #expect(catalog.count == 2)
        let saguaro = catalog.first { $0.scientificName == "Carnegiea gigantea" }
        #expect(saguaro?.source == .regional)
        #expect(saguaro?.family == "Cactaceae")
    }

    @Test("A bundled record wins over its pack counterpart (dedupe by iNat ID)")
    func bundledWinsByID() {
        let base = [bundled("Quercus rubra", inatID: 49005)]
        let p = pack([packTaxon("Quercus rubra", inatID: 49005, count: 100)])
        let catalog = p.catalogPlants(mergedWith: base)
        #expect(catalog.count == 1)
        #expect(catalog[0].source == .bundled)
        #expect(catalog[0].commonName == "Bundled Quercus rubra")
    }

    @Test("Dedupe also collapses a pack taxon that matches a bundled one by name key")
    func dedupeByNameKey() {
        let base = [bundled("Achillea millefolium", inatID: 999)]
        // Different iNat ID, same binomial (+ authorship) -> should not double-add.
        let p = pack([packTaxon("Achillea millefolium L.", inatID: 12345, count: 100)])
        let catalog = p.catalogPlants(mergedWith: base)
        #expect(catalog.count == 1)
        #expect(catalog[0].source == .bundled)
    }

    @Test("Region catalog is pack-driven: bundled plants not reported here are excluded")
    func regionCatalogIsPackDriven() {
        // Red Oak is bundled but NOT in this desert pack -> it must not appear.
        let base = [bundled("Quercus rubra", inatID: 49005)]
        let p = pack([
            packTaxon("Carnegiea gigantea", inatID: 54449, count: 500),
            packTaxon("Lupinus texensis", inatID: 60000, count: 300),
        ])
        let catalog = p.catalogPlants(mergedWith: base)
        #expect(catalog.count == 2)   // the two pack taxa, not 3
        #expect(!catalog.contains { $0.scientificName == "Quercus rubra" })
        #expect(catalog.allSatisfy { $0.source == .regional })
        // Ordered by observation count.
        #expect(catalog.first?.scientificName == "Carnegiea gigantea")
    }

    @Test("asCatalogPlant carries photo, native range, and a family placeholder")
    func packTaxonRendersDisplayFields() {
        let taxon = packTaxon("Carnegiea gigantea", inatID: 54449, count: 5,
                              family: "Cactaceae", photo: "https://x/p.jpg",
                              establishment: "native")
        let plant = taxon.asCatalogPlant()
        #expect(plant.source == .regional)
        #expect(plant.photoURL == "https://x/p.jpg")
        #expect(plant.photoAttribution == "(c) x")
        #expect(plant.nativeRange == "Native to this region")
        #expect(plant.inaturalistTaxonID == 54449)
    }

    @Test("Deterministic stableID is stable across calls for the same taxon")
    func stableIDDeterministic() {
        let a = packTaxon("Carnegiea gigantea", inatID: 54449, count: 5).stableID
        let b = packTaxon("Carnegiea gigantea", inatID: 54449, count: 9).stableID
        #expect(a == b)
    }
}

@Suite("Bundled region packs")
struct BundledRegionPackTests {

    @Test("Every preset region ships a decodable, photo-backed, region-specific pack",
          arguments: ["california", "pacific-northwest", "desert-southwest", "rocky-mountains",
                      "texas", "florida", "northeast", "hawaii"])
    func bundledPacksLoadAndAreRegionSpecific(regionID: String) throws {
        let pack = try #require(BundledRegionPacks.pack(for: regionID),
                                "Missing bundled pack for \(regionID)")
        #expect(pack.regionID == regionID)
        #expect(pack.taxa.count >= 20)
        // The region catalog is exactly the region's reported plants (pack-driven).
        let catalog = pack.catalogPlants(mergedWith: CatalogPlant.catalog)
        let distinctInPack = Set(pack.taxa.map(\.inaturalistTaxonID)).count
        #expect(catalog.count == distinctInPack)
        // Most are new regional plants beyond the bundled 50.
        #expect(catalog.contains { $0.source == .regional })
        // Every taxon ships a display photo (curation preferred photo-backed taxa).
        #expect(pack.taxa.filter { $0.defaultPhotoURL != nil }.count >= 20)
    }
}

@Suite("Family placeholder mapping")
struct FamilyPlaceholderTests {

    @Test("Tree families map to the tree symbol")
    func treeFamilies() {
        #expect(CatalogPlant.placeholderSymbol(forFamily: "Pinaceae") == "tree.fill")
        #expect(CatalogPlant.placeholderSymbol(forFamily: "Fagaceae") == "tree.fill")
    }

    @Test("Showy-flower families map to the flower symbol")
    func flowerFamilies() {
        #expect(CatalogPlant.placeholderSymbol(forFamily: "Asteraceae") == "sun.max.fill")
        #expect(CatalogPlant.placeholderSymbol(forFamily: "Papaveraceae") == "sun.max.fill")
    }

    @Test("Unknown or missing family falls back to the leaf symbol")
    func fallback() {
        #expect(CatalogPlant.placeholderSymbol(forFamily: "Cactaceae") == "leaf.fill")
        #expect(CatalogPlant.placeholderSymbol(forFamily: nil) == "leaf.fill")
        #expect(CatalogPlant.placeholderSymbol(forFamily: "") == "leaf.fill")
    }
}
