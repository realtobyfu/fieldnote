//
//  IllustrationFullScreenView.swift
//  Fieldnote
//
//  Full-screen, zoomable view of a botanical plate (or a remote photo), presented
//  when the user taps a detail-view hero. Lets a good illustration be seen at full
//  size. Pinch to zoom, drag to pan, double-tap to toggle, swipe-down / ✕ to close.
//

import SwiftUI

struct IllustrationFullScreenView: View {
    /// Local illustration asset name, when showing a bundled/regional plate.
    var assetName: String? = nil
    /// Remote photo URL, when showing an iNaturalist photo instead.
    var photoURL: URL? = nil
    /// Optional caption (attribution) shown along the bottom.
    var caption: AnyView? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.opacity(0.94).ignoresSafeArea()

            image
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnification)
                .simultaneousGesture(scale > 1 ? drag : nil)
                .onTapGesture(count: 2) { toggleZoom() }
                .padding()

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.9), .black.opacity(0.35))
                            .padding()
                    }
                    .accessibilityLabel("Close")
                }
                Spacer()
                if let caption {
                    caption
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
        }
        .presentationBackground(.clear)
    }

    @ViewBuilder
    private var image: some View {
        if let assetName {
            Image(assetName).resizable()
        } else if let photoURL {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .success(let img): img.resizable()
                case .empty: ProgressView().tint(.white)
                default: Image(systemName: "photo").foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in scale = min(max(lastScale * value, 1), 5) }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 { resetZoom() }
            }
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func toggleZoom() {
        withAnimation(.snappy) {
            if scale > 1 { resetZoom() } else { scale = 2.5; lastScale = 2.5 }
        }
    }

    private func resetZoom() {
        withAnimation(.snappy) {
            scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero
        }
    }
}
