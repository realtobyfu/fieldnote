//
//  Encounter.swift
//  Fieldnote
//
//  Per-sighting observation model
//

import Foundation
import CoreLocation

struct Encounter: Identifiable, Codable {
    let id: UUID
    let date: Date
    let locationName: String?
    let coordinates: CLLocationCoordinate2D?
    let photoPlaceholder: String  // SF Symbol name for colored placeholder
    let confidence: Double  // 0.0...1.0
    let notes: String?
    let conditions: [String]  // e.g., ["sun", "wet", "windy"]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        locationName: String? = nil,
        coordinates: CLLocationCoordinate2D? = nil,
        photoPlaceholder: String = "leaf.fill",
        confidence: Double,
        notes: String? = nil,
        conditions: [String] = []
    ) {
        self.id = id
        self.date = date
        self.locationName = locationName
        self.coordinates = coordinates
        self.photoPlaceholder = photoPlaceholder
        self.confidence = confidence
        self.notes = notes
        self.conditions = conditions
    }
}

// MARK: - CLLocationCoordinate2D Codable Extension

// Note: This extension adds Codable conformance to CLLocationCoordinate2D
// If future iOS versions add native Codable support, this can be removed
extension CLLocationCoordinate2D: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
}
