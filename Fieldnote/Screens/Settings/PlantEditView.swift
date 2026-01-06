//
//  PlantEditView.swift
//  Fieldnote
//
//  Form for editing custom plant catalog entries
//

import SwiftUI
import SwiftData

struct PlantEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plant: Plant

    @State private var commonName: String
    @State private var scientificName: String
    @State private var family: String
    @State private var habitat: String
    @State private var nativeRange: String
    @State private var summary: String
    @State private var traitsText: String
    @State private var saveError: String?

    init(plant: Plant) {
        self.plant = plant
        _commonName = State(initialValue: plant.commonName)
        _scientificName = State(initialValue: plant.scientificName)
        _family = State(initialValue: plant.family)
        _habitat = State(initialValue: plant.habitat ?? "")
        _nativeRange = State(initialValue: plant.nativeRange ?? "")
        _summary = State(initialValue: plant.summary)
        _traitsText = State(initialValue: plant.traits.joined(separator: ", "))
    }

    var body: some View {
        Form {
            Section("Names") {
                TextField("Common name", text: $commonName)
                TextField("Scientific name", text: $scientificName)
                TextField("Family", text: $family)
            }

            Section("Habitat & Range") {
                TextField("Habitat", text: $habitat)
                TextField("Native range", text: $nativeRange)
            }

            Section("Details") {
                TextField("Traits (comma separated)", text: $traitsText)
                TextEditor(text: $summary)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle("Edit Plant")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .alert("Unable to Save", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            if let saveError {
                Text(saveError)
            }
        }
    }

    private func saveChanges() {
        let trimmedCommon = commonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCommon.isEmpty else {
            saveError = "Common name cannot be empty."
            return
        }

        plant.commonName = trimmedCommon
        plant.scientificName = scientificName.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.family = family.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHabitat = habitat.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.habitat = trimmedHabitat.isEmpty ? nil : trimmedHabitat
        let trimmedRange = nativeRange.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.nativeRange = trimmedRange.isEmpty ? nil : trimmedRange
        plant.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)

        let traits = traitsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        plant.traits = traits

        plant.updatedAt = Date()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = "Please try again."
        }
    }
}
