//
//  FieldCameraView.swift
//  Fieldnote
//
//  Custom capture screen replacing the system UIImagePickerController.
//  AVFoundation preview with app-styled chrome: vintage serif title, glass
//  controls, tap-to-focus, pinch zoom, and integrated shortcuts to the photo
//  library and manual entry so those paths are discoverable from the camera.
//

import AVFoundation
import SwiftUI
import UIKit

struct FieldCameraView: View {
    /// Called with the confirmed photo; the view dismisses itself afterwards.
    var onUsePhoto: (UIImage) -> Void
    /// Called when the user opts to pick from the photo library instead.
    var onPickLibrary: () -> Void
    /// Called when the user opts to write a manual entry instead.
    var onManualEntry: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var model = FieldCameraModel()
    @State private var focusIndicator: FocusIndicator?

    private struct FocusIndicator: Equatable {
        let point: CGPoint
        let id = UUID()
    }

    var body: some View {
        ZStack {
            FieldColor.photoScrim.ignoresSafeArea()

            if let image = model.capturedImage {
                confirmCapture(image)
            } else {
                switch model.availability {
                case .checking:
                    ProgressView()
                        .tint(FieldColor.paper)
                case .ready:
                    liveCamera
                case .denied:
                    fallbackState(
                        title: "Camera Access Needed",
                        message: "Fieldnote uses the camera to photograph plants for identification. You can enable access in Settings.",
                        showsSettingsButton: true
                    )
                case .unavailable:
                    fallbackState(
                        title: "Camera Unavailable",
                        message: "No camera was found on this device — you can still add observations from your photo library or by writing an entry.",
                        showsSettingsButton: false
                    )
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .task { await model.start() }
        .onDisappear { model.stop() }
    }

    // MARK: - Live camera

    private var liveCamera: some View {
        ZStack {
            CameraPreview(
                session: model.session,
                currentZoom: { model.zoomFactor },
                onZoom: { model.setZoom($0) },
                onFocus: { devicePoint, viewPoint in
                    model.focus(at: devicePoint)
                    showFocusIndicator(at: viewPoint)
                }
            )
            .ignoresSafeArea()

            if let indicator = focusIndicator {
                FocusReticle()
                    .position(indicator.point)
                    .id(indicator.id)
            }

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomDeck
            }
        }
    }

    private var topBar: some View {
        HStack {
            chromeButton("xmark", label: "Close") { dismiss() }
            Spacer()
            Text("New Observation")
                .font(FieldType.title3)
                .foregroundStyle(FieldColor.paper)
            Spacer()
            chromeButton(flashSymbol, label: flashLabel) { model.cycleFlashMode() }
        }
        .padding(.horizontal, FieldSpace.md)
        .padding(.top, FieldSpace.sm)
    }

    private var bottomDeck: some View {
        VStack(spacing: FieldSpace.md) {
            if model.zoomFactor > 1.05 {
                Text(String(format: "%.1f×", model.zoomFactor))
                    .font(FieldType.caption.weight(.semibold))
                    .foregroundStyle(FieldColor.paper)
                    .padding(.horizontal, FieldSpace.sm)
                    .padding(.vertical, FieldSpace.xs)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            HStack {
                chromeButton("photo.on.rectangle", label: "Choose from Library", size: 52) {
                    onPickLibrary()
                    dismiss()
                }
                Spacer()
                shutterButton
                Spacer()
                chromeButton("arrow.triangle.2.circlepath", label: "Switch Camera", size: 52) {
                    model.toggleCameraPosition()
                }
            }
            .padding(.horizontal, FieldSpace.xl)

            Button {
                onManualEntry()
                dismiss()
            } label: {
                Label("Write an entry instead", systemImage: "pencil.line")
                    .font(FieldType.callout)
                    .foregroundStyle(FieldColor.paper)
                    .padding(.horizontal, FieldSpace.md)
                    .padding(.vertical, FieldSpace.sm)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, FieldSpace.md)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [FieldColor.photoScrim.opacity(0), FieldColor.photoScrim.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var shutterButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            model.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .stroke(FieldColor.paper, lineWidth: 4)
                    .frame(width: 78, height: 78)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [FieldColor.accent, FieldColor.accentDeep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 64, height: 64)
                if model.isCapturing {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(ShutterPressStyle())
        .disabled(model.isCapturing)
        .accessibilityLabel("Take photo")
    }

    private var flashSymbol: String {
        switch model.flashMode {
        case .on: "bolt.fill"
        case .off: "bolt.slash.fill"
        default: "bolt.badge.automatic.fill"
        }
    }

    private var flashLabel: String {
        switch model.flashMode {
        case .on: "Flash on"
        case .off: "Flash off"
        default: "Flash automatic"
        }
    }

    // MARK: - Confirm captured photo

    private func confirmCapture(_ image: UIImage) -> some View {
        VStack(spacing: FieldSpace.md) {
            Text("Keep this photo?")
                .font(FieldType.title3)
                .foregroundStyle(FieldColor.paper)
                .padding(.top, FieldSpace.sm)

            Spacer(minLength: 0)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: FieldRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: FieldRadius.lg)
                        .stroke(FieldColor.bookBorder.opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal, FieldSpace.md)

            Spacer(minLength: 0)

            HStack(spacing: FieldSpace.md) {
                Button {
                    model.retake()
                } label: {
                    Label("Retake", systemImage: "arrow.counterclockwise")
                        .font(FieldType.bodyEmphasized)
                        .foregroundStyle(FieldColor.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    onUsePhoto(image)
                    dismiss()
                } label: {
                    Label("Use Photo", systemImage: "checkmark")
                        .font(FieldType.bodyEmphasized)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                        .background(FieldColor.accent, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, FieldSpace.md)
            .padding(.bottom, FieldSpace.lg)
        }
    }

    // MARK: - Permission / availability fallbacks

    private func fallbackState(
        title: String,
        message: String,
        showsSettingsButton: Bool
    ) -> some View {
        VStack(spacing: FieldSpace.md) {
            HStack {
                chromeButton("xmark", label: "Close") { dismiss() }
                Spacer()
            }
            .padding(.horizontal, FieldSpace.md)
            .padding(.top, FieldSpace.sm)

            Spacer()

            Image(systemName: "camera.on.rectangle")
                .font(.system(size: 40))
                .foregroundStyle(FieldColor.paper.opacity(0.5))

            Text(title)
                .font(FieldType.title2)
                .foregroundStyle(FieldColor.paper)

            Text(message)
                .font(FieldType.callout)
                .foregroundStyle(FieldColor.paper.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, FieldSpace.xl)

            if showsSettingsButton {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(FieldType.bodyEmphasized)
                        .foregroundStyle(.white)
                        .padding(.horizontal, FieldSpace.lg)
                        .padding(.vertical, FieldSpace.sm)
                        .background(FieldColor.accent, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Text("or")
                .font(FieldType.caption)
                .foregroundStyle(FieldColor.paper.opacity(0.5))

            HStack(spacing: FieldSpace.md) {
                fallbackAction("Choose from Library", symbol: "photo.on.rectangle") {
                    onPickLibrary()
                    dismiss()
                }
                fallbackAction("Write an Entry", symbol: "pencil.line") {
                    onManualEntry()
                    dismiss()
                }
            }

            Spacer()
        }
    }

    private func fallbackAction(
        _ title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(FieldType.footnote.weight(.semibold))
                .foregroundStyle(FieldColor.paper)
                .padding(.horizontal, FieldSpace.md)
                .padding(.vertical, FieldSpace.sm)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chrome helpers

    private func chromeButton(
        _ symbol: String,
        label: String,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(FieldColor.paper)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func showFocusIndicator(at point: CGPoint) {
        let indicator = FocusIndicator(point: point)
        focusIndicator = indicator
        Task {
            try? await Task.sleep(for: .seconds(0.9))
            if focusIndicator == indicator {
                withAnimation(.easeOut(duration: 0.2)) { focusIndicator = nil }
            }
        }
    }
}

// MARK: - Shutter press feedback

private struct ShutterPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Focus reticle

private struct FocusReticle: View {
    @State private var appeared = false

    var body: some View {
        RoundedRectangle(cornerRadius: FieldRadius.sm)
            .stroke(FieldColor.accentBright, lineWidth: 1.5)
            .frame(width: 72, height: 72)
            .scaleEffect(appeared ? 1 : 1.35)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.25)) { appeared = true }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - AVFoundation preview (UIKit)

/// UIKit-backed preview so tap/pinch gestures can convert view coordinates to
/// capture-device coordinates via the preview layer.
private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var currentZoom: () -> CGFloat
    var onZoom: (CGFloat) -> Void
    /// (devicePoint 0...1, viewPoint) on tap.
    var onFocus: (CGPoint, CGPoint) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        view.addGestureRecognizer(
            UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        )
        view.addGestureRecognizer(
            UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch))
        )
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    final class Coordinator: NSObject {
        var parent: CameraPreview
        private var pinchBaseZoom: CGFloat = 1

        init(_ parent: CameraPreview) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? PreviewView else { return }
            let viewPoint = gesture.location(in: view)
            let devicePoint = view.previewLayer.captureDevicePointConverted(fromLayerPoint: viewPoint)
            parent.onFocus(devicePoint, viewPoint)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                pinchBaseZoom = parent.currentZoom()
            case .changed:
                parent.onZoom(pinchBaseZoom * gesture.scale)
            default:
                break
            }
        }
    }
}
