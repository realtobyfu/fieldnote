//
//  PlantManagementView.swift
//  Fieldnote
//
//  Management screen for custom illustrations and catalog entries
//

import SwiftUI
import UIKit

struct PlantManagementView: View {
    @Environment(\.appStore) private var store
    @State private var plantToRemoveIllustration: Plant?
    @State private var plantToDelete: Plant?

    var body: some View {
        Group {
            if let appStore = store {
                managementContent(appStore: appStore)
            } else {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app.")
                )
            }
        }
        .fieldListBackground()
        .navigationTitle("Plant Catalog")
        .confirmationDialog(
            "Remove Illustration?",
            isPresented: Binding(
                get: { plantToRemoveIllustration != nil },
                set: { if !$0 { plantToRemoveIllustration = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let plant = plantToRemoveIllustration, let appStore = store {
                    Task {
                        await appStore.removeCustomIllustration(from: plant)
                    }
                }
                plantToRemoveIllustration = nil
            }
            Button("Cancel", role: .cancel) {
                plantToRemoveIllustration = nil
            }
        } message: {
            if let plant = plantToRemoveIllustration {
                Text("Remove the custom illustration for \(plant.commonName)? The plant will use the default illustration.")
            }
        }
        .alert("Delete Plant?", isPresented: Binding(
            get: { plantToDelete != nil },
            set: { if !$0 { plantToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let plant = plantToDelete, let appStore = store {
                    appStore.deletePlant(plant)
                }
                plantToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                plantToDelete = nil
            }
        } message: {
            if let plant = plantToDelete {
                Text("This will remove \(plant.commonName) and all of its encounters.")
            }
        }
    }

    @ViewBuilder
    private func managementContent(appStore: AppStore) -> some View {
        List {
            Section("Overview") {
                HStack {
                    Label("Total Plants", systemImage: "leaf.fill")
                    Spacer()
                    Text("\(appStore.plants.count)")
                        .foregroundColor(FieldColor.mutedInk)
                }

                if !appStore.plantsWithCustomIllustrations.isEmpty {
                    HStack {
                        Label("Custom Illustrations", systemImage: "paintbrush")
                        Spacer()
                        Text("\(appStore.plantsWithCustomIllustrations.count)")
                            .foregroundColor(FieldColor.mutedInk)
                    }
                }
            }

            Section("Custom Illustrations") {
                if appStore.plantsWithCustomIllustrations.isEmpty {
                    Text("No custom illustrations yet.")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.mutedInk)
                } else {
                    ForEach(appStore.plantsWithCustomIllustrations) { plant in
                        CustomIllustrationRow(plant: plant) {
                            plantToRemoveIllustration = plant
                        }
                    }
                }
            }

            Section("Catalog Entries") {
                ForEach(appStore.plants.sorted { $0.commonName < $1.commonName }) { plant in
                    NavigationLink {
                        PlantEditView(plant: plant)
                    } label: {
                        PlantCatalogRow(plant: plant)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            plantToDelete = plant
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

private struct PlantCatalogRow: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            Text(plant.commonName)
                .font(FieldType.bodyEmphasized)
                .foregroundColor(FieldColor.ink)

            HStack(spacing: FieldSpace.sm) {
                Text(plant.scientificName)
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.mutedInk)
                Spacer()
                if plant.encounterCount > 0 {
                    Label("\(plant.encounterCount)", systemImage: "camera.fill")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.mutedInk)
                }
            }
        }
    }
}

private struct CustomIllustrationRow: View {
    let plant: Plant
    let onDelete: () -> Void

    @State private var thumbnailImage: UIImage?

    var body: some View {
        HStack(spacing: FieldSpace.sm) {
            Group {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(FieldColor.illustrationBg)
                        .overlay(
                            ProgressView()
                                .tint(FieldColor.fadedInk)
                        )
                }
            }
            .frame(width: 44, height: 44)
            .cornerRadius(FieldRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .stroke(FieldColor.bookBorder.opacity(0.3), lineWidth: 0.5)
            )

            Text(plant.commonName)
                .font(FieldType.body)
                .foregroundColor(FieldColor.ink)

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundColor(FieldColor.fadedInk)
            }
            .buttonStyle(.plain)
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let filename = plant.customIllustrationFileName else { return }
        thumbnailImage = await PlantIllustrationStorageService.shared.loadIllustration(filename: filename)
    }
}
