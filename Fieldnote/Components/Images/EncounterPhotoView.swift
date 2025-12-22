//
//  EncounterPhotoView.swift
//  Fieldnote
//
//  Displays user photos from encounters with vintage framing
//

import SwiftUI

struct EncounterPhotoView: View {
    let encounter: Encounter
    var height: CGFloat = 160
    var showFrame: Bool = true

    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var showFullscreen = false

    var body: some View {
        Group {
            if let image = loadedImage {
                loadedPhotoView(image)
            } else if isLoading && encounter.hasPhoto {
                loadingView
            } else {
                EmptyView()
            }
        }
        .task {
            await loadPhoto()
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            PhotoZoomView(image: loadedImage)
        }
    }

    // MARK: - Loaded Photo View

    private func loadedPhotoView(_ image: UIImage) -> some View {
        Button {
            showFullscreen = true
        } label: {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .clipped()
                .overlay(vintageOverlay)
                .cornerRadius(FieldRadius.sm)
                .overlay(vintageFrame)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Vintage Styling

    private var vintageOverlay: some View {
        // Subtle sepia tint for vintage feel
        Rectangle()
            .fill(FieldColor.sepia.opacity(0.05))
    }

    @ViewBuilder
    private var vintageFrame: some View {
        if showFrame {
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .stroke(FieldColor.bookBorder, lineWidth: 1)
                .padding(1)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .fill(FieldColor.illustrationBg)
                .frame(height: height)

            ProgressView()
                .tint(FieldColor.fadedInk)
        }
    }

    // MARK: - Photo Loading

    private func loadPhoto() async {
        guard let filename = encounter.photoFileName else {
            isLoading = false
            return
        }

        loadedImage = await PhotoStorageService.shared.loadPhoto(filename: filename)
        isLoading = false
    }
}

// MARK: - Thumbnail Variant

/// A smaller thumbnail version for list views
struct EncounterPhotoThumbnail: View {
    let encounter: Encounter
    var size: CGFloat = 60

    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
                    .cornerRadius(FieldRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: FieldRadius.sm)
                            .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
                    )
            } else if encounter.hasPhoto {
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .fill(FieldColor.separator)
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.6)
                    )
            }
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let filename = encounter.photoFileName else { return }
        loadedImage = await PhotoStorageService.shared.loadThumbnail(filename: filename, maxSize: size * 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: FieldSpace.lg) {
        Text("Encounter Photo View")
            .font(FieldType.title3)

        // Note: This won't show actual photos in preview
        // since there's no stored photo data
        EncounterPhotoView(
            encounter: Encounter(
                confidence: 0.85,
                photoFileName: "test.jpg"
            )
        )

        EncounterPhotoThumbnail(
            encounter: Encounter(
                confidence: 0.85,
                photoFileName: "test.jpg"
            )
        )
    }
    .padding()
    .background(FieldColor.agedPaper)
}
