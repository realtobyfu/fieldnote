//
//  Plant+Mock.swift
//  Fieldnote
//
//  Mock plant data for development and previews
//

import Foundation

extension Plant {
    // MARK: - Mock Plants (8 botanically-accurate species)

    static let mockDandelion = Plant(
        commonName: "Common Dandelion",
        scientificName: "Taraxacum officinale",
        family: "Asteraceae",
        traits: ["Yellow flowers", "Deep taproot", "Rosette leaves", "Milky sap"],
        encounters: [
            Encounter.mockDandelion1,
            Encounter.mockDandelion2
        ]
    )

    static let mockClover = Plant(
        commonName: "White Clover",
        scientificName: "Trifolium repens",
        family: "Fabaceae",
        traits: ["Trifoliate leaves", "White flowers", "Creeping stems", "Nitrogen-fixing"],
        encounters: [
            Encounter.mockClover1,
            Encounter.mockClover2
        ]
    )

    static let mockCedar = Plant(
        commonName: "Eastern Red Cedar",
        scientificName: "Juniperus virginiana",
        family: "Cupressaceae",
        traits: ["Evergreen", "Scale-like leaves", "Blue berry-like cones", "Aromatic wood"],
        encounters: [
            Encounter.mockCedar1,
            Encounter.mockCedar2,
            Encounter.mockCedar3
        ]
    )

    static let mockViolet = Plant(
        commonName: "Common Blue Violet",
        scientificName: "Viola sororia",
        family: "Violaceae",
        traits: ["Purple flowers", "Heart-shaped leaves", "Low-growing", "Self-seeding"],
        encounters: [
            Encounter.mockViolet1,
            Encounter.mockViolet2
        ]
    )

    static let mockPoisonIvy = Plant(
        commonName: "Poison Ivy",
        scientificName: "Toxicodendron radicans",
        family: "Anacardiaceae",
        traits: ["Leaves of three", "Climbing vine", "White berries", "Causes severe rash"],
        encounters: [
            Encounter.mockPoisonIvy1,
            Encounter.mockPoisonIvy2
        ]
    )

    static let mockQueenAnne = Plant(
        commonName: "Queen Anne's Lace",
        scientificName: "Daucus carota",
        family: "Apiaceae",
        traits: ["White umbel flowers", "Carrot-scented root", "Hairy stems", "Dark center floret"],
        encounters: [
            Encounter.mockQueenAnne1,
            Encounter.mockQueenAnne2
        ]
    )

    static let mockMaple = Plant(
        commonName: "Red Maple",
        scientificName: "Acer rubrum",
        family: "Sapindaceae",
        traits: ["Opposite leaves", "Red twigs", "V-shaped leaf sinuses", "Brilliant fall color"],
        encounters: [
            Encounter.mockMaple1,
            Encounter.mockMaple2,
            Encounter.mockMaple3
        ]
    )

    static let mockMilkweed = Plant(
        commonName: "Common Milkweed",
        scientificName: "Asclepias syriaca",
        family: "Apocynaceae",
        traits: ["Pink flowers", "Milky sap", "Large pods", "Monarch butterfly host"],
        encounters: [
            Encounter.mockMilkweed1,
            Encounter.mockMilkweed2
        ]
    )

    // MARK: - Mock Plant Array

    static let mockPlants: [Plant] = [
        mockDandelion,
        mockClover,
        mockCedar,
        mockViolet,
        mockPoisonIvy,
        mockQueenAnne,
        mockMaple,
        mockMilkweed
    ]
}
