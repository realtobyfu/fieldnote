//
//  OnboardingCameraPage.swift
//  Fieldnote
//
//  "Ready Your Lens" - Camera and location permission requests
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

            // Illustration/icon
            permissionIllustration

            // Request text
            VStack(spacing: FieldSpace.md) {
                Text(showLocationStep ? "One More Thing" : "Ready Your Lens")
                    .font(FieldType.displayTitle)
                    .foregroundColor(FieldColor.vintageInk)
                    .multilineTextAlignment(.center)

                Text(permissionDescription)
                    .font(FieldType.body)
                    .foregroundColor(FieldColor.fadedInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, FieldSpace.md)
                    .fixedSize(horizontal: false, vertical: true)
                
            }

            // Permission buttons
            permissionButtons

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FieldSpace.xl)
        .opacity(contentVisible ? 1 : 0)
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

    private var permissionDescription: String {
        if showLocationStep {
            return "Enable location to discover plants commonly found near you. This helps personalize your exploration experience."
        } else {
            return "To document your botanical discoveries, Fieldnote needs access to your camera. Your photos stay private on your device."
        }
    }

    // MARK: - Permission Illustration

    private var permissionIllustration: some View {
        ZStack {
            // Vintage frame background - larger size
            RoundedRectangle(cornerRadius: FieldRadius.lg)
                .fill(FieldColor.illustrationBg)
                .frame(width: 180, height: 180)

            // Decorative outer border
            RoundedRectangle(cornerRadius: FieldRadius.lg)
                .stroke(FieldColor.bookBorder, lineWidth: 2)
                .frame(width: 180, height: 180)

            // Inner decorative border
            RoundedRectangle(cornerRadius: FieldRadius.md)
                .stroke(FieldColor.bookBorder.opacity(0.3), lineWidth: 1)
                .frame(width: 166, height: 166)

            // Icon based on current step
            if showBeginButton {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(FieldColor.successGreen)
            } else if showLocationStep {
                Image(systemName: "location.viewfinder")
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(FieldColor.accent)
            } else if cameraAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(FieldColor.successGreen)
            } else {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(FieldColor.accent)
            }
        }
        .fieldShadow(FieldShadow.card)
        .scaleEffect(contentVisible ? 1 : 0.85)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: contentVisible)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showLocationStep)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showBeginButton)
    }

    // MARK: - Permission Buttons

    private var permissionButtons: some View {
        VStack(spacing: FieldSpace.sm) {
            if showBeginButton {
                // All permissions handled - show begin button
                PrimaryButton("Begin Your Journal") {
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

                    Button("Continue Without Camera") {
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
