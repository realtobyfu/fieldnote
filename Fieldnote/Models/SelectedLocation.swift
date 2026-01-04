//
//  SelectedLocation.swift
//  Fieldnote
//
//  Model for location picker selection
//

import Foundation
import CoreLocation

struct SelectedLocation: Identifiable, Equatable {
    let id: UUID
    let name: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D?
    let isCurrentLocation: Bool
    let lastUsed: Date?

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        isCurrentLocation: Bool = false,
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.isCurrentLocation = isCurrentLocation
        self.lastUsed = lastUsed
    }

    // MARK: - Distance Formatting

    func distanceString(from userLocation: CLLocationCoordinate2D?) -> String? {
        guard let userLocation = userLocation,
              let coordinate = coordinate else { return nil }

        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let locationCLLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distanceMeters = userCLLocation.distance(from: locationCLLocation)

        return Self.formatDistance(meters: distanceMeters)
    }

    static func formatDistance(meters: CLLocationDistance) -> String {
        let feet = meters * 3.28084
        let miles = meters / 1609.344

        if feet < 1000 {
            return "\(Int(feet)) ft"
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return "\(Int(miles)) mi"
        }
    }

    // MARK: - Equatable

    static func == (lhs: SelectedLocation, rhs: SelectedLocation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Factory Methods

extension SelectedLocation {
    /// Create from an Encounter's location data
    static func from(encounter: Encounter) -> SelectedLocation? {
        guard let name = encounter.displayLocationName else { return nil }

        return SelectedLocation(
            name: encounter.locationLabel ?? encounter.locationName ?? name,
            subtitle: encounter.locationName != nil && encounter.locationLabel != nil
                ? encounter.locationName
                : nil,
            coordinate: encounter.coordinates,
            lastUsed: encounter.date
        )
    }
}
