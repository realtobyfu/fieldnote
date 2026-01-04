//
//  LocationIcon.swift
//  Fieldnote
//
//  Location icon with category-based color variation
//

import SwiftUI

struct LocationIcon: View {
    let category: LocationCategory
    let size: Size

    enum Size {
        case small   // For list rows (32pt)
        case medium  // For cards/headers (40pt)

        var containerSize: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 40
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            }
        }
    }

    init(category: LocationCategory, size: Size = .small) {
        self.category = category
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(category.color)
                .frame(width: size.containerSize, height: size.containerSize)

            Image(systemName: "leaf.fill")
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Current Location Icon

struct CurrentLocationIcon: View {
    let isLoading: Bool

    init(isLoading: Bool = false) {
        self.isLoading = isLoading
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(FieldColor.accent)
                .frame(width: 32, height: 32)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        Text("Location Icons")
            .font(.headline)

        // All categories with color variation
        HStack(spacing: 16) {
            ForEach(LocationCategory.allCases, id: \.self) { category in
                VStack(spacing: 8) {
                    LocationIcon(category: category)
                    Text(category.label)
                        .font(.caption2)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }
        }

        Divider()

        // Current location
        HStack(spacing: 16) {
            CurrentLocationIcon()
            Text("Current Location")
                .font(.caption)
        }
    }
    .padding()
    .background(FieldColor.paper)
}
