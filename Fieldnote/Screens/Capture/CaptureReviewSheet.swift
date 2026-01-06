//
//  CaptureReviewSheet.swift
//  Fieldnote
//
//  Review sheet for captured plant photo with form to save encounter
//

import SwiftUI
import CoreLocation
import PhotosUI

struct CaptureReviewSheet: View {
    @Bindable var viewModel: CaptureViewModel
    var store: AppStore
    var captureMode: CaptureMode

    @Environment(\.dismiss) private var dismiss

    @State private var commonName: String
    @State private var scientificName: String
    @State private var family: String
    @State private var confidence: Double
    @State private var selectedCatalogPlant: CatalogPlant?
    @State private var showCatalogPicker = false
    @State private var locationLabel = ""
    @State private var selectedLocation: SelectedLocation?
    @State private var showLocationPicker = false
    @State private var notes = ""
    @State private var selectedConditions: Set<String> = []
    @State private var isSaving = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var addedImage: UIImage?

    // Enrichment data for uncatalogued plants
    @State private var enrichedSummary: String = ""
    @State private var enrichedHabitat: String?
    @State private var enrichedNativeRange: String?
    @State private var isEnriching = false

    let availableConditions = ["sun", "shade", "wet", "dry", "snow", "windy", "hot", "cold"]
    let placeholderSymbols = ["leaf.fill", "camera.fill", "sun.max.fill", "cloud.fill", "tree.fill", "allergens.fill"]

    private var capturedImage: UIImage? {
        addedImage ?? captureMode.image
    }

