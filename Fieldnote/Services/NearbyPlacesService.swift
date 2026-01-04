//
//  NearbyPlacesService.swift
//  Fieldnote
//
//  Service for searching and fetching nearby places using MapKit
//

import Foundation
import MapKit
import CoreLocation

@MainActor
final class NearbyPlacesService {
    static let shared = NearbyPlacesService()

    private init() {}

    // MARK: - Search for Places

    /// Search for places matching a query string
    func search(query: String, near coordinate: CLLocationCoordinate2D?) async -> [SelectedLocation] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let coordinate = coordinate {
            // Search within ~50km of user location
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
            request.region = region
        }

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()

            return response.mapItems.compactMap { item -> SelectedLocation? in
                guard let name = item.name else { return nil }

                let subtitle = [
                    item.placemark.locality,
                    item.placemark.administrativeArea
                ].compactMap { $0 }.joined(separator: ", ")

                return SelectedLocation(
                    name: name,
                    subtitle: subtitle.isEmpty ? nil : subtitle,
                    coordinate: item.placemark.coordinate
                )
            }
        } catch {
            print("Search failed: \(error)")
            return []
        }
    }

    // MARK: - Fetch Nearby Places

    /// Get interesting nearby places (parks, nature areas, landmarks)
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) async -> [SelectedLocation] {
        let categories: [MKPointOfInterestCategory] = [
            .park,
            .nationalPark,
            .beach,
            .campground,
            .marina,
            .zoo,
            .museum,
            .library,
            .school,
            .university
        ]

        var allPlaces: [SelectedLocation] = []

        // Search for natural/outdoor places
        let naturalQuery = MKLocalSearch.Request()
        naturalQuery.naturalLanguageQuery = "park nature trail garden"
        naturalQuery.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        naturalQuery.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)

        do {
            let search = MKLocalSearch(request: naturalQuery)
            let response = try await search.start()

            let places = response.mapItems.prefix(10).compactMap { item -> SelectedLocation? in
                guard let name = item.name else { return nil }

                let subtitle = [
                    item.placemark.locality,
                    item.placemark.administrativeArea
                ].compactMap { $0 }.joined(separator: ", ")

                return SelectedLocation(
                    name: name,
                    subtitle: subtitle.isEmpty ? nil : subtitle,
                    coordinate: item.placemark.coordinate
                )
            }

            allPlaces.append(contentsOf: places)
        } catch {
            print("Nearby search failed: \(error)")
        }

        // Sort by distance from user
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        allPlaces.sort { place1, place2 in
            guard let coord1 = place1.coordinate,
                  let coord2 = place2.coordinate else { return false }

            let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
            let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)

            return userLocation.distance(from: loc1) < userLocation.distance(from: loc2)
        }

        return allPlaces
    }

    // MARK: - Reverse Geocode Current Location

    /// Get a location object for the current position
    func currentLocationPlace(coordinate: CLLocationCoordinate2D) async -> SelectedLocation? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            let name = [
                placemark.name,
                placemark.thoroughfare
            ].compactMap { $0 }.first ?? "Current Location"

            let subtitle = [
                placemark.locality,
                placemark.administrativeArea
            ].compactMap { $0 }.joined(separator: ", ")

            return SelectedLocation(
                name: name,
                subtitle: subtitle.isEmpty ? nil : subtitle,
                coordinate: coordinate,
                isCurrentLocation: true
            )
        } catch {
            print("Reverse geocode failed: \(error)")
            return SelectedLocation(
                name: "Current Location",
                coordinate: coordinate,
                isCurrentLocation: true
            )
        }
    }
}
