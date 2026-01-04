//
//  AllEncountersView.swift
//  Fieldnote
//
//  Chronological list of all encounters with swipe-to-delete and tap-to-edit
//

import SwiftUI
import SwiftData

struct AllEncountersView: View {
    @Environment(\.appStore) private var store
    @Environment(\.modelContext) private var modelContext

    @State private var encounterToDelete: Encounter?

    var body: some View {
        Group {
            if let appStore = store {
                encountersContent(appStore: appStore)
            } else {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app.")
                )
            }
        }
        .navigationTitle("All Encounters")
    }

    @ViewBuilder
    private func encountersContent(appStore: AppStore) -> some View {
        Group {
            if appStore.allEncounters.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(appStore.allEncounters) { encounter in
                        if let plant = encounter.plant {
                            NavigationLink {
                                EncounterDetailView(encounter: encounter, plant: plant)
                            } label: {
                                EncounterListRow(encounter: encounter, plantName: plant.commonName)
                            }
                        }
                    }
                    .onDelete { offsets in
                        confirmDelete(at: offsets, appStore: appStore)
                    }
                }
                .listStyle(.plain)
            }
        }
        .confirmationDialog(
            "Delete Observation?",
            isPresented: Binding(
                get: { encounterToDelete != nil },
                set: { if !$0 { encounterToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let encounter = encounterToDelete {
                    deleteEncounter(encounter)
                }
                encounterToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                encounterToDelete = nil
            }
        } message: {
            Text("This removes the observation permanently.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: FieldSpace.md) {
            Image(systemName: "camera")
                .font(.system(size: 48))
                .foregroundColor(FieldColor.fadedInk)

            Text("No Encounters Yet")
                .font(FieldType.title3)
                .foregroundColor(FieldColor.ink)

            Text("Start capturing plants to see your observations here.")
                .font(FieldType.callout)
                .foregroundColor(FieldColor.mutedInk)
                .multilineTextAlignment(.center)
        }
        .padding(FieldSpace.xl)
    }

    private func confirmDelete(at offsets: IndexSet, appStore: AppStore) {
        if let index = offsets.first {
            encounterToDelete = appStore.allEncounters[index]
        }
    }

    private func deleteEncounter(_ encounter: Encounter) {
        // Remove from plant's encounters array
        if let plant = encounter.plant,
           let index = plant.encounters.firstIndex(where: { $0.id == encounter.id }) {
            plant.encounters.remove(at: index)
        }

        modelContext.delete(encounter)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete encounter: \(error)")
        }
    }
}

// MARK: - Encounter List Row

private struct EncounterListRow: View {
    let encounter: Encounter
    let plantName: String

    var body: some View {
        HStack(spacing: FieldSpace.sm) {
            // Photo thumbnail or placeholder
            Group {
                if encounter.hasPhoto {
                    EncounterPhotoThumbnail(encounter: encounter)
                } else {
                    RoundedRectangle(cornerRadius: FieldRadius.sm)
                        .fill(FieldColor.illustrationBg)
                        .overlay(
                            Image(systemName: "leaf.fill")
                                .font(.body)
                                .foregroundColor(FieldColor.fadedInk)
                        )
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(FieldRadius.sm)

            // Plant name, date, location
            VStack(alignment: .leading, spacing: 2) {
                Text(plantName)
                    .font(FieldType.bodyEmphasized)
                    .foregroundColor(FieldColor.ink)
                    .lineLimit(1)

                HStack(spacing: FieldSpace.xs) {
                    Text(encounter.date, style: .date)
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.mutedInk)

                    if let location = encounter.displayLocationName {
                        Text("•")
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.mutedInk)

                        Text(location)
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.mutedInk)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Confidence pill
            ConfidencePill(confidence: encounter.confidence)
        }
        .padding(.vertical, FieldSpace.xs)
    }
}
