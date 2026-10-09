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

    @Environment(\.capturePlant) private var capturePlant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BookIdentity(label: "Specimen · \(FieldBook.encounterCount(plant.encounterCount))",
                             name: plant.commonName, scientificName: plant.scientificName)
                VStack(spacing: 10) {
                    BookPlantImage(plant: plant)
                        .frame(maxWidth: .infinity).frame(height: 232)
                    if !isShowingCustomIllustration {
                        IllustrationCreditLine(plantName: plant.commonName, family: plant.family,
                                               scientificName: plant.scientificName)
                    }
                }
                Divider()
                BookRecognition(traits: plant.traits, summary: displaySummary)
                Text("Your encounters").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
                if let encounters = plant.encounters, !encounters.isEmpty {
                    ForEach(encounters.sorted { $0.date > $1.date }) { encounter in
                        NavigationLink {
                            EncounterDetailView(encounter: encounter, plant: plant)
                        } label: {
                            HStack(spacing: 16) {
                                if encounter.hasPhoto { EncounterPhotoThumbnail(encounter: encounter) }
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(encounter.date, style: .date).font(.body.weight(.medium))
                                    if let location = encounter.displayLocationName {
                                        Label(location, systemImage: "mappin").font(.caption)
                                            .foregroundStyle(FieldColor.mutedInk)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption2)
                            }
                            .frame(minHeight: 58).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                BookDisclosure(title: "Botanical details") {
                    VStack(alignment: .leading, spacing: 14) {
                        LabeledContent("Family", value: plant.family)
                        if let habitat = plant.habitat, !habitat.isEmpty {
                            LabeledContent("Habitat", value: habitat.capitalized)
                        }
                        if let range = plant.nativeRange, !range.isEmpty {
                            Text(range).font(.body)
                        }
                    }.font(.subheadline)
                }
                BookDisclosure(title: "Photographs & illustration") {
                    PlantPhotoGalleryView(plantName: plant.commonName, userPhotoFilenames: encounterPhotoFilenames)
                    PhotosPicker(selection: $selectedIllustrationItem, matching: .images) {
                        Label("Choose illustration", systemImage: "photo.badge.plus")
                    }.disabled(isSavingIllustration)
                    if let illustrationError { Text(illustrationError).font(.caption) }
                }
            }
            .foregroundStyle(FieldColor.ink)
            .padding(24)
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle(plant.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let capturePlant {
                    Button(action: capturePlant) { Label("Capture plant", systemImage: "camera") }
                }
            }
        }
        .onChange(of: selectedIllustrationItem) { _, newItem in
            guard let newItem else { return }
            Task { await saveCustomIllustration(from: newItem) }
        }
    }

}

extension PlantDetailView {
    /// Existing SwiftData records may still contain the old 300-character
    /// pipeline truncation. Resolve only those records against the corrected
    /// bundled packs so user-authored summaries remain untouched.
    private var displaySummary: String {
        guard plant.summary.hasSuffix("…"),
              let completeSummary = BundledRegionPacks.completeSummary(
                forScientificName: plant.scientificName
              ),
              completeSummary.count > plant.summary.count else {
            return plant.summary
        }
        return completeSummary
    }

    /// True when a user-supplied illustration is being displayed instead of the
    /// built-in plate. Attribution keys off the house asset, so it must be
    /// suppressed here — the credit isn't for the user's image.
    private var isShowingCustomIllustration: Bool {
        plant.customIllustrationFileName?.isEmpty == false
    }

    private var encounterPhotoFilenames: [String] {
        (plant.encounters ?? [])
            .sorted { $0.date > $1.date }
            .compactMap { $0.photoFileName }
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
