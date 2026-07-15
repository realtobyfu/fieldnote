//
//  LocationService.swift
//  Fieldnote
//
//  One-shot location fetcher for capture tagging
//

import CoreLocation

enum LocationAccessState: Equatable {
    case notDetermined
    case authorized
    case denied
    case servicesDisabled
}

enum LocationRequestError: Error, Equatable {
    case permissionDenied
    case servicesDisabled
    case unavailable
}

@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager: CLLocationManager
    private var pendingContinuations: [CheckedContinuation<CLLocationCoordinate2D, Error>] = []

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() async -> CLLocationCoordinate2D? {
        try? await requestCurrentLocationResult()
    }

    /// Typed one-shot request for flows that need to distinguish permission,
    /// services, and transient availability failures.
    func requestCurrentLocationResult() async throws -> CLLocationCoordinate2D {
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationRequestError.servicesDisabled
        }

        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            throw LocationRequestError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
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

    var accessState: LocationAccessState {
        guard CLLocationManager.locationServicesEnabled() else { return .servicesDisabled }

        switch manager.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
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
        let continuations = pendingContinuations
        pendingContinuations.removeAll()

        guard let coordinate = locations.last?.coordinate else {
            continuations.forEach { $0.resume(throwing: LocationRequestError.unavailable) }
            return
        }
        continuations.forEach { $0.resume(returning: coordinate) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let continuations = pendingContinuations
        pendingContinuations.removeAll()
        let requestError: LocationRequestError = accessState == .denied
            ? .permissionDenied
            : .unavailable
        continuations.forEach { $0.resume(throwing: requestError) }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            guard !pendingContinuations.isEmpty else { return }
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            let continuations = pendingContinuations
            pendingContinuations.removeAll()
            continuations.forEach { $0.resume(throwing: LocationRequestError.permissionDenied) }
        }
    }
}
