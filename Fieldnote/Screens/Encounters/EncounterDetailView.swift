//
//  EncounterDetailView.swift
//  Fieldnote
//
//  Detail view for editing an individual encounter/observation
//

import SwiftUI
import PhotosUI
import SwiftData

struct EncounterDetailView: View {
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
    @State private var selectedConditions: Set<String>

    private let availableConditions = ["sun", "shade", "wet", "dry", "snow", "windy", "hot", "cold"]

    init(encounter: Encounter, plant: Plant) {
        self.encounter = encounter
        self.plant = plant
        _notes = State(initialValue: encounter.notes ?? "")
        _locationLabel = State(initialValue: encounter.locationLabel ?? "")
        _selectedConditions = State(initialValue: Set(encounter.conditions))
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
                // Show existing photos
                if encounter.hasPhoto {
                    EncounterPhotoView(encounter: encounter, height: 220)
                }

                // Add Photo button (always visible)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: FieldSpace.xs) {
                        Image(systemName: isSavingPhoto ? "arrow.triangle.2.circlepath" : "plus.circle.fill")
                            .font(.body)
                        Text(isSavingPhoto ? "Saving..." : "Add Photo")
                            .font(FieldType.callout)
                    }
                    .foregroundColor(FieldColor.accent)
                    .padding(.vertical, FieldSpace.sm)
                    .padding(.horizontal, FieldSpace.md)
                    .background(FieldColor.surface)
                    .cornerRadius(FieldRadius.pill)
                    .overlay(
                        RoundedRectangle(cornerRadius: FieldRadius.pill)
                            .stroke(FieldColor.accent.opacity(0.4), lineWidth: 1)
                    )
                }
                .disabled(isSavingPhoto)

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

            // Use indexed save, based on current photo count
            let index = encounter.photoFileNames.count
            let filename = try await PhotoStorageService.shared.savePhoto(image, for: encounter.id, index: index)
            encounter.photoFileNames.append(filename)
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

        // Save conditions
        encounter.conditions = Array(selectedConditions)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            isSaving = false
        }
    }

    private func deleteEncounter() {
        if var encounters = plant.encounters,
           let index = encounters.firstIndex(where: { $0.id == encounter.id }) {
            encounters.remove(at: index)
            plant.encounters = encounters
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
