//
//  LocationService.swift
//  Fieldnote
//
//  One-shot location fetcher for capture tagging
//

import CoreLocation

@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager: CLLocationManager
    private var pendingContinuations: [CheckedContinuation<CLLocationCoordinate2D?, Never>] = []

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() async -> CLLocationCoordinate2D? {
        guard CLLocationManager.locationServicesEnabled() else {
            return nil
        }

        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            return nil
        }
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            return nil
        }

        return await withCheckedContinuation { continuation in
            pendingContinuations.append(continuation)
            // Only request location if this is the first pending request
            if pendingContinuations.count == 1 {
                manager.requestLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.first?.coordinate
        let continuations = pendingContinuations
        pendingContinuations.removeAll()
        continuations.forEach { $0.resume(returning: coordinate) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let continuations = pendingContinuations
        pendingContinuations.removeAll()
        continuations.forEach { $0.resume(returning: nil) }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            let continuations = pendingContinuations
            pendingContinuations.removeAll()
            continuations.forEach { $0.resume(returning: nil) }
        }
    }
}