    init(viewModel: CaptureViewModel, store: AppStore, captureMode: CaptureMode) {
        self.viewModel = viewModel
        self.store = store
        self.captureMode = captureMode

        if let result = captureMode.identificationResult {
            let matchedPlant = CatalogPlant.match(for: result, in: store.catalogPlants)
            _selectedCatalogPlant = State(initialValue: matchedPlant)
            _commonName = State(initialValue: matchedPlant?.commonName ?? result.commonName)
            _scientificName = State(initialValue: matchedPlant?.scientificName ?? result.scientificName)
            _family = State(initialValue: matchedPlant?.family ?? result.family)
            _confidence = State(initialValue: result.confidence)
        } else {
            _commonName = State(initialValue: "")
            _scientificName = State(initialValue: "")
            _family = State(initialValue: "")
            _confidence = State(initialValue: 0.75)
            _selectedCatalogPlant = State(initialValue: nil)
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

//                                    if isEnriching {
//                                        enrichingBadge
//                                    } else if !enrichedSummary.isEmpty && selectedCatalogPlant == nil {
//                                        enrichedBadge
//                                    }
                                }

                                TextField("Common name", text: $commonName)
                                    .vintageTextField()
                                    .onChange(of: commonName) { _, _ in
                                        clearCatalogSelectionIfNeeded()
                                    }

                                TextField("Scientific name (optional)", text: $scientificName)
                                    .vintageTextField()
                                    .italic()
                                    .onChange(of: scientificName) { _, _ in
                                        clearCatalogSelectionIfNeeded()
                                    }

                                TextField("Family", text: $family)
                                    .vintageTextField()
                                    .onChange(of: family) { _, _ in
                                        clearCatalogSelectionIfNeeded()
                                    }

                                HStack(spacing: FieldSpace.xs) {
                                    if let selectedCatalogPlant {
                                        Text("Catalog: \(selectedCatalogPlant.commonName)")
                                            .font(FieldType.caption)
                                            .foregroundColor(FieldColor.mutedInk)
                                    } else {
                                        Text("Catalog: Unmatched")
                                            .font(FieldType.caption)
                                            .foregroundColor(FieldColor.fadedInk)
                                    }

                                    Spacer()

                                    Button {
                                        showCatalogPicker = true
                                    } label: {
                                        Label("Choose", systemImage: "leaf")
                                            .font(FieldType.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
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

                                Button {
                                    showLocationPicker = true
                                } label: {
                                    HStack(spacing: FieldSpace.sm) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(selectedLocation != nil ? FieldColor.accent : FieldColor.fadedInk)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(selectedLocation?.name ?? "Add Location")
                                                .font(FieldType.body)
                                                .foregroundColor(selectedLocation != nil ? FieldColor.ink : FieldColor.fadedInk)
                                                .lineLimit(1)

                                            if let subtitle = selectedLocation?.subtitle {
                                                Text(subtitle)
                                                    .font(FieldType.caption)
                                                    .foregroundColor(FieldColor.fadedInk)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(FieldColor.fadedInk)
                                    }
                                    .padding(FieldSpace.sm)
                                    .background(FieldColor.surface)
                                    .cornerRadius(FieldRadius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FieldRadius.sm)
                                            .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)

                                if !locationLabel.isEmpty {
                                    HStack(spacing: FieldSpace.xs) {
                                        Text("Label: \(locationLabel)")
                                            .font(FieldType.caption)
                                            .foregroundColor(FieldColor.mutedInk)
                                        Spacer()
                                    }
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
                            isEnabled: !commonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
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
        .sheet(isPresented: $showCatalogPicker) {
            CatalogPlantPicker(
                plants: store.catalogPlants,
                selectedPlant: $selectedCatalogPlant,
                isPresented: $showCatalogPicker
            ) { plant in
                applyCatalogPlant(plant)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(
                selectedLocation: $selectedLocation,
                customLabel: $locationLabel
            )
        }
        .task {
            await fetchEnrichmentDataIfNeeded()
        }
    }

    // MARK: - Wikipedia Enrichment

    private func fetchEnrichmentDataIfNeeded() async {
        // Only fetch if not in catalog and we have identification data
        guard selectedCatalogPlant == nil,
              !scientificName.isEmpty || !commonName.isEmpty else {
            print("DEBUG CaptureReview: Skipping enrichment (catalogPlant=\(selectedCatalogPlant != nil), scientific='\(scientificName)', common='\(commonName)')")
            return
        }

        print("DEBUG CaptureReview: Starting enrichment fetch...")
        isEnriching = true

        if let enrichment = await WikipediaPlantService.fetchPlantData(
            scientificName: scientificName,
            commonName: commonName
        ) {
            enrichedSummary = enrichment.summary
            enrichedHabitat = enrichment.habitat
            enrichedNativeRange = enrichment.nativeRange
            print("DEBUG CaptureReview: Enrichment received!")
            print("DEBUG CaptureReview: summary length=\(enrichedSummary.count)")
            print("DEBUG CaptureReview: habitat=\(enrichedHabitat ?? "nil")")
            print("DEBUG CaptureReview: nativeRange=\(enrichedNativeRange ?? "nil")")
        } else {
            print("DEBUG CaptureReview: Enrichment returned nil")
        }

        isEnriching = false
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

    private var enrichingBadge: some View {
        HStack(spacing: FieldSpace.xs) {
            ProgressView()
                .scaleEffect(0.7)
            Text("Loading info...")
                .font(FieldType.caption2)
        }
        .foregroundColor(FieldColor.mutedInk)
        .padding(.horizontal, FieldSpace.sm)
        .padding(.vertical, FieldSpace.xs)
        .background(FieldColor.fadedInk.opacity(0.1))
        .cornerRadius(FieldRadius.sm)
    }

//    private var enrichedBadge: some View {
//        HStack(spacing: FieldSpace.xs) {
//            Image(systemName: "checkmark.circle.fill")
//                .font(.caption)
//            Text("Enriched")
//                .font(FieldType.caption2)
//        }
//        .foregroundColor(FieldColor.successGreen)
//        .padding(.horizontal, FieldSpace.sm)
//        .padding(.vertical, FieldSpace.xs)
//        .background(FieldColor.successGreen.opacity(0.1))
//        .cornerRadius(FieldRadius.sm)
//    }

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
                // Tappable placeholder to add photo
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: FieldRadius.sm)
                            .fill(FieldColor.illustrationBg)

                        VStack(spacing: FieldSpace.xs) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                                .foregroundColor(FieldColor.accent.opacity(0.6))

                            Text("Tap to add photo")
                                .font(FieldType.caption)
                                .foregroundColor(FieldColor.fadedInk)
                        }
                    }
                    .frame(width: 200, height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: FieldRadius.sm)
                            .stroke(FieldColor.accent.opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await loadSelectedPhoto(from: newItem)
            }
        }
    }

    private func loadSelectedPhoto(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                addedImage = image
            }
        } catch {
            print("Failed to load photo: \(error)")
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
        let trimmedCommonName = commonName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedScientificName = scientificName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFamily = family.trimmingCharacters(in: .whitespacesAndNewlines)

        // Build location data from selected location
        let locationName = selectedLocation?.name
        let finalLocationLabel = trimmedLabel.isEmpty ? nil : trimmedLabel
        let coordinates = selectedLocation?.coordinate

        let encounter = Encounter(
            id: encounterId,
            date: Date(),
            locationName: locationName,
            locationLabel: finalLocationLabel,
            coordinates: coordinates,
            photoPlaceholder: placeholderSymbols.randomElement() ?? "leaf.fill",
            confidence: confidence,
            notes: notes.isEmpty ? nil : notes,
            conditions: Array(selectedConditions),
            photoFileName: photoFileName
        )

        // Check if plant exists
        if let existingPlant = store.plant(withCommonName: trimmedCommonName) {
            // Add encounter to existing plant
            store.addEncounter(encounter, to: existingPlant)
        } else {
            // Create new plant with this encounter
            // Use catalog data if available, otherwise use Wikipedia enrichment
            let plantSummary: String
            let plantTraits: [String]
            let plantHabitat: String?
            let plantNativeRange: String?

            if let catalogPlant = selectedCatalogPlant {
                // Use catalog data
                plantSummary = catalogPlant.summary
                plantTraits = catalogPlant.traits
                plantHabitat = catalogPlant.habitat
                plantNativeRange = catalogPlant.nativeRange.isEmpty ? nil : catalogPlant.nativeRange
            } else {
                // Use Wikipedia enrichment data
                plantSummary = enrichedSummary
                plantTraits = []
                plantHabitat = enrichedHabitat
                plantNativeRange = enrichedNativeRange
                print("DEBUG Save: Using enriched data - summary length=\(plantSummary.count), habitat=\(plantHabitat ?? "nil"), nativeRange=\(plantNativeRange ?? "nil")")
            }

            print("DEBUG Save: Creating new plant '\(trimmedCommonName)'")
            print("DEBUG Save: summary='\(plantSummary.prefix(50))...'")
            print("DEBUG Save: habitat=\(plantHabitat ?? "nil"), nativeRange=\(plantNativeRange ?? "nil")")

            let newPlant = Plant(
                commonName: trimmedCommonName,
                scientificName: trimmedScientificName.isEmpty ? "Species unknown" : trimmedScientificName,
                family: trimmedFamily.isEmpty ? "Unknown" : trimmedFamily,
                summary: plantSummary,
                traits: plantTraits,
                habitat: plantHabitat,
                nativeRange: plantNativeRange
            )
            store.addPlant(newPlant)
            store.addEncounter(encounter, to: newPlant)
            print("DEBUG Save: Plant saved with id=\(newPlant.id)")
        }

        isSaving = false

        // Dismiss and reset
        dismiss()
        viewModel.reset()
    }

