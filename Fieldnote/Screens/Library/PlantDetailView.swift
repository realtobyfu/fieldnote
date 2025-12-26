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
                            EncounterCard(encounter: encounter)
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
            // Main illustration
            ZStack {
                PlantIllustrationView(plant: plant, size: .hero)
                    .bookPageBorder(padding: FieldSpace.md, cornerRadius: FieldRadius.lg)
                    .background(FieldColor.surface)
                    .cornerRadius(FieldRadius.lg)

                if shouldOfferCustomIllustration {
                    PhotosPicker(selection: $selectedIllustrationItem, matching: .images) {
                        VStack(spacing: FieldSpace.xs) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 28, weight: .medium))
                            Text(isSavingIllustration ? "Saving..." : "Add Illustration")
                                .font(FieldType.caption)
                        }
                        .foregroundColor(FieldColor.accent)
                        .padding(.vertical, FieldSpace.xs)
                        .padding(.horizontal, FieldSpace.sm)
                        .background(
                            RoundedRectangle(cornerRadius: FieldRadius.sm)
                                .fill(FieldColor.surface.opacity(0.9))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: FieldRadius.sm)
                                .stroke(FieldColor.bookBorder.opacity(0.5), lineWidth: 0.5)
                        )
                    }
                    .disabled(isSavingIllustration)
                }
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

// Previews disabled - require SwiftData ModelContainer setup
//#Preview {
//    PlantDetailView(plant: Plant(...))
//}
