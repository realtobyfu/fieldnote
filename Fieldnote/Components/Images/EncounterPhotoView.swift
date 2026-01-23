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

    @State private var loadedImages: [String: UIImage] = [:]
    @State private var isLoading = true
    @State private var showFullscreen = false
    @State private var selectedPhotoIndex: Int = 0
    @State private var downloadingFromCloud = false

    private var photoFileNames: [String] {
        encounter.allPhotoFileNames
    }

    private var hasMultiplePhotos: Bool {
        photoFileNames.count > 1
    }

    var body: some View {
        Group {
            if !loadedImages.isEmpty {
                if hasMultiplePhotos {
                    multiPhotoView
                } else if let firstFilename = photoFileNames.first,
                          let image = loadedImages[firstFilename] {
                    singlePhotoView(image)
                }
            } else if isLoading && encounter.hasPhoto {
                loadingView
            } else {
                EmptyView()
            }
        }
        .task {
            await loadPhotos()
        }
        .onReceive(NotificationCenter.default.publisher(for: .photoSyncedFromCloud)) { notification in
            // Reload if a synced photo belongs to this encounter
            if let filename = notification.userInfo?["filename"] as? String,
               photoFileNames.contains(filename) {
                Task {
                    await loadPhotos()
                }
            }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            PhotoPagerView(
                images: photoFileNames.compactMap { loadedImages[$0] },
                initialIndex: selectedPhotoIndex
            )
        }
    }

    // MARK: - Single Photo View

    private func singlePhotoView(_ image: UIImage) -> some View {
        Button {
            selectedPhotoIndex = 0
            showFullscreen = true
        } label: {
            ZStack {
                // Vintage letterbox background
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .fill(FieldColor.illustrationBg)

                // Photo with aspect fit
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(FieldSpace.xs)
            }
            .frame(height: height)
            .overlay(vintageOverlay)
            .cornerRadius(FieldRadius.sm)
            .overlay(vintageFrame)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Multi Photo View

    private var multiPhotoView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FieldSpace.sm) {
                ForEach(Array(photoFileNames.enumerated()), id: \.offset) { index, filename in
                    if let image = loadedImages[filename] {
                        Button {
                            selectedPhotoIndex = index
                            showFullscreen = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: FieldRadius.sm)
                                    .fill(FieldColor.illustrationBg)

                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(FieldSpace.xs)
                            }
                            .frame(width: height * 1.2, height: height)
                            .overlay(vintageOverlay)
                            .cornerRadius(FieldRadius.sm)
                            .overlay(vintageFrame)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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

            VStack(spacing: FieldSpace.xs) {
                if downloadingFromCloud {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.title2)
                        .foregroundColor(FieldColor.fadedInk)
                }
                ProgressView()
                    .tint(FieldColor.fadedInk)
                if downloadingFromCloud {
                    Text("Downloading from iCloud...")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }
        }
    }

    // MARK: - Photo Loading

    private func loadPhotos() async {
        let filenames = photoFileNames
        guard !filenames.isEmpty else {
            isLoading = false
            return
        }

        // Check if any photos need to be downloaded from iCloud
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDirectory = documentsPath.appendingPathComponent("EncounterPhotos", isDirectory: true)

        var needsCloudDownload = false
        for filename in filenames {
            let localURL = photosDirectory.appendingPathComponent(filename)
            if !fileManager.fileExists(atPath: localURL.path) {
                needsCloudDownload = true
                break
            }
        }

        if needsCloudDownload {
            downloadingFromCloud = true
        }

        for filename in filenames {
            if let image = await PhotoStorageService.shared.loadPhoto(filename: filename) {
                loadedImages[filename] = image
            }
        }

        downloadingFromCloud = false
        isLoading = false
    }
}

// MARK: - Photo Pager View (Fullscreen)

struct PhotoPagerView: View {
    let images: [UIImage]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    PhotoZoomView(image: image)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never))

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            currentIndex = initialIndex
        }
    }
}

// MARK: - Thumbnail Variant

/// A smaller thumbnail version for list views
struct EncounterPhotoThumbnail: View {
    let encounter: Encounter
    var size: CGFloat = 60

    @State private var loadedImage: UIImage?

    private var firstPhotoFilename: String? {
        encounter.allPhotoFileNames.first
    }

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
        guard let filename = firstPhotoFilename else { return }
        loadedImage = await PhotoStorageService.shared.loadThumbnail(filename: filename, maxSize: size * 2)
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    EncounterPhotoView(encounter: Encounter(...))
//}