    private func applyCatalogPlant(_ plant: CatalogPlant) {
        selectedCatalogPlant = plant
        commonName = plant.commonName
        scientificName = plant.scientificName
        family = plant.family
    }

    private func clearCatalogSelectionIfNeeded() {
        guard let selectedCatalogPlant else { return }
        if commonName != selectedCatalogPlant.commonName ||
            scientificName != selectedCatalogPlant.scientificName ||
            family != selectedCatalogPlant.family {
            self.selectedCatalogPlant = nil
        }
    }
}

private struct CatalogPlantPicker: View {
    let plants: [CatalogPlant]
    @Binding var selectedPlant: CatalogPlant?
    @Binding var isPresented: Bool
    let onSelect: (CatalogPlant) -> Void

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List(filteredPlants) { plant in
                Button {
                    selectedPlant = plant
                    onSelect(plant)
                    isPresented = false
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plant.commonName)
                            .font(FieldType.bodyEmphasized)
                            .foregroundColor(FieldColor.ink)
                        Text(plant.scientificName)
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.fadedInk)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search catalog")
            .navigationTitle("Choose Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }
                if selectedPlant != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Clear") {
                            selectedPlant = nil
                            isPresented = false
                        }
                    }
                }
            }
        }
    }

    private var filteredPlants: [CatalogPlant] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return plants.sorted { $0.commonName < $1.commonName }
        }
        let query = trimmed.lowercased()
        return plants.filter { plant in
            plant.commonName.lowercased().contains(query) ||
            plant.scientificName.lowercased().contains(query) ||
            plant.family.lowercased().contains(query)
        }
        .sorted { $0.commonName < $1.commonName }
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    CaptureReviewSheet(viewModel: CaptureViewModel(), captureMode: .manualEntry)
//}
