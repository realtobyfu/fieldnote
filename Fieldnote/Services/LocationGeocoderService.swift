//
//  LocationGeocoderService.swift
//  Fieldnote
//
//  Reverse geocoding helper for cached place names
//

import CoreLocation

@MainActor
final class LocationGeocoderService {
    static let shared = LocationGeocoderService()

    private let geocoder = CLGeocoder()

    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            return formattedName(from: placemark)
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
