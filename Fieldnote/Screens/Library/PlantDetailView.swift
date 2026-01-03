//
//  PlantDetailView.swift
//  Fieldnote
//
//  Detail view for an individual plant with vintage book styling
//

import SwiftUI
import PhotosUI
import SwiftData

struct PlantDetailView: View {
    let plant: Plant
    @Environment(\.modelContext) private var modelContext

    @State private var selectedIllustrationItem: PhotosPickerItem?
    @State private var isSavingIllustration = false
    @State private var illustrationError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.lg) {
                // Hero botanical illustration
                heroIllustration

                // Curated photo gallery (exact-match only)
                PlantPhotoGalleryView(plantName: plant.commonName)

                // Plant info card
                VintageCard {
                    VStack(alignment: .leading, spacing: FieldSpace.md) {
                        // Names
                        VStack(alignment: .leading, spacing: FieldSpace.xs) {
                            Text(plant.commonName)
                                .font(FieldType.displaySubtitle)
                                .foregroundColor(FieldColor.vintageInk)

                            ScientificNameText(plant.scientificName, size: .callout)
                            
                        }
                        RuledLine()


                        // Family and confidence
                        HStack {
                            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                                Text("Family")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                                Text(plant.family)
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.vintageInk)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: FieldSpace.xs) {
                                if !plant.encounters.isEmpty {
                                    Text("Confidence")  
                                        .font(FieldType.caption)
                                        .foregroundColor(FieldColor.fadedInk)
                                    ConfidencePill(confidence: plant.averageConfidence)
                                }
                            }
                        }

                        // Traits
                        if !plant.traits.isEmpty {
                            RuledLine()

                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Traits")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)

                                FlowLayout(spacing: FieldSpace.xs) {
                                    ForEach(plant.traits, id: \.self) { trait in
                                        TraitChip(trait)
                                    }
                                }
                            }
                        }
                        RuledLine()

                        if !plant.summary.isEmpty {
                            Text(plant.summary)
                                .font(FieldType.callout)
                                .foregroundColor(FieldColor.ink)
                        }



                    }
                }

                // Encounters section
                if !plant.encounters.isEmpty {
                    VStack(alignment: .leading, spacing: FieldSpace.md) {
                        SectionHeader(title: "Observations (\(plant.encounterCount))", showRuledLine: true)

                        ForEach(plant.encounters.sorted(by: { $0.date > $1.date })) { encounter in
                            NavigationLink {
                                EncounterDetailView(encounter: encounter, plant: plant)
                            } label: {
                                EncounterCard(encounter: encounter)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(FieldSpace.md)
        }
        .background(FieldColor.agedPaper)
        .navigationTitle(plant.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedIllustrationItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await saveCustomIllustration(from: newItem)
            }
        }
    }

    // MARK: - Hero Illustration

    private var heroIllustration: some View {
        VStack(spacing: 0) {
            // Main illustration - tappable when no illustration exists
            if shouldOfferCustomIllustration {
                PhotosPicker(selection: $selectedIllustrationItem, matching: .images) {
                    PlantIllustrationView(plant: plant, size: .hero)
                        .bookPageBorder(padding: FieldSpace.md, cornerRadius: FieldRadius.lg)
                        .background(FieldColor.surface)
                        .cornerRadius(FieldRadius.lg)
                        .overlay(
                            // Subtle hint that it's tappable
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(FieldColor.accent)
                                        .background(Circle().fill(FieldColor.surface))
                                        .padding(FieldSpace.sm)
                                }
                            }
                        )
                }
                .disabled(isSavingIllustration)
            } else {
                PlantIllustrationView(plant: plant, size: .hero)
                    .bookPageBorder(padding: FieldSpace.md, cornerRadius: FieldRadius.lg)
                    .background(FieldColor.surface)
                    .cornerRadius(FieldRadius.lg)
            }

            // Scientific name plate
            ScientificNamePlate(name: plant.scientificName)
                .padding(.top, FieldSpace.sm)
                .padding(.horizontal, FieldSpace.lg)

            if let illustrationError {
                Text(illustrationError)
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.fadedInk)
                    .padding(.top, FieldSpace.xs)
            }
        }
    }
}

