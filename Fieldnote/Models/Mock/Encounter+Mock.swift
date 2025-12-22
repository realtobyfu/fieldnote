//
//  Encounter+Mock.swift
//  Fieldnote
//
//  Mock encounter data for development and previews
//

import Foundation
import CoreLocation

extension Encounter {
    // MARK: - Mock Encounters

    static let mockDandelion1 = Encounter(
        date: Date().addingTimeInterval(-86400 * 5), // 5 days ago
        locationName: "Central Park, New York",
        coordinates: CLLocationCoordinate2D(latitude: 40.785091, longitude: -73.968285),
        photoPlaceholder: "sun.max.fill",
        confidence: 0.92,
        notes: "Large patch blooming in sunny meadow. Dozens of plants with bright yellow flowers.",
        conditions: ["sun", "dry"]
    )

    static let mockDandelion2 = Encounter(
        date: Date().addingTimeInterval(-86400 * 45), // 45 days ago
        locationName: "Backyard Garden",
        photoPlaceholder: "cloud.fill",
        confidence: 0.88,
        notes: "Found growing through cracks in patio. Classic rosette formation.",
        conditions: ["shade", "wet"]
    )

    static let mockClover1 = Encounter(
        date: Date().addingTimeInterval(-86400 * 2), // 2 days ago
        locationName: "Riverside Trail",
        coordinates: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        photoPlaceholder: "leaf.fill",
        confidence: 0.95,
        notes: "Dense ground cover. White flowers with characteristic V-markings on leaves.",
        conditions: ["sun", "wet"]
    )

    static let mockClover2 = Encounter(
        date: Date().addingTimeInterval(-86400 * 20), // 20 days ago
        locationName: "Front Lawn",
        photoPlaceholder: "leaf.fill",
        confidence: 0.90,
        conditions: ["sun", "dry"]
    )

    static let mockCedar1 = Encounter(
        date: Date().addingTimeInterval(-86400 * 10), // 10 days ago
        locationName: "Forest Edge Trail",
        photoPlaceholder: "tree.fill",
        confidence: 0.75,
        notes: "Young tree, approximately 15 feet tall. Scale-like leaves confirm juniper family.",
        conditions: ["sun", "windy"]
    )

    static let mockCedar2 = Encounter(
        date: Date().addingTimeInterval(-86400 * 60), // 60 days ago
        locationName: "Old Field",
        photoPlaceholder: "tree.fill",
        confidence: 0.68,
        notes: "Blue berry-like cones present but no flowers. Bark is reddish-brown and fibrous.",
        conditions: ["sun", "cold"]
    )

    static let mockCedar3 = Encounter(
        date: Date().addingTimeInterval(-86400 * 120), // 120 days ago
        locationName: "Abandoned Farm",
        photoPlaceholder: "tree.fill",
        confidence: 0.70,
        conditions: ["sun", "windy", "dry"]
    )

    static let mockViolet1 = Encounter(
        date: Date().addingTimeInterval(-86400 * 7), // 7 days ago
        locationName: "Woodland Path",
        photoPlaceholder: "camera.fill",
        confidence: 0.93,
        notes: "Growing in shaded area under oak trees. Purple five-petaled flowers, heart-shaped leaves.",
        conditions: ["shade", "wet"]
    )

    static let mockViolet2 = Encounter(
        date: Date().addingTimeInterval(-86400 * 35), // 35 days ago
        locationName: "Side Yard",
        photoPlaceholder: "camera.fill",
        confidence: 0.87,
        conditions: ["shade"]
    )

    static let mockPoisonIvy1 = Encounter(
        date: Date().addingTimeInterval(-86400 * 3), // 3 days ago
        locationName: "Forest Trail",
        coordinates: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851),
        photoPlaceholder: "exclamationmark.triangle.fill",
        confidence: 0.98,
        notes: "CAUTION: Confirmed poison ivy. Leaves of three, middle leaflet on longer stem. Avoided contact.",
        conditions: ["shade", "wet"]
    )

    static let mockPoisonIvy2 = Encounter(
        date: Date().addingTimeInterval(-86400 * 50), // 50 days ago
        locationName: "Woodland Edge",
        photoPlaceholder: "exclamationmark.triangle.fill",
        confidence: 0.95,
        notes: "Climbing on tree trunk with aerial rootlets. White berries present.",
        conditions: ["shade"]
    )

    static let mockQueenAnne1 = Encounter(
        date: Date().addingTimeInterval(-86400 * 12), // 12 days ago
        locationName: "Roadside Meadow",
        photoPlaceholder: "circle.grid.cross.fill",
        confidence: 0.78,
        notes: "White umbel flowers with distinctive dark purple center floret. Carrot-scented root.",
        conditions: ["sun", "hot", "dry"]
    )

    static let mockQueenAnne2 = Encounter(
        date: Date().addingTimeInterval(-86400 * 55), // 55 days ago
        locationName: "Highway Shoulder",
        photoPlaceholder: "circle.grid.cross.fill",
        confidence: 0.65,
        notes: "Flowers past peak bloom. Hairy stems noted.",
        conditions: ["sun", "windy"]
    )

    static let mockMaple1 = Encounter(
        date: Date().addingTimeInterval(-86400 * 8), // 8 days ago
        locationName: "City Park",
        photoPlaceholder: "leaf.fill",
        confidence: 0.90,
        notes: "Large mature tree. Opposite leaf arrangement, V-shaped sinuses between lobes.",
        conditions: ["sun"]
    )

    static let mockMaple2 = Encounter(
        date: Date().addingTimeInterval(-86400 * 25), // 25 days ago
        locationName: "Wetland Trail",
        photoPlaceholder: "leaf.fill",
        confidence: 0.85,
        notes: "Red twigs visible. Growing in wet soil near stream.",
        conditions: ["shade", "wet"]
    )

    static let mockMaple3 = Encounter(
        date: Date().addingTimeInterval(-86400 * 90), // 90 days ago (winter)
        locationName: "Neighborhood Street",
        photoPlaceholder: "snowflake",
        confidence: 0.75,
        notes: "Winter identification - red buds and opposite branching pattern visible.",
        conditions: ["cold", "snow"]
    )

    static let mockMilkweed1 = Encounter(
        date: Date().addingTimeInterval(-86400 * 15), // 15 days ago
        locationName: "Prairie Restoration",
        photoPlaceholder: "allergens.fill",
        confidence: 0.82,
        notes: "Pink flower clusters fragrant. Milky sap confirmed when stem broken. Important for monarchs!",
        conditions: ["sun", "hot"]
    )

    static let mockMilkweed2 = Encounter(
        date: Date().addingTimeInterval(-86400 * 40), // 40 days ago
        locationName: "Field Edge",
        photoPlaceholder: "allergens.fill",
        confidence: 0.73,
        notes: "Large opposite leaves. Seed pods forming.",
        conditions: ["sun", "dry"]
    )
}
