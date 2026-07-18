//
//  PlantPhotoGalleryView.swift
//  Fieldnote
//
//  Horizontally scrollable gallery of curated plant photos
//

import SwiftUI
import UIKit

/// A licensed remote photo (today: iNaturalist) shown alongside the curated
/// bundled shots. Attribution is the source's prebuilt credit string and is
/// surfaced in the full-screen viewer.
struct RemoteGalleryPhoto: Identifiable, Hashable {
    /// Medium rendition — gallery thumbnails.
    let url: URL
    /// Large rendition — full-screen viewing (falls back to `url`).
    let fullURL: URL?
    let attribution: String?

    var id: String { url.absoluteString }
}

struct PlantPhotoGalleryView: View {
    let plantName: String
    let userPhotoFilenames: [String]
    let remotePhotos: [RemoteGalleryPhoto]
    let isProminent: Bool

    @State private var selectedIndex: Int?
    @State private var userThumbnails: [String: UIImage] = [:]
    @State private var isLoadingUserPhotos = false

    private let itemSize = CGSize(width: 200, height: 140)
    private let prominentHeroSize = CGSize(width: 320, height: 220)

    init(
        plantName: String,
        userPhotoFilenames: [String] = [],
        remotePhotos: [RemoteGalleryPhoto] = [],
        isProminent: Bool = false
    ) {
        self.plantName = plantName
        self.userPhotoFilenames = userPhotoFilenames
        self.remotePhotos = remotePhotos
        self.isProminent = isProminent
    }

    var body: some View {
        let items = galleryItems

        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            if !items.isEmpty {
                if isProminent {
                    // Gallery-first mode: first photo is hero-sized
                    prominentGalleryView(items: items)
                } else {
                    // Standard mode: horizontal scroll gallery
                    SectionHeader(title: "Gallery", showRuledLine: true)
                    standardGalleryView(items: items)
                }
            } else if isProminent {
                // No photos available in prominent mode - show empty state
                emptyProminentState
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedIndex != nil },
            set: { if !$0 { selectedIndex = nil } }
        )) {
            if let selectedIndex {
                PhotoGalleryPagerView(
                    items: items,
                    userImages: userThumbnails,
                    initialIndex: selectedIndex
                )
            }
        }
        .task(id: userPhotoFilenames) {
            await loadUserThumbnails()
        }
    }

    // MARK: - Standard Gallery View

    private func standardGalleryView(items: [GalleryItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FieldSpace.sm) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        selectedIndex = index
                    } label: {
                        galleryItem(item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, FieldSpace.xs)
        }
    }

    // MARK: - Prominent (Gallery-First) View

    private func prominentGalleryView(items: [GalleryItem]) -> some View {
        VStack(alignment: .leading, spacing: FieldSpace.md) {
            // First photo as hero
            if let firstItem = items.first {
                Button {
                    selectedIndex = 0
                } label: {
                    prominentHeroItem(firstItem)
                }
                .buttonStyle(.plain)
            }

            // Remaining photos in horizontal scroll
            if items.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.sm) {
                        ForEach(Array(items.dropFirst().enumerated()), id: \.element.id) { index, item in
                            Button {
                                selectedIndex = index + 1
                            } label: {
                                galleryItem(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, FieldSpace.xs)
                }
            }
        }
    }

    private func prominentHeroItem(_ item: GalleryItem) -> some View {
        ZStack {
            switch item {
            case .asset(let name):
                BundledImagery.image(name)
                    .resizable()
                    .scaledToFill()
            case .remote(let photo):
                remoteThumbnail(photo, cornerRadius: FieldRadius.md)
            case .user(let filename):
                if let image = userThumbnails[filename] {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if isLoadingUserPhotos {
                    RoundedRectangle(cornerRadius: FieldRadius.md)
                        .fill(FieldColor.illustrationBg)
                        .overlay(
                            ProgressView()
                                .tint(FieldColor.fadedInk)
                        )
                } else {
                    RoundedRectangle(cornerRadius: FieldRadius.md)
                        .fill(FieldColor.illustrationBg)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(FieldColor.fadedInk)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: prominentHeroSize.height)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.md)
                .stroke(FieldColor.bookBorder.opacity(0.6), lineWidth: 0.8)
        )
        .cornerRadius(FieldRadius.md)
        .overlay(
            Rectangle()
                .fill(FieldColor.sepia.opacity(0.03))
        )
    }

    private var emptyProminentState: some View {
        VStack(spacing: FieldSpace.sm) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(FieldColor.fadedInk)

            Text("No photos yet")
                .font(FieldType.callout)
                .foregroundColor(FieldColor.fadedInk)

            Text("Photos from observations will appear here")
                .font(FieldType.caption)
                .foregroundColor(FieldColor.fadedInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: prominentHeroSize.height)
        .background(FieldColor.illustrationBg)
        .cornerRadius(FieldRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.md)
                .stroke(FieldColor.bookBorder.opacity(0.4), lineWidth: 0.5)
        )
    }

    private var galleryItems: [GalleryItem] {
        let curated = PlantPhotoService.photoNames(for: plantName).map { GalleryItem.asset(name: $0) }
        let user = userPhotoFilenames.map { GalleryItem.user(filename: $0) }
        let remote = remotePhotos.map { GalleryItem.remote(photo: $0) }
        return user + curated + remote
    }

    private func galleryItem(_ item: GalleryItem) -> some View {
        ZStack {
            switch item {
            case .asset(let name):
                BundledImagery.image(name)
                    .resizable()
                    .scaledToFill()
            case .remote(let photo):
                remoteThumbnail(photo, cornerRadius: FieldRadius.sm)
            case .user(let filename):
                if let image = userThumbnails[filename] {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if isLoadingUserPhotos {
                    RoundedRectangle(cornerRadius: FieldRadius.sm)
                        .fill(FieldColor.illustrationBg)
                        .overlay(
                            ProgressView()
                                .tint(FieldColor.fadedInk)
                        )
                } else {
                    RoundedRectangle(cornerRadius: FieldRadius.sm)
                        .fill(FieldColor.illustrationBg)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(FieldColor.fadedInk)
                        )
                }
            }
        }
        .frame(width: itemSize.width, height: itemSize.height)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: FieldRadius.sm)
                .stroke(FieldColor.bookBorder.opacity(0.6), lineWidth: 0.8)
        )
        .cornerRadius(FieldRadius.sm)
        .overlay(
            Rectangle()
                .fill(FieldColor.sepia.opacity(0.03))
        )
    }

    /// AsyncImage thumbnail for a remote (iNaturalist) photo, matching the
    /// bundled-asset treatment.
    private func remoteThumbnail(_ photo: RemoteGalleryPhoto, cornerRadius: CGFloat) -> some View {
        AsyncImage(url: photo.url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .empty:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(FieldColor.illustrationBg)
                    .overlay(
                        ProgressView()
                            .tint(FieldColor.fadedInk)
                    )
            case .failure:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(FieldColor.illustrationBg)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(FieldColor.fadedInk)
                    )
            @unknown default:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(FieldColor.illustrationBg)
            }
        }
    }

    private func loadUserThumbnails() async {
        guard !userPhotoFilenames.isEmpty else { return }
        guard !isLoadingUserPhotos else { return }

        isLoadingUserPhotos = true

        for filename in userPhotoFilenames where userThumbnails[filename] == nil {
            if let thumbnail = await PhotoStorageService.shared.loadThumbnail(
                filename: filename,
                maxSize: max(itemSize.width, itemSize.height) * 2
            ) {
                await MainActor.run {
                    userThumbnails[filename] = thumbnail
                }
            }
        }

        isLoadingUserPhotos = false
    }
}

