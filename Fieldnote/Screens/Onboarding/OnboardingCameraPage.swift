//
//  OnboardingCameraPage.swift
//  Fieldnote
//
//  "Ready Your Lens" - Camera permission request with field journal framing
//

import SwiftUI
import AVFoundation

struct OnboardingCameraPage: View {
    @Environment(\.onboardingStore) private var onboardingStore
    @State private var cameraAuthorized = false
    @State private var permissionDenied = false
    @State private var contentVisible = false

    var body: some View {
        VStack(spacing: FieldSpace.xl) {
            Spacer()

            // Camera illustration/icon
            cameraIllustration

            // Request text
            VStack(spacing: FieldSpace.md) {
                Text("Ready Your Lens")
                    .font(FieldType.displayTitle)
                    .foregroundColor(FieldColor.vintageInk)
                    .multilineTextAlignment(.center)

                Text("To document your botanical discoveries, Fieldnote needs access to your camera. Your photos stay private on your device.")
                    .font(FieldType.body)
                    .foregroundColor(FieldColor.fadedInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, FieldSpace.md)
            }

            // Permission button
            permissionButton

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FieldSpace.xl)
        .opacity(contentVisible ? 1 : 0)
        .onAppear {
            checkCameraPermission()
            withAnimation(.easeOut(duration: 0.5)) {
                contentVisible = true
            }
        }
    }

    // MARK: - Camera Illustration

    private var cameraIllustration: some View {
        ZStack {
            // Vintage frame background
            RoundedRectangle(cornerRadius: FieldRadius.lg)
                .fill(FieldColor.illustrationBg)
                .frame(width: 160, height: 160)

            // Decorative border
            RoundedRectangle(cornerRadius: FieldRadius.lg)
                .stroke(FieldColor.bookBorder, lineWidth: 1.5)
                .frame(width: 160, height: 160)

            // Camera icon
            Image(systemName: cameraAuthorized ? "checkmark.circle.fill" : "camera.viewfinder")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(cameraAuthorized ? FieldColor.successGreen : FieldColor.accent)
        }
        .fieldShadow(FieldShadow.card)
    }

    // MARK: - Permission Button

    private var permissionButton: some View {
        VStack(spacing: FieldSpace.sm) {
            if cameraAuthorized {
                // Camera authorized - show begin button
                PrimaryButton("Begin Your Journal") {
                    onboardingStore.completeOnboarding()
                }
                .frame(maxWidth: 280)
            } else if permissionDenied {
                // Permission denied - show settings button
                VStack(spacing: FieldSpace.sm) {
                    Text("Camera access was denied")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.errorRed)

                    SecondaryButton("Open Settings") {
                        openSettings()
                    }
                    .frame(maxWidth: 200)

                    Button("Skip for Now") {
                        onboardingStore.completeOnboarding()
                    }
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.mutedInk)
                    .padding(.top, FieldSpace.xs)
                }
            } else {
                // Request permission
                PrimaryButton("Allow Camera Access") {
                    requestCameraPermission()
                }
                .frame(maxWidth: 280)

                Button("Skip for Now") {
                    onboardingStore.completeOnboarding()
                }
                .font(FieldType.callout)
                .foregroundColor(FieldColor.mutedInk)
                .padding(.top, FieldSpace.xs)
            }
        }
    }

    // MARK: - Permission Logic

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraAuthorized = true
        case .denied, .restricted:
            permissionDenied = true
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cameraAuthorized = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        permissionDenied = true
                    }
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

#Preview {
    OnboardingCameraPage()
        .background(FieldColor.agedPaper)
}
