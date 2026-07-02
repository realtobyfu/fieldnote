//
//  FieldCameraModel.swift
//  Fieldnote
//
//  AVFoundation capture session backing FieldCameraView. Observable UI state
//  lives on the main actor; all session mutation happens on a dedicated
//  serial queue so configuration never stalls the UI.
//

import AVFoundation
import SwiftUI
import UIKit

@MainActor
@Observable
final class FieldCameraModel {

    enum Availability {
        case checking
        case ready
        case denied
        case unavailable
    }

    private(set) var availability: Availability = .checking
    private(set) var isCapturing = false
    private(set) var flashMode: AVCaptureDevice.FlashMode = .auto
    private(set) var position: AVCaptureDevice.Position = .back
    private(set) var zoomFactor: CGFloat = 1
    private(set) var maxZoomFactor: CGFloat = 1
    var capturedImage: UIImage?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.fieldnote.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    // Only ever touched on sessionQueue after configuration.
    nonisolated(unsafe) private var activeInput: AVCaptureDeviceInput?
    // Retains the in-flight capture delegate until its callback fires.
    private var activeCaptureDelegate: PhotoCaptureDelegate?

    // MARK: - Lifecycle

    func start() async {
        guard availability == .checking else {
            resumeIfNeeded()
            return
        }

        #if targetEnvironment(simulator)
        availability = .unavailable
        return
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                availability = .denied
                return
            }
        default:
            availability = .denied
            return
        }
        configureSession()
        #endif
    }

    func stop() {
        let session = session
        sessionQueue.async {
            if session.isRunning { session.stopRunning() }
        }
    }

    private func resumeIfNeeded() {
        guard availability == .ready else { return }
        let session = session
        sessionQueue.async {
            if !session.isRunning { session.startRunning() }
        }
    }

    private func configureSession() {
        let session = session
        let photoOutput = photoOutput
        let position = position
        sessionQueue.async { [weak self] in
            guard let device = Self.camera(at: position),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                Task { @MainActor in self?.availability = .unavailable }
                return
            }

            session.beginConfiguration()
            session.sessionPreset = .photo
            guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
                session.commitConfiguration()
                Task { @MainActor in self?.availability = .unavailable }
                return
            }
            session.addInput(input)
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
            Self.lockPortraitRotation(on: photoOutput)
            session.commitConfiguration()

            self?.activeInput = input
            session.startRunning()

            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 8)
            Task { @MainActor in
                guard let self else { return }
                self.maxZoomFactor = maxZoom
                self.availability = .ready
            }
        }
    }

    // MARK: - Controls

    func cycleFlashMode() {
        switch flashMode {
        case .auto: flashMode = .on
        case .on: flashMode = .off
        default: flashMode = .auto
        }
    }

    func toggleCameraPosition() {
        let newPosition: AVCaptureDevice.Position = position == .back ? .front : .back
        position = newPosition
        zoomFactor = 1

        let session = session
        let photoOutput = photoOutput
        sessionQueue.async { [weak self] in
            guard let device = Self.camera(at: newPosition),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }

            session.beginConfiguration()
            if let current = self?.activeInput { session.removeInput(current) }
            if session.canAddInput(input) {
                session.addInput(input)
                self?.activeInput = input
            } else if let current = self?.activeInput {
                // Restore the previous camera rather than leaving a dead session.
                session.addInput(current)
            }
            Self.lockPortraitRotation(on: photoOutput)
            session.commitConfiguration()

            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 8)
            Task { @MainActor in self?.maxZoomFactor = maxZoom }
        }
    }

    func setZoom(_ factor: CGFloat) {
        let clamped = min(max(factor, 1), maxZoomFactor)
        zoomFactor = clamped
        sessionQueue.async { [weak self] in
            guard let device = self?.activeInput?.device else { return }
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()
            } catch {}
        }
    }

    /// Focus + expose at a point in capture-device coordinates (0...1).
    func focus(at devicePoint: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let device = self?.activeInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch {}
        }
    }

    // MARK: - Capture

    func capturePhoto() {
        guard availability == .ready, !isCapturing else { return }
        isCapturing = true

        let settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(flashMode) {
            settings.flashMode = flashMode
        }
        settings.photoQualityPrioritization = .balanced

        let delegate = PhotoCaptureDelegate { [weak self] image in
            Task { @MainActor in
                guard let self else { return }
                self.isCapturing = false
                self.activeCaptureDelegate = nil
                if let image { self.capturedImage = image }
            }
        }
        activeCaptureDelegate = delegate

        let photoOutput = photoOutput
        sessionQueue.async {
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    func retake() {
        capturedImage = nil
        resumeIfNeeded()
    }

    // MARK: - Helpers

    nonisolated private static func camera(at position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    nonisolated private static func lockPortraitRotation(on output: AVCapturePhotoOutput) {
        guard let connection = output.connection(with: .video),
              connection.isVideoRotationAngleSupported(90) else { return }
        connection.videoRotationAngle = 90
    }
}

// MARK: - Photo capture delegate

/// Bridges AVCapturePhotoOutput's queue-bound callback to a Sendable completion.
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: @Sendable (UIImage?) -> Void

    init(completion: @escaping @Sendable (UIImage?) -> Void) {
        self.completion = completion
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        completion(image)
    }
}
