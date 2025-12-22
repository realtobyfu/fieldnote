//
//  CaptureView.swift
//  Fieldnote
//
//  Capture screen with camera (primary) and photo picker (secondary)
//

import SwiftUI
import PhotosUI

struct CaptureView: View {
    @Environment(\.appStore) var store
    @State private var viewModel = CaptureViewModel()
    @State private var showCamera = false
    @State private var capturedImage: UIImage?

    var body: some View {
        VStack(spacing: FieldSpace.xl) {
            Spacer()

            // Icon and instructions
            VStack(spacing: FieldSpace.md) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(FieldColor.accent)

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

            // Capture buttons
            VStack(spacing: FieldSpace.md) {
                // Primary: Take Photo (Camera)
                if CameraView.isAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                            .font(FieldType.buttonLabel)
                            .foregroundColor(.white)
                            .frame(maxWidth: 280)
                            .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                            .background(FieldColor.accent)
                            .cornerRadius(FieldRadius.button)
                    }
                }

                // Secondary: Choose from Library
                PhotosPicker(
                    selection: $viewModel.selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .font(FieldType.buttonLabel)
                        .foregroundColor(FieldColor.accent)
                        .frame(maxWidth: 280)
                        .padding(.vertical, FieldSpace.sm + FieldSpace.xs)
                        .background(FieldColor.surface)
                        .cornerRadius(FieldRadius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: FieldRadius.button)
                                .stroke(FieldColor.accent, lineWidth: 1.5)
                        )
                }
            }

            Spacer()

            // Recent captures hint
            if !store.allEncounters.isEmpty {
                VStack(spacing: FieldSpace.xs) {
                    Text("Recent Captures")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.mutedInk)

                    Text("\(store.allEncounters.count) total observations")
                        .font(FieldType.caption2)
                        .foregroundColor(FieldColor.mutedInk)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FieldColor.paper)
        .navigationTitle("Capture")
        .onChange(of: viewModel.selectedItem) { _, _ in
            Task {
                await viewModel.loadPhoto()
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            if newImage != nil {
                viewModel.showReviewSheet = true
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: $capturedImage)
        }
        .sheet(isPresented: $viewModel.showReviewSheet) {
            CaptureReviewSheet(
                viewModel: viewModel,
                store: store,
                capturedImage: capturedImage
            )
        }
    }
}

#Preview {
    let store = AppStore()
    return NavigationStack {
        CaptureView()
            .environment(\.appStore, store)
    }
}