extension PlantDetailView {
    private var shouldOfferCustomIllustration: Bool {
        let hasCustom = (plant.customIllustrationFileName?.isEmpty == false)
        let hasBuiltIn = IllustrationService.hasIllustration(for: plant.commonName, family: plant.family)
        return !hasCustom && !hasBuiltIn
    }

    private func saveCustomIllustration(from item: PhotosPickerItem) async {
        isSavingIllustration = true
        illustrationError = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                illustrationError = "Unable to load the selected image."
                isSavingIllustration = false
                return
            }

            let filename = try await PlantIllustrationStorageService.shared.saveIllustration(
                image,
                for: plant.id
            )
            plant.customIllustrationFileName = filename

            do {
                try modelContext.save()
            } catch {
                illustrationError = "Failed to save illustration."
            }
        } catch {
            illustrationError = "Failed to import illustration."
        }

        isSavingIllustration = false
    }
}

// MARK: - Encounter Card

private struct EncounterCard: View {
    let encounter: Encounter

    var body: some View {
        VintageCard {
            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                // User photo (if available)
                if encounter.hasPhoto {
                    EncounterPhotoView(encounter: encounter, height: 180)
                        .cornerRadius(FieldRadius.sm)
                }

                // Date and confidence
                HStack {
                    Text(encounter.date, style: .date)
                        .font(FieldType.bodyEmphasized)
                        .foregroundColor(FieldColor.vintageInk)

                    Spacer()

                    ConfidencePill(confidence: encounter.confidence)
                }

                // Location
                if let location = encounter.displayLocationName {
                    HStack(spacing: FieldSpace.xs) {
                        Image(systemName: "mappin")
                            .font(.caption)
                            .foregroundColor(FieldColor.fadedInk)

                        Text(location)
                            .font(FieldType.callout)
                            .foregroundColor(FieldColor.fadedInk)
                        
                        
                        Spacer()

                        // Conditions
                        if !encounter.conditions.isEmpty {
                            FlowLayout(spacing: FieldSpace.xs) {
                                ForEach(encounter.conditions, id: \.self) { condition in
                                    TraitChip(condition)
                                }
                            }
                        }
                    }
                }


                // Notes
                if let notes = encounter.notes {
                    RuledLine()

                    Text(notes)
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.vintageInk)
                        .italic()
                }
            }
        }
    }
}

private struct EncounterDetailView: View {
    let encounter: Encounter
    let plant: Plant

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var notes: String
    @State private var showDeleteConfirmation = false
    @State private var isSaving = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isSavingPhoto = false
    @State private var showLocationPicker = false
    @State private var selectedLocation: SelectedLocation?
    @State private var locationLabel: String