private struct PhotoGalleryPagerView: View {
    let items: [GalleryItem]
    let userImages: [String: UIImage]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int

    init(items: [GalleryItem], userImages: [String: UIImage], initialIndex: Int) {
        self.items = items
        self.userImages = userImages
        self.initialIndex = initialIndex
        _selection = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(items.indices, id: \.self) { index in
                    page(for: items[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            closeButton
        }
        .statusBarHidden()
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
                .padding(.trailing, FieldSpace.md)
                .padding(.top, FieldSpace.md)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func page(for item: GalleryItem) -> some View {
        switch item {
        case .asset(let name):
            PhotoZoomView(image: BundledImagery.uiImage(named: name), showsCloseButton: false)
        case .user(let filename):
            PhotoZoomView(image: userImages[filename], showsCloseButton: false)
        case .remote(let photo):
            RemotePhotoZoomPage(photo: photo)
        }
    }
}

/// Full-screen page for a remote photo: downloads the large rendition into the
/// shared zoom viewer, with the source attribution pinned beneath (licensed
/// photos must stay credited wherever they render large).
private struct RemotePhotoZoomPage: View {
    let photo: RemoteGalleryPhoto

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if let image {
                PhotoZoomView(image: image, showsCloseButton: false)
            } else if failed {
                PhotoZoomView(image: nil, showsCloseButton: false)
            } else {
                ProgressView()
                    .tint(.white)
            }

            if let attribution = photo.attribution, !attribution.isEmpty {
                Text("Photo: \(attribution) · iNaturalist")
                    .font(FieldType.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FieldSpace.lg)
                    .padding(.bottom, FieldSpace.xxl)
            }
        }
        .task {
            guard image == nil else { return }
            let url = photo.fullURL ?? photo.url
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let loaded = UIImage(data: data) {
                image = loaded
            } else {
                failed = true
            }
        }
    }
}

private enum GalleryItem: Identifiable, Hashable {
    case asset(name: String)
    case user(filename: String)
    case remote(photo: RemoteGalleryPhoto)

    var id: String {
        switch self {
        case .asset(let name): return "asset-\(name)"
        case .user(let filename): return "user-\(filename)"
        case .remote(let photo): return "remote-\(photo.id)"
        }
    }
}

//#Preview {
//    PlantPhotoGalleryView(plantName: "Dandelion", userPhotoFilenames: [])
//        .padding()
//        .background(FieldColor.agedPaper)
//}
