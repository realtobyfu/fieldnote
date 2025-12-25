//
//  CaptureReviewSheet.swift
//  Fieldnote
//
//  Review sheet for captured plant photo with form to save encounter
//

import SwiftUI
import CoreLocation

struct CaptureReviewSheet: View {
    @Bindable var viewModel: CaptureViewModel
    var store: AppStore
    var captureMode: CaptureMode

    @Environment(\.dismiss) private var dismiss

    @State private var commonName: String
    @State private var scientificName: String
    @State private var family: String
    @State private var confidence: Double
    @State private var locationLabel = ""
    @State private var resolvedLocationName: String?
    @State private var locationCoordinates: CLLocationCoordinate2D?
    @State private var isLocating = false
    @State private var isResolvingLocation = false
    @State private var locationError: String?
    @State private var notes = ""
    @State private var selectedConditions: Set<String> = []
    @State private var isSaving = false

    let availableConditions = ["sun", "shade", "wet", "dry", "snow", "windy", "hot", "cold"]
    let placeholderSymbols = ["leaf.fill", "camera.fill", "sun.max.fill", "cloud.fill", "tree.fill", "allergens.fill"]

    private var capturedImage: UIImage? {
        captureMode.image
    }

    init(viewModel: CaptureViewModel, store: AppStore, captureMode: CaptureMode) {
        self.viewModel = viewModel
        self.store = store
        self.captureMode = captureMode

        if let result = captureMode.identificationResult {
            _commonName = State(initialValue: result.commonName)
            _scientificName = State(initialValue: result.scientificName)
            _family = State(initialValue: result.family)
            _confidence = State(initialValue: result.confidence)
        } else {
            _commonName = State(initialValue: "")
            _scientificName = State(initialValue: "")
            _family = State(initialValue: "")
            _confidence = State(initialValue: 0.75)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FieldSpace.lg) {
                    // Preview image with vintage frame
                    photoPreview
                        .padding(.horizontal, FieldSpace.md)

                    // Form sections
                    VStack(spacing: FieldSpace.md) {
                        // Plant identification
                        VintageCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                HStack {
                                    Text("Plant Identification")
                                        .font(FieldType.bodyEmphasized)
                                        .foregroundColor(FieldColor.vintageInk)

                                    Spacer()

                                    if captureMode.hasPrefilledData {
                                        aiIdentifiedBadge
                                    }
                                }

                                TextField("Common name", text: $commonName)
                                    .vintageTextField()

                                TextField("Scientific name (optional)", text: $scientificName)
                                    .vintageTextField()
                                    .italic()

                                TextField("Family", text: $family)
                                    .vintageTextField()
                            }
                        }

                        // Confidence
                        VintageCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                HStack {
                                    Text("Confidence")
                                        .font(FieldType.bodyEmphasized)
                                        .foregroundColor(FieldColor.vintageInk)

                                    Spacer()

                                    ConfidencePill(confidence: confidence)
                                }

                                Slider(value: $confidence, in: 0.0...1.0)
                                    .tint(FieldColor.accent)
                            }
                        }

                        // Location
                        VintageCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Location")
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.vintageInk)

                                TextField("Location label (optional)", text: $locationLabel)
                                    .vintageTextField()

                                if let coordinateDisplay {
                                    Text("Coords: \(coordinateDisplay)")
                                        .font(FieldType.caption)
                                        .foregroundColor(FieldColor.fadedInk)
                                }

                                HStack(spacing: FieldSpace.xs) {
                                    locationActionButton(
                                        title: isLocating ? "Locating..." : "Use Current Location",
                                        systemImage: "location.fill",
                                        isEnabled: !isLocating
                                    ) {
                                        Task {
                                            await requestLocation()
                                        }
                                    }

                                    locationActionButton(
                                        title: isResolvingLocation ? "Looking Up..." : "Look Up Place Name",
                                        systemImage: "mappin.and.ellipse",
                                        isEnabled: locationCoordinates != nil && !isResolvingLocation
                                    ) {
                                        Task {
                                            await resolveLocationName()
                                        }
                                    }
                                }

                                if let resolvedLocationName {
                                    HStack(spacing: FieldSpace.xs) {
                                        Text("Detected: \(resolvedLocationName)")
                                            .font(FieldType.caption)
                                            .foregroundColor(FieldColor.mutedInk)

                                        Spacer()

                                        Button("Use") {
                                            locationLabel = resolvedLocationName
                                        }
                                        .font(FieldType.caption)
                                        .foregroundColor(FieldColor.accent)
                                        .buttonStyle(.plain)
                                    }
                                }

                                if let locationError {
                                    Text(locationError)
                                        .font(FieldType.caption)
                                        .foregroundColor(FieldColor.fadedInk)
                                }
                            }
                        }

                        // Conditions
                        VintageCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Conditions")
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.vintageInk)

                                FlowLayout(spacing: FieldSpace.xs) {
                                    ForEach(availableConditions, id: \.self) { condition in
                                        TraitChip(
                                            condition,
                                            isSelected: selectedConditions.contains(condition)
                                        ) {
                                            if selectedConditions.contains(condition) {
                                                selectedConditions.remove(condition)
                                            } else {
                                                selectedConditions.insert(condition)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Notes
                        VintageCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Field Notes")
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.vintageInk)

                                TextEditor(text: $notes)
                                    .font(FieldType.body)
                                    .foregroundColor(FieldColor.ink)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 100)
                                    .padding(FieldSpace.xs)
                                    .background(FieldColor.surface)
                                    .cornerRadius(FieldRadius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FieldRadius.sm)
                                            .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
                                    )
                            }
                        }

                        // Save button
                        PrimaryButton(
                            isSaving ? "Saving..." : "Save Observation",
                            isEnabled: !commonName.isEmpty && !isSaving
                        ) {
                            Task {
                                await saveEncounter()
                            }
                        }
                    }
                    .padding(.horizontal, FieldSpace.md)
                }
                .padding(.vertical, FieldSpace.md)
            }
            .background(FieldColor.agedPaper)
            .navigationTitle("Review Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        viewModel.reset()
                    }
                }
            }
        }
    }

    // MARK: - AI Badge

    private var aiIdentifiedBadge: some View {
        HStack(spacing: FieldSpace.xs) {
            Image(systemName: "sparkles")
                .font(.caption)
            Text("AI Identified")
                .font(FieldType.caption2)
        }
        .foregroundColor(FieldColor.accent)
        .padding(.horizontal, FieldSpace.sm)
        .padding(.vertical, FieldSpace.xs)
        .background(FieldColor.accent.opacity(0.1))
        .cornerRadius(FieldRadius.sm)
    }

    // MARK: - Photo Preview

    private var photoPreview: some View {
        Group {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 140)
                    .clipped()
                    .overlay(
                        // Subtle sepia tint
                        Rectangle()
                            .fill(FieldColor.sepia.opacity(0.05))
                    )
                    .cornerRadius(FieldRadius.sm)
                    .overlay(
                        // Vintage frame
                        RoundedRectangle(cornerRadius: FieldRadius.sm)
                            .stroke(FieldColor.bookBorder.opacity(0.6), lineWidth: 0.8)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: FieldRadius.sm)
                        .fill(FieldColor.illustrationBg)

                    VStack(spacing: FieldSpace.xs) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 32))
                            .foregroundColor(FieldColor.botanicalBrown.opacity(0.4))

                        Text("No photo")
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.fadedInk)
                    }
                }
                .frame(width: 200, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: FieldRadius.sm)
                        .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Save Encounter

    private func saveEncounter() async {
        isSaving = true

        // Generate encounter ID for photo filename
        let encounterId = UUID()

        // Save photo if available
        var photoFileName: String? = nil
        if let image = capturedImage {
            do {
                photoFileName = try await PhotoStorageService.shared.savePhoto(image, for: encounterId)
            } catch {
                print("Failed to save photo: \(error)")
                // Continue without photo
            }
        }

        // Create new encounter with photo reference
        let trimmedLabel = locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let encounter = Encounter(
            id: encounterId,
            date: Date(),
            locationName: resolvedLocationName,
            locationLabel: trimmedLabel.isEmpty ? nil : trimmedLabel,
            coordinates: locationCoordinates,
            photoPlaceholder: placeholderSymbols.randomElement() ?? "leaf.fill",
            confidence: confidence,
            notes: notes.isEmpty ? nil : notes,
            conditions: Array(selectedConditions),
            photoFileName: photoFileName
        )

        // Check if plant exists
        if let existingPlant = store.plant(withCommonName: commonName) {
            // Add encounter to existing plant
            store.addEncounter(encounter, to: existingPlant)
        } else {
            // Create new plant with this encounter
            let newPlant = Plant(
                commonName: commonName,
                scientificName: scientificName.isEmpty ? "Species unknown" : scientificName,
                family: family.isEmpty ? "Unknown" : family,
                summary: "",
                traits: []
            )
            store.addPlant(newPlant)
            store.addEncounter(encounter, to: newPlant)
        }

        isSaving = false

        // Dismiss and reset
        dismiss()
        viewModel.reset()
    }

    private var coordinateDisplay: String? {
        guard let coordinates = locationCoordinates else { return nil }
        return String(format: "%.4f, %.4f", coordinates.latitude, coordinates.longitude)
    }

    private func requestLocation() async {
        isLocating = true
        locationError = nil

        let coordinates = await LocationService.shared.requestCurrentLocation()
        if let coordinates {
            locationCoordinates = coordinates
        } else {
            locationError = "Location unavailable. Check permissions or try again."
        }

        isLocating = false
    }

    private func resolveLocationName() async {
        guard let coordinates = locationCoordinates else {
            locationError = "Add coordinates before looking up a place name."
            return
        }

        isResolvingLocation = true
        locationError = nil

        let name = await LocationGeocoderService.shared.reverseGeocode(coordinates)
        if let name {
            resolvedLocationName = name
        } else {
            locationError = "Unable to resolve a place name right now."
        }

        isResolvingLocation = false
    }

    private func locationActionButton(
        title: String,
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: FieldSpace.xs) {
                Image(systemName: systemImage)
                    .font(.caption2)
                Text(title)
                    .font(FieldType.caption)
            }
            .foregroundColor(isEnabled ? FieldColor.accent : FieldColor.fadedInk)
            .padding(.vertical, FieldSpace.xs)
            .padding(.horizontal, FieldSpace.sm)
            .background(
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .stroke(isEnabled ? FieldColor.accent : FieldColor.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    CaptureReviewSheet(viewModel: CaptureViewModel(), captureMode: .manualEntry)
//}
