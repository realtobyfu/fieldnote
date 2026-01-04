//
//  SettingsView.swift
//  Fieldnote
//
//  Settings screen with app information and options
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.appStore) private var store
    @State private var plantToRemoveIllustration: Plant?

    private var appStore: AppStore {
        guard let store = store else {
            fatalError("AppStore not found in environment")
        }
        return store
    }

    var body: some View {
        List {
            // App Philosophy section
            Section {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Label {
                        Text("Offline-First")
                            .font(FieldType.bodyEmphasized)
                    } icon: {
                        Image(systemName: "icloud.slash.fill")
                            .foregroundColor(FieldColor.accent)
                    }

                    Text("Fieldnote stores all your observations locally on your device. Your field journal is yours, always accessible without an internet connection.")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, FieldSpace.xs)
            }

            // Data section
            Section("Data") {
                HStack {
                    Label("Total Plants", systemImage: "leaf.fill")
                    Spacer()
                    Text("\(appStore.plants.count)")
                        .foregroundColor(FieldColor.mutedInk)
                }

                NavigationLink {
                    AllEncountersView()
                } label: {
                    HStack {
                        Label("Total Encounters", systemImage: "camera.fill")
                        Spacer()
                        Text("\(appStore.allEncounters.count)")
                            .foregroundColor(FieldColor.mutedInk)
                    }
                }

                Button {
                    // Export functionality - placeholder
                } label: {
                    HStack {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(FieldColor.mutedInk)
                    }
                }
                .disabled(true)
                .foregroundColor(FieldColor.mutedInk)
            }

            // Custom Illustrations section (only show if any exist)
            if !appStore.plantsWithCustomIllustrations.isEmpty {
                Section("Custom Illustrations") {
                    ForEach(appStore.plantsWithCustomIllustrations) { plant in
                        CustomIllustrationRow(plant: plant) {
                            plantToRemoveIllustration = plant
                        }
                    }
                }
            }

            // About section
            Section("About") {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Text("Fieldnote")
                        .font(FieldType.title3)
                        .foregroundColor(FieldColor.ink)

                    Text("A field journal for mindful plant observation. Document your encounters with the botanical world, one observation at a time.")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: FieldSpace.xs) {
                        Text("Version")
                            .font(FieldType.caption)
                        Text("1.0.0")
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.mutedInk)
                    }
                    .padding(.top, FieldSpace.xs)
                }
                .padding(.vertical, FieldSpace.xs)
            }

            // Design section
            Section("Design Philosophy") {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Text("Confidence-Forward")
                        .font(FieldType.bodyEmphasized)
                        .foregroundColor(FieldColor.ink)

                    Text("We never over-claim certainty. Every identification includes a confidence level based on your observations. Low confidence plants are opportunities to learn, not failures.")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, FieldSpace.xs)
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Remove Illustration?",
            isPresented: Binding(
                get: { plantToRemoveIllustration != nil },
                set: { if !$0 { plantToRemoveIllustration = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let plant = plantToRemoveIllustration {
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
    }
}

// MARK: - Custom Illustration Row

private struct CustomIllustrationRow: View {
    let plant: Plant
    let onDelete: () -> Void

    @State private var thumbnailImage: UIImage?

    var body: some View {
        HStack(spacing: FieldSpace.sm) {
            // Thumbnail
            Group {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(FieldColor.illustrationBg)
                }
            }
            .frame(width: 44, height: 44)
            .cornerRadius(FieldRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.sm)
                    .stroke(FieldColor.bookBorder.opacity(0.3), lineWidth: 0.5)
            )

            // Plant name
            Text(plant.commonName)
                .font(FieldType.body)
                .foregroundColor(FieldColor.ink)

            Spacer()

            // Delete button
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
