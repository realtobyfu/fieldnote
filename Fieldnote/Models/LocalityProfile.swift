//
//  LocalityProfile.swift
//  Fieldnote
//
//  A coarse, privacy-preserving description of "where + when" used to fetch and
//  rank a locale-aware catalog. We deliberately round coordinates to a grid cell
//  so precise encounter coordinates never leave the device.
//  See LocaleAwareCatalogImplementationPlan.md.
//

import Foundation
import CoreLocation

struct LocalityProfile: Codable, Hashable {
    /// Grid resolution in degrees. ~0.1° ≈ 11 km at the equator — coarse enough
    /// to avoid pinpointing the user while still being locally meaningful.
    static let cellSizeDegrees = 0.1

    /// Stable identifier for the rounded grid cell, e.g. "37.8,-122.4".
    let coarseCellID: String
    /// Cell-center latitude (rounded). Safe to send to iNaturalist.
    let latitude: Double
    /// Cell-center longitude (rounded). Safe to send to iNaturalist.
    let longitude: Double
    /// Optional human-readable region for display, e.g. "San Francisco Bay".
    var displayRegion: String?
    /// ISO country code when known.
    var countryCode: String?
    /// Northern/southern hemisphere — drives seasonal interpretation.
    let hemisphere: Hemisphere
    /// Calendar month 1...12 the profile was generated for.
    let currentMonth: Int
    /// When this profile was created.
    let generatedAt: Date
    /// iNaturalist place IDs when this profile represents a named region rather
    /// than a coarse GPS cell. `nil` for current-location profiles.
    var placeIDs: [Int]? = nil

    enum Hemisphere: String, Codable {
        case northern
        case southern
    }

    /// The coarse cell center as a coordinate, suitable for an iNaturalist query.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension LocalityProfile {
    /// Builds a profile by snapping a precise coordinate to the coarse grid.
    /// The precise coordinate is consumed here and never stored.
    static func make(
        from coordinate: CLLocationCoordinate2D,
        displayRegion: String? = nil,
        countryCode: String? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> LocalityProfile {
        let cell = Self.cellSizeDegrees
        let lat = (coordinate.latitude / cell).rounded() * cell
        let lng = (coordinate.longitude / cell).rounded() * cell
        let id = String(format: "%.1f,%.1f", lat, lng)
        let month = calendar.component(.month, from: now)

        return LocalityProfile(
            coarseCellID: id,
            latitude: lat,
            longitude: lng,
            displayRegion: displayRegion,
            countryCode: countryCode,
            hemisphere: lat >= 0 ? .northern : .southern,
            currentMonth: month,
            generatedAt: now
        )
    }

    /// Builds a profile for a named region defined by iNaturalist place IDs
    /// (e.g. a macro-region = the union of its states). No GPS coordinate is
    /// involved; the cell ID is derived from the place IDs so it caches cleanly.
    static func makeRegion(
        name: String,
        placeIDs: [Int],
        hemisphere: Hemisphere = .northern,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> LocalityProfile {
        let sorted = placeIDs.sorted()
        let id = "place:" + sorted.map(String.init).joined(separator: ",")
        return LocalityProfile(
            coarseCellID: id,
            latitude: 0,
            longitude: 0,
            displayRegion: name,
            countryCode: nil,
            hemisphere: hemisphere,
            currentMonth: calendar.component(.month, from: now),
            generatedAt: now,
            placeIDs: sorted
        )
    }

    /// Cache key combining cell + month, since seasonality is month-specific.
    var cacheKey: String { "\(coarseCellID)@\(currentMonth)" }
}
