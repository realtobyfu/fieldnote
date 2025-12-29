//
//  PlantPhotoGalleryView.swift
//  Fieldnote
//
//  Horizontally scrollable gallery of curated plant photos
//

import SwiftUI

struct PlantPhotoGalleryView: View {
    let plantName: String

    @State private var selectedIndex: Int?

    private let itemSize = CGSize(width: 200, height: 140)

    var body: some View {
        let photoAssets = PlantPhotoService.photoNames(for: plantName)

        if !photoAssets.isEmpty {
            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                SectionHeader(title: "Gallery", showRuledLine: true)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.sm) {
                        ForEach(Array(photoAssets.enumerated()), id: \.element) { index, assetName in
                            Button {
                                selectedIndex = index
                            } label: {
                                galleryItem(assetName)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, FieldSpace.xs)
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { selectedIndex != nil },
                set: { if !$0 { selectedIndex = nil } }
            )) {
                if let selectedIndex {
                    PhotoGalleryPagerView(
                        assetNames: photoAssets,
                        initialIndex: selectedIndex
                    )
                }
            }
        }
    }

    private func galleryItem(_ assetName: String) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
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
}

private struct PhotoGalleryPagerView: View {
    let assetNames: [String]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int

    init(assetNames: [String], initialIndex: Int) {
        self.assetNames = assetNames
        self.initialIndex = initialIndex
        _selection = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(assetNames.indices, id: \.self) { index in
                    PhotoZoomView(assetName: assetNames[index], showsCloseButton: false)
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
}

#Preview {
    PlantPhotoGalleryView(plantName: "Dandelion")
        .padding()
        .background(FieldColor.agedPaper)
}
