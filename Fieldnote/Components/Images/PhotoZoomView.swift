//
//  PhotoZoomView.swift
//  Fieldnote
//
//  Fullscreen photo viewer with pinch-to-zoom
//

import SwiftUI

struct PhotoZoomView: View {
    private let assetName: String?
    private let providedImage: UIImage?
    private let showsCloseButton: Bool

    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0

    /// Initialize with an asset catalog name (loads on appear)
    init(assetName: String, showsCloseButton: Bool = true) {
        self.assetName = assetName
        self.providedImage = nil
        self.showsCloseButton = showsCloseButton
    }

    /// Initialize with a pre-loaded UIImage
    init(image: UIImage?, showsCloseButton: Bool = true) {
        self.assetName = nil
        self.providedImage = image
        self.showsCloseButton = showsCloseButton
    }

    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()

            // Photo
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnificationGesture)
                    .highPriorityGesture(dragGesture, including: scale > 1.0 ? .all : .none)
                    .onTapGesture(count: 2) {
                        doubleTapZoom()
                    }
            } else {
                // No image fallback
                VStack(spacing: FieldSpace.md) {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No Photo")
                        .font(FieldType.callout)
                        .foregroundColor(.gray)
                }
            }

            // Close button overlay
            if showsCloseButton {
                closeButton
            }
        }
        .statusBarHidden()
        .onAppear {
            if let providedImage {
                image = providedImage
            } else if let assetName {
                image = BundledImagery.uiImage(named: assetName)
            }
        }
    }

    // MARK: - Close Button

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

            // Zoom indicator
            if scale > 1.0 {
                Text("\(Int(scale * 100))%")
                    .font(FieldType.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, FieldSpace.sm)
                    .padding(.vertical, FieldSpace.xs)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(FieldRadius.sm)
                    .padding(.bottom, FieldSpace.lg)
            }
        }
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let delta = value.magnification / lastScale
                lastScale = value.magnification
                let newScale = scale * delta
                scale = min(max(newScale, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = 1.0
                // Reset if zoomed out too much
                if scale < minScale {
                    withAnimation(.spring(response: 0.3)) {
                        scale = minScale
                        offset = .zero
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow drag when zoomed in
                guard scale > 1.0 else { return }

                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset

                // If not zoomed, reset offset
                if scale <= 1.0 {
                    withAnimation(.spring(response: 0.3)) {
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }

    // MARK: - Double Tap Zoom

    private func doubleTapZoom() {
        withAnimation(.spring(response: 0.3)) {
            if scale > 1.0 {
                // Reset to 1x
                scale = 1.0
                offset = .zero
                lastOffset = .zero
            } else {
                // Zoom to 2x
                scale = 2.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PhotoZoomView(assetName: "dandelion_photo_01")
}
