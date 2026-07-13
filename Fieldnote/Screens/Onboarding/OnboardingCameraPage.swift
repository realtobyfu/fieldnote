//
//  OnboardingCameraPage.swift
//  Fieldnote
//
//  Camera and location permission requests, presented as a field-kit
//  checklist that ticks off as each permission is granted
//

import SwiftUI
import AVFoundation
import CoreLocation
import Combine

struct OnboardingCameraPage: View {
    @Environment(\.onboardingStore) private var onboardingStore
    @State private var cameraAuthorized = false
    @State private var cameraDenied = false
    @State private var locationAuthorized = false
    @State private var locationDenied = false
    @State private var contentVisible = false
    @StateObject private var locationDelegate = LocationPermissionDelegate()

    private var showLocationStep: Bool {
        cameraAuthorized && !locationAuthorized && !locationDenied
    }

    private var showBeginButton: Bool {
        cameraAuthorized && (locationAuthorized || locationDenied)
    }

    var body: some View {
        VStack(spacing: FieldSpace.xl) {
            Spacer()

            header

            fieldKitCard

            permissionButtons

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FieldSpace.xl)
        .opacity(contentVisible ? 1 : 0)
        .offset(y: contentVisible ? 0 : 8)
        .onAppear {
            checkCameraPermission()
            checkLocationPermission()
            withAnimation(.easeOut(duration: 0.5)) {
                contentVisible = true
            }
        }
        .onChange(of: locationDelegate.authorizationStatus) { _, newStatus in
            handleLocationStatusChange(newStatus)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: FieldSpace.sm) {
            Text("BEFORE YOU SET OUT")
                .font(FieldType.plateLabel)
                .tracking(2.0)
                .foregroundColor(FieldColor.sepia.opacity(0.7))

            Text(permissionTitle)
                .font(FieldType.displayTitle)
                .foregroundColor(FieldColor.vintageInk)
                .multilineTextAlignment(.center)

            Text(permissionDescription)
                .font(FieldType.body)
                .foregroundColor(FieldColor.fadedInk)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, FieldSpace.md)
                .padding(.top, FieldSpace.xs)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var permissionTitle: String {
        if showBeginButton {
            return "The journal is ready"
        } else if showLocationStep {
            return "And your location"
        } else {
            return "First, the camera"
        }
    }

    private var permissionDescription: String {
        if showBeginButton {
            return "Everything is in place. Add your first entry whenever you find something worth noting."
        } else if showLocationStep {
            return "Location marks where each entry was made and suggests plants that grow nearby. This step is optional."
        } else {
            return "Fieldnote photographs plants to identify them. Your photos stay on your device."
        }
    }

    // MARK: - Field Kit Checklist

    /// The two permissions as a checklist on parchment — rows tick off
    /// as they are granted, like preparing a kit before going out.
    private var fieldKitCard: some View {
        VStack(spacing: 0) {
            kitRow(
                title: "Camera",
                detail: "For photographing the plants you find.",
                granted: cameraAuthorized,
                declined: cameraDenied,
                optional: false
            )

            RuledLine(color: FieldColor.bookBorder.opacity(0.35))

            kitRow(
                title: "Location",
                detail: "Marks where each entry was made.",
                granted: locationAuthorized,
                declined: locationDenied,
                optional: true
            )
        }
        .padding(.horizontal, FieldSpace.md)
        .background(FieldColor.parchment)
        .clipShape(RoundedRectangle(cornerRadius: FieldRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.md, style: .continuous)
                .stroke(FieldColor.bookBorder.opacity(0.4), lineWidth: 0.5)
        )
        .fieldShadow(FieldShadow.card)
        .animation(.easeInOut(duration: 0.3), value: cameraAuthorized)
        .animation(.easeInOut(duration: 0.3), value: locationAuthorized)
        .animation(.easeInOut(duration: 0.3), value: locationDenied)
    }

    private func kitRow(title: String, detail: String, granted: Bool, declined: Bool, optional: Bool) -> some View {
        HStack(spacing: FieldSpace.md) {
            ZStack {
                Circle()
                    .stroke(granted ? FieldColor.accent : FieldColor.bookBorder, lineWidth: 1)
                    .frame(width: 26, height: 26)

                if granted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FieldColor.accent)
                } else if declined {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FieldColor.mutedInk)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: FieldSpace.sm) {
                    Text(title)
                        .font(FieldType.title3)
                        .foregroundColor(FieldColor.vintageInk)

                    if optional {
                        Text("OPTIONAL")
                            .font(FieldType.plateLabel)
                            .tracking(1.2)
                            .foregroundColor(FieldColor.sepia.opacity(0.7))
                    }
                }

                Text(detail)
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, FieldSpace.md)
    }

    // MARK: - Permission Buttons

    private var permissionButtons: some View {
        VStack(spacing: FieldSpace.sm) {
            if showBeginButton {
                // All permissions handled - show begin button
                PrimaryButton("Open the journal") {
                    onboardingStore.completeOnboarding()
                }
                .frame(maxWidth: 280)
            } else if showLocationStep {
                // Camera done, now location
                PrimaryButton("Continue") {
                    requestLocationPermission()
                }
                .frame(maxWidth: 280)
            } else if cameraDenied {
                // Camera permission denied
                VStack(spacing: FieldSpace.sm) {
                    Text("Camera access was denied")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.errorRed)

                    SecondaryButton("Open Settings") {
                        openSettings()
                    }
                    .frame(maxWidth: 200)

                    Button("Continue without camera") {
                        onboardingStore.completeOnboarding()
                    }
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.mutedInk)
                    .padding(.top, FieldSpace.xs)
                }
            } else {
                // Request camera permission
                PrimaryButton("Continue") {
                    requestCameraPermission()
                }
                .frame(maxWidth: 280)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showLocationStep)
        .animation(.easeInOut(duration: 0.3), value: showBeginButton)
    }

    // MARK: - Camera Permission Logic

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraAuthorized = true
        case .denied, .restricted:
            cameraDenied = true
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if granted {
                        cameraAuthorized = true
                    } else {
                        cameraDenied = true
                    }
                }
            }
        }
    }

    // MARK: - Location Permission Logic

    private func checkLocationPermission() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationAuthorized = true
        case .denied, .restricted:
            locationDenied = true
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    private func requestLocationPermission() {
        locationDelegate.requestPermission()
    }

    private func handleLocationStatusChange(_ status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    locationAuthorized = true
                case .denied, .restricted:
                    locationDenied = true
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Location Permission Delegate

private class LocationPermissionDelegate: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = CLLocationManager.authorizationStatus()
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

#Preview {
    OnboardingCameraPage()
        .background(FieldColor.paper)
}
