//
//  Encounter.swift
//  Fieldnote
//
//  Per-sighting observation model
//

import SwiftData
import Foundation
import CoreLocation

@Model
final class Encounter: Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var locationName: String?
    var locationLabel: String?
    var latitude: Double?
    var longitude: Double?
    var photoPlaceholder: String = "leaf.fill"  // SF Symbol name for colored placeholder
    var confidence: Double = 0.75  // 0.0...1.0
    var notes: String?
    var conditions: [String] = []  // e.g., ["sun", "wet", "windy"]

    // User photo storage
    var photoFileName: String?  // Legacy: single photo reference (kept for backward compatibility)
    var photoFileNames: [String] = []  // Multiple photos support

    var plant: Plant?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        locationName: String? = nil,
        locationLabel: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        photoPlaceholder: String = "leaf.fill",
        confidence: Double = 0.75,
        notes: String? = nil,
        conditions: [String] = [],
        photoFileName: String? = nil
    ) {
        self.id = id
        self.date = date
        self.locationName = locationName
        self.locationLabel = locationLabel
        self.latitude = latitude
        self.longitude = longitude
        self.photoPlaceholder = photoPlaceholder
        self.confidence = confidence
        self.notes = notes
        self.conditions = conditions
        self.photoFileName = photoFileName
    }

    /// Convenience initializer with CLLocationCoordinate2D
    convenience init(
        id: UUID = UUID(),
        date: Date = Date(),
        locationName: String? = nil,
        locationLabel: String? = nil,
        coordinates: CLLocationCoordinate2D?,
        photoPlaceholder: String = "leaf.fill",
        confidence: Double = 0.75,
        notes: String? = nil,
        conditions: [String] = [],
        photoFileName: String? = nil
    ) {
        self.init(
            id: id,
            date: date,
            locationName: locationName,
            locationLabel: locationLabel,
            latitude: coordinates?.latitude,
            longitude: coordinates?.longitude,
            photoPlaceholder: photoPlaceholder,
            confidence: confidence,
            notes: notes,
            conditions: conditions,
            photoFileName: photoFileName
        )
    }

    /// Check if this encounter has any photos
    var hasPhoto: Bool {
        !photoFileNames.isEmpty || photoFileName != nil
    }

    /// Get all photo filenames (combines legacy single photo with new array)
    var allPhotoFileNames: [String] {
        var all = photoFileNames
        if let legacy = photoFileName, !all.contains(legacy) {
            all.insert(legacy, at: 0)
        }
        return all
    }
}

// MARK: - Computed Properties

extension Encounter {
    var coordinates: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var displayLocationName: String? {
        if let label = locationLabel, !label.isEmpty {
            return label
        }
        if let cached = locationName, !cached.isEmpty {
            return cached
        }
        return coordinateTag
    }

    var coordinateTag: String? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return "\(formattedCoordinate(lat)), \(formattedCoordinate(lon))"
    }

    private func formattedCoordinate(_ value: Double) -> String {
        String(format: "%.4f", value)
    }
}

// MARK: - Hashable Conformance

extension Encounter {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Encounter, rhs: Encounter) -> Bool {
        lhs.id == rhs.id
    }
}
