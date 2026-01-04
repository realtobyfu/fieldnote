//
//  LocationCategory.swift
//  Fieldnote
//
//  Location category types with associated icons and colors
//

import SwiftUI
import MapKit

enum LocationCategory: String, Codable, CaseIterable {
    case park
    case trail
    case garden
    case water
    case urban
    case unknown

    // MARK: - Display Properties

    var iconName: String {
        switch self {
        case .park:
            return "tree.fill"
        case .trail:
            return "figure.hiking"
        case .garden:
            return "leaf.fill"
        case .water:
            return "drop.fill"
        case .urban:
            return "building.2.fill"
        case .unknown:
            return "mappin.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .park:
            return FieldColor.accent // Muted chlorophyll green
        case .trail:
            return FieldColor.botanicalBrown // Warm brown
        case .garden:
            return Color(red: 0.42, green: 0.56, blue: 0.42) // Soft sage
        case .water:
            return Color(red: 0.36, green: 0.48, blue: 0.55) // Slate blue
        case .urban:
            return FieldColor.sepia // Sepia brown
        case .unknown:
            return FieldColor.accent // Default to green
        }
    }

    var label: String {
        switch self {
        case .park:
            return "Park"
        case .trail:
            return "Trail"
        case .garden:
            return "Garden"
        case .water:
            return "Water"
        case .urban:
            return "Urban"
        case .unknown:
            return "Location"
        }
    }

    // MARK: - MapKit Category Mapping

    /// Initialize from MapKit POI category
    init(from poiCategory: MKPointOfInterestCategory?) {
        guard let category = poiCategory else {
            self = .unknown
            return
        }

        switch category {
        case .park, .nationalPark, .campground:
            self = .park
        case .beach, .marina:
            self = .water
        case .zoo, .museum, .library, .school, .university:
            self = .garden // Cultural/educational places often have gardens
        default:
            self = .unknown
        }
    }

    /// Infer category from location name keywords
    static func infer(from name: String) -> LocationCategory {
        let lowercased = name.lowercased()

        // Water-related
        if lowercased.contains("beach") || lowercased.contains("lake") ||
           lowercased.contains("river") || lowercased.contains("creek") ||
           lowercased.contains("pond") || lowercased.contains("stream") ||
           lowercased.contains("wetland") || lowercased.contains("marsh") ||
           lowercased.contains("bay") || lowercased.contains("harbor") {
            return .water
        }

        // Trail-related
        if lowercased.contains("trail") || lowercased.contains("path") ||
           lowercased.contains("hike") || lowercased.contains("walk") ||
           lowercased.contains("greenway") || lowercased.contains("bluff") {
            return .trail
        }

        // Garden-related
        if lowercased.contains("garden") || lowercased.contains("arboretum") ||
           lowercased.contains("botanical") || lowercased.contains("nursery") ||
           lowercased.contains("conservatory") {
            return .garden
        }

        // Park-related
        if lowercased.contains("park") || lowercased.contains("forest") ||
           lowercased.contains("preserve") || lowercased.contains("reserve") ||
           lowercased.contains("sanctuary") || lowercased.contains("wilderness") ||
           lowercased.contains("woods") || lowercased.contains("meadow") {
            return .park
        }

        // Urban-related
        if lowercased.contains("street") || lowercased.contains("avenue") ||
           lowercased.contains("road") || lowercased.contains("plaza") ||
           lowercased.contains("square") || lowercased.contains("downtown") ||
           lowercased.contains("neighborhood") {
            return .urban
        }

        return .unknown
    }
}
