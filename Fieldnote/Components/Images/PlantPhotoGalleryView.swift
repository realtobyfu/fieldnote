//
//  PlantPhotoGalleryView.swift
//  Fieldnote
//
//  Horizontally scrollable gallery of curated plant photos
//

import SwiftUI
import UIKit

struct PlantPhotoGalleryView: View {
    let plantName: String
    let userPhotoFilenames: [String]

    @State private var selectedIndex: Int?
    @State private var userThumbnails: [String: UIImage] = [:]
    @State private var isLoadingUserPhotos = false

    private let itemSize = CGSize(width: 200, height: 140)

    init(plantName: String, userPhotoFilenames: [String] = []) {
        self.plantName = plantName
        self.userPhotoFilenames = userPhotoFilenames
    }

    var body: some View {
        let items = galleryItems

        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            if !items.isEmpty {
                SectionHeader(title: "Gallery", showRuledLine: true)

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

    private var galleryItems: [GalleryItem] {
        let curated = PlantPhotoService.photoNames(for: plantName).map { GalleryItem.asset(name: $0) }
        let user = userPhotoFilenames.map { GalleryItem.user(filename: $0) }
        return user + curated
    }

    private func galleryItem(_ item: GalleryItem) -> some View {
        ZStack {
            switch item {
            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFill()
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
                    PhotoZoomView(
                        image: image(for: items[index]),
                        showsCloseButton: false
                    )
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

    private func image(for item: GalleryItem) -> UIImage? {
        switch item {
        case .asset(let name):
            return UIImage(named: name)
        case .user(let filename):
            return userImages[filename]
        }
    }
}

private enum GalleryItem: Identifiable, Hashable {
    case asset(name: String)
    case user(filename: String)

    var id: String {
        switch self {
        case .asset(let name): return "asset-\(name)"
        case .user(let filename): return "user-\(filename)"
        }
    }
}

//#Preview {
//    PlantPhotoGalleryView(plantName: "Dandelion", userPhotoFilenames: [])
//        .padding()
//        .background(FieldColor.agedPaper)
//}
