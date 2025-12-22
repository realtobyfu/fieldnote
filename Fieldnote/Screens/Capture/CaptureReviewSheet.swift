//
//  CaptureReviewSheet.swift
//  Fieldnote
//
//  Review sheet for captured plant photo with form to save encounter
//

import SwiftUI

struct CaptureReviewSheet: View {
    @Bindable var viewModel: CaptureViewModel
    var store: AppStore
    var capturedImage: UIImage?

    @Environment(\.dismiss) private var dismiss

    @State private var commonName = ""
    @State private var scientificName = ""
    @State private var family = ""
    @State private var confidence: Double = 0.75
    @State private var locationName = ""
    @State private var notes = ""
    @State private var selectedConditions: Set<String> = []
    @State private var isSaving = false

    let availableConditions = ["sun", "shade", "wet", "dry", "snow", "windy", "hot", "cold"]
    let placeholderSymbols = ["leaf.fill", "camera.fill", "sun.max.fill", "cloud.fill", "tree.fill", "allergens.fill"]

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
                                Text("Plant Identification")
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.vintageInk)

                                TextField("Common name", text: $commonName)
                                    .textFieldStyle(.roundedBorder)

                                TextField("Scientific name (optional)", text: $scientificName)
                                    .textFieldStyle(.roundedBorder)
                                    .italic()

                                TextField("Family", text: $family)
                                    .textFieldStyle(.roundedBorder)
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

                                TextField("Location name (optional)", text: $locationName)
                                    .textFieldStyle(.roundedBorder)
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
                                    .frame(height: 100)
                                    .padding(FieldSpace.xs)
                                    .background(FieldColor.illustrationBg)
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

    // MARK: - Photo Preview

    private var photoPreview: some View {
        Group {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
                    .overlay(
                        // Subtle sepia tint
                        Rectangle()
                            .fill(FieldColor.sepia.opacity(0.05))
                    )
                    .cornerRadius(FieldRadius.lg)
                    .overlay(
                        // Vintage frame
                        RoundedRectangle(cornerRadius: FieldRadius.lg)
                            .stroke(FieldColor.bookBorder, lineWidth: 1)
                            .padding(1)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: FieldRadius.lg)
                        .fill(FieldColor.illustrationBg)

                    VStack(spacing: FieldSpace.sm) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 48))
                            .foregroundColor(FieldColor.botanicalBrown.opacity(0.4))

                        Text("No photo captured")
                            .font(FieldType.callout)
                            .foregroundColor(FieldColor.fadedInk)
                    }
                }
                .frame(height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: FieldRadius.lg)
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
        let encounter = Encounter(
            id: encounterId,
            date: Date(),
            locationName: locationName.isEmpty ? nil : locationName,
            coordinates: nil,
            photoPlaceholder: placeholderSymbols.randomElement() ?? "leaf.fill",
            confidence: confidence,
            notes: notes.isEmpty ? nil : notes,
            conditions: Array(selectedConditions),
            photoFileName: photoFileName
        )

        // Check if plant exists
        if let existingPlant = store.plants.first(where: { $0.commonName.lowercased() == commonName.lowercased() }) {
            // Add encounter to existing plant
            store.addEncounter(encounter, to: existingPlant.id)
        } else {
            // Create new plant with this encounter
            let newPlant = Plant(
                commonName: commonName,
                scientificName: scientificName.isEmpty ? "Species unknown" : scientificName,
                family: family.isEmpty ? "Unknown" : family,
                traits: [],
                encounters: [encounter]
            )
            store.addPlant(newPlant)
        }

        isSaving = false

        // Dismiss and reset
        dismiss()
        viewModel.reset()
    }
}

#Preview {
    CaptureReviewSheet(
        viewModel: CaptureViewModel(),
        store: AppStore(),
        capturedImage: nil
    )
}
