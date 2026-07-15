//
//  LocationGeocoderService.swift
//  Fieldnote
//
//  Reverse geocoding helper for cached place names
//

import CoreLocation

/// A coarse reverse-geocode result: a friendly display name plus the fields used
/// to match the curated Explore regions.
struct GeocodedPlace {
    let displayName: String?
    /// State / province (`CLPlacemark.administrativeArea`).
    let administrativeArea: String?
    /// ISO country code (`CLPlacemark.isoCountryCode`), e.g. "US".
    let countryCode: String?
}

@MainActor
final class LocationGeocoderService {
    static let shared = LocationGeocoderService()

    private let geocoder = CLGeocoder()

    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String? {
        await reverseGeocodeDetailed(coordinate)?.displayName
    }

    /// Reverse-geocodes a coarse coordinate to a display name plus the state and
    /// country used for region auto-selection. Returns nil on geocoding failure.
    func reverseGeocodeDetailed(_ coordinate: CLLocationCoordinate2D) async -> GeocodedPlace? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            return GeocodedPlace(
                displayName: formattedName(from: placemark),
                administrativeArea: placemark.administrativeArea,
                countryCode: placemark.isoCountryCode
            )
        } catch {
            return nil
        }
    }

    private func formattedName(from placemark: CLPlacemark) -> String? {
        let name = placemark.name
        let locality = placemark.locality
        let region = placemark.administrativeArea

        var parts: [String] = []
        if let name, !name.isEmpty {
            parts.append(name)
        }
        if let locality, !locality.isEmpty {
            parts.append(locality)
        }
        if let region, !region.isEmpty {
            parts.append(region)
        }

        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
