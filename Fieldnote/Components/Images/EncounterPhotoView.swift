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
        .padding(.horizontal, FieldSpace.sm)
    }

    // MARK: - Multi Photo View (Grid Mosaic)

    private var multiPhotoView: some View {
        let count = loadedImages.count

        return Group {
            switch count {
            case 2:
                twoPhotoLayout
            case 3:
                threePhotoLayout
            case 4:
                fourPhotoLayout
            default:
                fourPlusLayout
            }
        }
        .cornerRadius(FieldRadius.sm)
        .overlay(vintageFrame)
        .padding(.horizontal, FieldSpace.sm)
    }

    // Two photos: side-by-side, equal width
    private var twoPhotoLayout: some View {
        HStack(spacing: 2) {
            photoCell(index: 0)
            photoCell(index: 1)
        }
        .frame(height: height)
    }

    // Three photos: 1 large left (2/3) + 2 stacked right (1/3)
    private var threePhotoLayout: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                photoCell(index: 0)
                    .frame(width: geometry.size.width * 2 / 3 - 1)

                VStack(spacing: 2) {
                    photoCell(index: 1)
                    photoCell(index: 2)
                }
                .frame(width: geometry.size.width / 3 - 1)
            }
        }
        .frame(height: height)
    }

    // Four photos: 2x2 grid
    private var fourPhotoLayout: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                photoCell(index: 0)
                photoCell(index: 1)
            }
            HStack(spacing: 2) {
                photoCell(index: 2)
                photoCell(index: 3)
            }
        }
        .frame(height: height)
    }

    // Five+ photos: 2x2 grid with "+N" overlay on last cell
    private var fourPlusLayout: some View {
        let extraCount = loadedImages.count - 4

        return VStack(spacing: 2) {
            HStack(spacing: 2) {
                photoCell(index: 0)
                photoCell(index: 1)
            }
            HStack(spacing: 2) {
                photoCell(index: 2)
                photoCell(index: 3, showOverlay: extraCount)
            }
        }
        .frame(height: height)
    }

    // MARK: - Photo Cell Helper

    @ViewBuilder
    private func photoCell(index: Int, showOverlay: Int? = nil) -> some View {
        let filenames = photoFileNames
        if index < filenames.count,
           let image = loadedImages[filenames[index]] {
            Button {
                selectedPhotoIndex = index
                showFullscreen = true
            } label: {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .contentShape(Rectangle())
                    .overlay {
                        if let extra = showOverlay, extra > 0 {
                            Color.black.opacity(0.4)
                            Text("+\(extra)")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Vintage Styling

    private var vintageOverlay: some View {
        // Very subtle sepia tint - reduced for cleaner look
        Rectangle()
            .fill(FieldColor.sepia.opacity(0.02))
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
                .fill(FieldColor.separator.opacity(0.3))
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
