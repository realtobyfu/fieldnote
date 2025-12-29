//
//  CaptureView.swift
//  Fieldnote
//
//  Capture screen with animated shutter camera button
//

import SwiftUI
import PhotosUI

struct CaptureView: View {
    @Environment(\.appStore) private var store
    @State private var viewModel = CaptureViewModel()
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var shutterExpanding = false

    private var appStore: AppStore {
        guard let store = store else {
            fatalError("AppStore not found in environment")
        }
        return store
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                mainContent(geometry: geometry)
                shutterOverlay(geometry: geometry)

                if viewModel.isIdentifying {
                    identifyingOverlay
                }
            }
            .background(FieldColor.paper)
        }
        .navigationTitle("Capture")
        .onChange(of: viewModel.selectedItem) { _, _ in
            Task {
                await viewModel.loadPhoto()
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                Task {
                    await viewModel.handleCapturedImage(image)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            showCamera = false
            shutterExpanding = false
        } content: {
            CameraView(capturedImage: $capturedImage)
                .environment(\.appStore, store)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showReviewSheet) {
            shutterExpanding = false
            capturedImage = nil
        } content: {
            CaptureReviewSheet(
                viewModel: viewModel,
                store: appStore,
                captureMode: viewModel.captureMode ?? .manualEntry
            )
            .environment(\.appStore, store)
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: FieldSpace.xl) {
            Spacer()
            VStack(spacing: FieldSpace.md) {
                cameraButton(geometry: geometry)

                VStack(spacing: FieldSpace.xs) {
                    Text("Capture a Plant")
                        .font(FieldType.title2)
                        .foregroundColor(FieldColor.ink)

                    Text("Take a photo or choose from your library")
                        .font(FieldType.body)
                        .foregroundColor(FieldColor.mutedInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FieldSpace.xl)
                }
            }
            .padding(.bottom, 5)

            VStack(spacing: FieldSpace.sm) {
                // Choose from Library
                PhotosPicker(
                    selection: $viewModel.selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .font(FieldType.buttonLabel)
                        .foregroundColor(.white)
                        .frame(maxWidth: 280)
                        .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                        .background(FieldColor.accent)
                        .cornerRadius(FieldRadius.button)
                }

                // Manual Entry (secondary)
                Button {
                    viewModel.startManualEntry()
                } label: {
                    Label("Manual Entry", systemImage: "pencil.line")
                        .font(FieldType.buttonLabel)
                        .foregroundColor(FieldColor.accent)
                        .frame(maxWidth: 280)
                        .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                        .background(
                            RoundedRectangle(cornerRadius: FieldRadius.button)
                                .stroke(FieldColor.accent, lineWidth: 1.5)
                        )
                }
            }
            // Recent captures hint
            if !appStore.allEncounters.isEmpty {
                VStack(spacing: FieldSpace.xs) {
                    Text("\(appStore.allEncounters.count) total observations")
                        .font(FieldType.footnote)
                        .foregroundColor(FieldColor.mutedInk)
                }
                .padding(.top, 10)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var instructionsSection: some View {
        VStack(spacing: FieldSpace.sm) {
            Text("Capture a Plant")
                .font(FieldType.title2)
                .foregroundColor(FieldColor.ink)

            Text("Tap the camera to begin")
                .font(FieldType.callout)
                .foregroundColor(FieldColor.mutedInk)
        }
        .opacity(shutterExpanding ? 0 : 1)
    }

    @ViewBuilder
    private func cameraButton(geometry: GeometryProxy) -> some View {
        if CameraView.isAvailable {
            Button {
                triggerShutter(geometry: geometry)
            } label: {
                cameraButtonLabel
            }
            .opacity(shutterExpanding ? 0 : 1)
        }
    }

    private var cameraButtonLabel: some View {
        ZStack {
            Circle()
                .fill(FieldColor.surface)
                .frame(width: 88, height: 88)
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)

            Circle()
                .stroke(FieldColor.accent, lineWidth: 3)
                .frame(width: 88, height: 88)

            Image(systemName: "camera.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(FieldColor.accent)
        }
    }

    private var libraryPickerSection: some View {
        PhotosPicker(
            selection: $viewModel.selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack(spacing: FieldSpace.xs) {
                Image(systemName: "photo.on.rectangle")
                Text("Choose from Library")
            }
            .font(FieldType.callout)
            .foregroundColor(FieldColor.mutedInk)
        }
        .opacity(shutterExpanding ? 0 : 1)
        .padding(.bottom, FieldSpace.xl)
    }

    @ViewBuilder
    private var recentCapturesSection: some View {
        if !appStore.allEncounters.isEmpty {
            Text("\(appStore.allEncounters.count) observations")
                .font(FieldType.caption2)
                .foregroundColor(FieldColor.mutedInk)
                .opacity(shutterExpanding ? 0 : 1)
                .padding(.bottom, FieldSpace.md)
        }
    }

    // MARK: - Identifying Overlay

    private var identifyingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: FieldSpace.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Identifying plant...")
                    .font(FieldType.body)
                    .foregroundColor(.white)
            }
            .padding(FieldSpace.xl)
            .background(
                RoundedRectangle(cornerRadius: FieldRadius.lg)
                    .fill(FieldColor.ink.opacity(0.9))
            )
        }
    }

    // MARK: - Shutter Overlay

    @ViewBuilder
    private func shutterOverlay(geometry: GeometryProxy) -> some View {
        if shutterExpanding {
            let size = max(geometry.size.width, geometry.size.height) * 2.5
            Circle()
                .fill(FieldColor.ink)
                .frame(width: size, height: size)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
        }
    }

    // MARK: - Actions

    private func triggerShutter(geometry: GeometryProxy) {
        withAnimation(.easeInOut(duration: 0.35)) {
            shutterExpanding = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showCamera = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                shutterExpanding = false
            }
        }
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    CaptureView()
//}
