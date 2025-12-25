//
//  PlantPhotoGalleryView.swift
//  Fieldnote
//
//  Horizontally scrollable gallery of curated plant photos
//

import SwiftUI

struct PlantPhotoGalleryView: View {
    let plantName: String

    @State private var selectedAssetName: String?

    private let itemSize = CGSize(width: 200, height: 140)

    var body: some View {
        let photoAssets = PlantPhotoService.photoNames(for: plantName)

        if !photoAssets.isEmpty {
            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                SectionHeader(title: "Gallery", showRuledLine: true)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.sm) {
                        ForEach(photoAssets, id: \.self) { assetName in
                            Button {
                                selectedAssetName = assetName
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
                get: { selectedAssetName != nil },
                set: { if !$0 { selectedAssetName = nil } }
            )) {
                if let assetName = selectedAssetName {
                    PhotoZoomView(assetName: assetName)
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

#Preview {
    PlantPhotoGalleryView(plantName: "Dandelion")
        .padding()
        .background(FieldColor.agedPaper)
}
