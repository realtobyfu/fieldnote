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

    let availableConditions = ["sun", "shade", "wet", "dry", "snow", "windy", "hot", "cold"]
    let placeholderSymbols = ["leaf.fill", "camera.fill", "sun.max.fill", "cloud.fill", "tree.fill", "allergens.fill"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FieldSpace.lg) {
                    // Preview image
                    Group {
                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(FieldRadius.lg)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: FieldRadius.lg)
                                    .fill(FieldColor.accent.opacity(0.3))

                                Image(systemName: placeholderSymbols.randomElement() ?? "leaf.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(FieldColor.accent)
                            }
                            .frame(height: 200)
                        }
                    }
                    .padding(.horizontal, FieldSpace.md)

                    // Form sections
                    VStack(spacing: FieldSpace.md) {
                        // Plant identification
                        FieldCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Plant Identification")
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.ink)

                                TextField("Common name", text: $commonName)
                                    .textFieldStyle(.roundedBorder)

                                TextField("Scientific name (optional)", text: $scientificName)
                                    .textFieldStyle(.roundedBorder)

                                TextField("Family", text: $family)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        // Confidence
                        FieldCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                HStack {
                                    Text("Confidence")
                                        .font(FieldType.bodyEmphasized)
                                        .foregroundColor(FieldColor.ink)

                                    Spacer()

                                    ConfidencePill(confidence: confidence)
                                }

                                Slider(value: $confidence, in: 0.0...1.0)
                                    .tint(FieldColor.accent)
                            }
                        }

                        // Location
                        FieldCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Location")
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.ink)

                                TextField("Location name (optional)", text: $locationName)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        // Conditions
                        FieldCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Conditions")
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.ink)

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
                        FieldCard {
                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Notes")
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.ink)

                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(FieldSpace.xs)
                                    .background(FieldColor.paper)
                                    .cornerRadius(FieldRadius.sm)
                            }
                        }

                        // Save button
                        PrimaryButton("Save Encounter", isEnabled: !commonName.isEmpty) {
                            saveEncounter()
                        }
                    }
                    .padding(.horizontal, FieldSpace.md)
                }
                .padding(.vertical, FieldSpace.md)
            }
            .background(FieldColor.paper)
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

    // MARK: - Save Encounter

    private func saveEncounter() {
        // Create new encounter
        let encounter = Encounter(
            date: Date(),
            locationName: locationName.isEmpty ? nil : locationName,
            coordinates: nil,
            photoPlaceholder: placeholderSymbols.randomElement() ?? "leaf.fill",
            confidence: confidence,
            notes: notes.isEmpty ? nil : notes,
            conditions: Array(selectedConditions)
        )

        // Check if plant exists
        if let existingPlant = store.plants.first(where: { $0.commonName == commonName }) {
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