    init(encounter: Encounter, plant: Plant) {
        self.encounter = encounter
        self.plant = plant
        _notes = State(initialValue: encounter.notes ?? "")
        _locationLabel = State(initialValue: encounter.locationLabel ?? "")
        // Initialize selected location from encounter
        if let name = encounter.displayLocationName {
            _selectedLocation = State(initialValue: SelectedLocation(
                name: name,
                subtitle: encounter.locationName,
                coordinate: encounter.coordinates
            ))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.lg) {
                if encounter.hasPhoto {
                    EncounterPhotoView(encounter: encounter, height: 220)
                } else {
                    // Tappable placeholder to add photo
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: FieldRadius.sm)
                                .fill(FieldColor.illustrationBg)

                            VStack(spacing: FieldSpace.xs) {
                                Image(systemName: isSavingPhoto ? "arrow.triangle.2.circlepath" : "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(FieldColor.accent.opacity(0.6))

                                Text(isSavingPhoto ? "Saving..." : "Tap to add photo")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                            }
                        }
                        .frame(height: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: FieldRadius.sm)
                                .stroke(FieldColor.accent.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .disabled(isSavingPhoto)
                }

                VintageCard {
                    VStack(alignment: .leading, spacing: FieldSpace.sm) {
                        Text(encounter.date, style: .date)
                            .font(FieldType.bodyEmphasized)
                            .foregroundColor(FieldColor.vintageInk)

                        // Tappable location row
                        Button {
                            showLocationPicker = true
                        } label: {
                            HStack(spacing: FieldSpace.xs) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.body)
                                    .foregroundColor(selectedLocation != nil ? FieldColor.accent : FieldColor.fadedInk)

                                if let location = selectedLocation {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(location.name)
                                            .font(FieldType.callout)
                                            .foregroundColor(FieldColor.ink)
                                            .lineLimit(1)
                                        if let subtitle = location.subtitle, subtitle != location.name {
                                            Text(subtitle)
                                                .font(FieldType.caption)
                                                .foregroundColor(FieldColor.fadedInk)
                                                .lineLimit(1)
                                        }
                                    }
                                } else {
                                    Text("Add Location")
                                        .font(FieldType.callout)
                                        .foregroundColor(FieldColor.fadedInk)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                            }
                        }
                        .buttonStyle(.plain)

                        HStack {
                            Text("Confidence")
                                .font(FieldType.caption)
                                .foregroundColor(FieldColor.fadedInk)

                            Spacer()

                            ConfidencePill(confidence: encounter.confidence)
                        }

                        if !encounter.conditions.isEmpty {
                            FlowLayout(spacing: FieldSpace.xs) {
                                ForEach(encounter.conditions, id: \.self) { condition in
                                    TraitChip(condition)
                                }
                            }
                        }
                    }
                }

                VintageCard {
                    VStack(alignment: .leading, spacing: FieldSpace.sm) {
                        Text("Field Notes")
                            .font(FieldType.bodyEmphasized)
                            .foregroundColor(FieldColor.vintageInk)

                        TextEditor(text: $notes)
                            .font(FieldType.body)
                            .foregroundColor(FieldColor.ink)
                            .scrollContentBackground(.hidden)
                            .frame(height: 140)
                            .padding(FieldSpace.xs)
                            .background(FieldColor.surface)
                            .cornerRadius(FieldRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: FieldRadius.sm)
                                    .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
                            )
                    }
                }

                PrimaryButton(isSaving ? "Saving..." : "Save Changes", isEnabled: !isSaving) {
                    saveChanges()
                }
            }
            .padding(FieldSpace.md)
        }
        .background(FieldColor.agedPaper)
        .navigationTitle("Edit Observation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button("Delete") {
                    showDeleteConfirmation = true
                }
            }
        }
        .confirmationDialog(
            "Delete Observation?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Observation", role: .destructive) {
                deleteEncounter()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the observation permanently.")
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await saveEncounterPhoto(from: newItem)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(
                selectedLocation: $selectedLocation,
                customLabel: $locationLabel
            )
        }
    }

    private func saveEncounterPhoto(from item: PhotosPickerItem) async {
        isSavingPhoto = true
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                isSavingPhoto = false
                return
            }

            let filename = try await PhotoStorageService.shared.savePhoto(image, for: encounter.id)
            encounter.photoFileName = filename
            try modelContext.save()
        } catch {
            print("Failed to save encounter photo: \(error)")
        }
        isSavingPhoto = false
    }

    private func saveChanges() {
        isSaving = true

        // Save notes
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        encounter.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

        // Save location changes
        encounter.locationName = selectedLocation?.name
        let trimmedLabel = locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        encounter.locationLabel = trimmedLabel.isEmpty ? nil : trimmedLabel
        if let coordinate = selectedLocation?.coordinate {
            encounter.latitude = coordinate.latitude
            encounter.longitude = coordinate.longitude
        } else {
            encounter.latitude = nil
            encounter.longitude = nil
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            isSaving = false
        }
    }

    private func deleteEncounter() {
        if let index = plant.encounters.firstIndex(where: { $0.id == encounter.id }) {
            plant.encounters.remove(at: index)
        }
        modelContext.delete(encounter)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            dismiss()
        }
    }
}

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    PlantDetailView(plant: Plant(...))
//}
