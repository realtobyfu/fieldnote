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
                if hasIllustration {
                    // Standard layout: Hero botanical illustration
                    heroIllustration
                        .onAppear {
                            print("DEBUG PlantDetailView: Loading plant '\(plant.commonName)' (standard layout)")
                            print("DEBUG PlantDetailView: summary length=\(plant.summary.count)")
                        }

                    // Curated photo gallery (exact-match only)
                    PlantPhotoGalleryView(
                        plantName: plant.commonName,
                        userPhotoFilenames: encounterPhotoFilenames
                    )
                } else {
                    // Gallery-first layout: No hero, prominent gallery at top
                    galleryFirstHeader
                        .onAppear {
                            print("DEBUG PlantDetailView: Loading plant '\(plant.commonName)' (gallery-first layout)")
                        }
                }

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


                        // Family & Habitat row
                        HStack(alignment: .top, spacing: FieldSpace.lg) {
                            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                                Text("Family")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                                Text(plant.family)
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.vintageInk)
                            }
                            Spacer()

                            if let habitat = plant.habitat, !habitat.isEmpty {
                                VStack(alignment: .leading, spacing: FieldSpace.xs) {
                                    Text("Habitat")
                                        .font(FieldType.caption)
                                        .foregroundColor(FieldColor.fadedInk)
                                    Text(habitat.capitalized)
                                        .font(FieldType.bodyEmphasized)
                                        .foregroundColor(FieldColor.vintageInk)
                                }
                            }
                        }

                        // Native Range
                        if let nativeRange = plant.nativeRange, !nativeRange.isEmpty {
                            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                                Text("Native Range")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                                Text(nativeRange)
                                    .font(FieldType.body)
                                    .foregroundColor(FieldColor.vintageInk)
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

                        if !displaySummary.isEmpty {
                            ExpandablePlantSummary(text: displaySummary)
                        }



                    }
                }

                // Encounters section
                if !(plant.encounters ?? []).isEmpty {
                    VStack(alignment: .leading, spacing: FieldSpace.md) {
                        SectionHeader(title: "Observations (\(plant.encounterCount))", showRuledLine: true)

                        ForEach((plant.encounters ?? []).sorted(by: { $0.date > $1.date })) { encounter in
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

            // Attribution — renders only for real, human-authored plates, and
            // only when the built-in illustration is what's on screen. A user's
            // own custom illustration must never inherit the house plate's credit.
            if !isShowingCustomIllustration {
                IllustrationCreditLine(
                    plantName: plant.commonName,
                    family: plant.family
                )
                .padding(.top, FieldSpace.xs)
                .padding(.horizontal, FieldSpace.lg)
            }

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

    /// Check if the plant has any illustration (custom or built-in)
    private var hasIllustration: Bool {
        let hasCustom = (plant.customIllustrationFileName?.isEmpty == false)
        let hasBuiltIn = IllustrationService.hasIllustration(for: plant.commonName, family: plant.family)
        return hasCustom || hasBuiltIn
    }

    private var shouldOfferCustomIllustration: Bool {
        !hasIllustration
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

    // MARK: - Gallery-First Layout

    /// Header for gallery-first layout (when no illustration is available)
    private var galleryFirstHeader: some View {
        VStack(alignment: .leading, spacing: FieldSpace.md) {
            // Prominent gallery view - first photo larger, rest in horizontal scroll
            PlantPhotoGalleryView(
                plantName: plant.commonName,
                userPhotoFilenames: encounterPhotoFilenames,
                isProminent: true
            )

            // Scientific name plate (without hero)
            ScientificNamePlate(name: plant.scientificName)
                .padding(.horizontal, FieldSpace.lg)

            // Option to add custom illustration
            PhotosPicker(selection: $selectedIllustrationItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                        .foregroundColor(FieldColor.accent)
                    Text("Add illustration")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.accent)
                }
                .padding(.horizontal, FieldSpace.lg)
            }
            .disabled(isSavingIllustration)
        }
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

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    PlantDetailView(plant: Plant(...))
//}
