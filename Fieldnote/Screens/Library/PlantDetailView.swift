//
//  PlantDetailView.swift
//  Fieldnote
//
//  Detail view for an individual plant with vintage book styling
//

import SwiftUI

struct PlantDetailView: View {
    let plant: Plant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.lg) {
                // Hero botanical illustration
                heroIllustration

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
                                Text("Confidence")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                                ConfidencePill(confidence: plant.averageConfidence)
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
    }

    // MARK: - Hero Illustration

    private var heroIllustration: some View {
        VStack(spacing: 0) {
            // Main illustration
            BotanicalIllustrationView(
                plant.commonName,
                family: plant.family,
                size: .hero
            )
            .bookPageBorder(padding: FieldSpace.md, cornerRadius: FieldRadius.lg)
            .background(FieldColor.surface)
            .cornerRadius(FieldRadius.lg)

            // Scientific name plate
            ScientificNamePlate(name: plant.scientificName)
                .padding(.top, FieldSpace.sm)
                .padding(.horizontal, FieldSpace.lg)
        }
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
                if let location = encounter.locationName {
                    HStack(spacing: FieldSpace.xs) {
                        Image(systemName: "mappin")
                            .font(.caption)
                            .foregroundColor(FieldColor.fadedInk)

                        Text(location)
                            .font(FieldType.callout)
                            .foregroundColor(FieldColor.fadedInk)
                    }
                }

                // Conditions
                if !encounter.conditions.isEmpty {
                    FlowLayout(spacing: FieldSpace.xs) {
                        ForEach(encounter.conditions, id: \.self) { condition in
                            TraitChip(condition)
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

#Preview {
    NavigationStack {
        PlantDetailView(plant: Plant.mockDandelion)
    }
}

#Preview("Low Confidence") {
    NavigationStack {
        PlantDetailView(plant: Plant.mockCedar)
    }
}

#Preview("Many Encounters") {
    NavigationStack {
        PlantDetailView(plant: Plant.mockMaple)
    }
}
