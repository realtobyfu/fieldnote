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

        return await withCheckedContinuation { continuation in
            pendingContinuations.append(continuation)

            // Keep the request alive across the system permission prompt. The
            // authorization delegate continues the same request once the user
            // responds instead of making the caller tap a second time.
            guard pendingContinuations.count == 1 else { return }
            if status == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    var hasAuthorizedAccess: Bool {
        guard CLLocationManager.locationServicesEnabled() else { return false }
        return manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways
    }

    var requiresSettings: Bool {
        guard CLLocationManager.locationServicesEnabled() else { return true }
        return manager.authorizationStatus == .denied
            || manager.authorizationStatus == .restricted
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
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
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            guard !pendingContinuations.isEmpty else { return }
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            let continuations = pendingContinuations
            pendingContinuations.removeAll()
            continuations.forEach { $0.resume(returning: nil) }
        }
    }
}
