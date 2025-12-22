//
//  PlantDetailView.swift
//  Fieldnote
//
//  Detail view for an individual plant
//

import SwiftUI

struct PlantDetailView: View {
    let plant: Plant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.lg) {
                // Hero image placeholder
                heroPlaceholder

                // Plant info card
                FieldCard {
                    VStack(alignment: .leading, spacing: FieldSpace.md) {
                        // Names
                        VStack(alignment: .leading, spacing: FieldSpace.xs) {
                            Text(plant.commonName)
                                .font(FieldType.title2)
                                .foregroundColor(FieldColor.ink)

                            ScientificNameText(plant.scientificName, size: .callout)
                        }

                        Divider()

                        // Family and confidence
                        HStack {
                            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                                Text("Family")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.mutedInk)
                                Text(plant.family)
                                    .font(FieldType.bodyEmphasized)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: FieldSpace.xs) {
                                Text("Confidence")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.mutedInk)
                                ConfidencePill(confidence: plant.averageConfidence)
                            }
                        }

                        // Traits
                        if !plant.traits.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Traits")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.mutedInk)

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
                        SectionHeader(title: "Encounters (\(plant.encounterCount))")

                        ForEach(plant.encounters.sorted(by: { $0.date > $1.date })) { encounter in
                            EncounterCard(encounter: encounter)
                        }
                    }
                }
            }
            .padding(FieldSpace.md)
        }
        .background(FieldColor.paper)
        .navigationTitle(plant.commonName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Placeholder

    private var heroPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FieldRadius.lg)
                .fill(placeholderColor)

            Image(systemName: plant.displayPlaceholder)
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
    }

    private var placeholderColor: Color {
        let colors: [Color] = [
            FieldColor.accent,
            FieldColor.botanicalBrown,
            Color.green.opacity(0.6),
            Color.blue.opacity(0.4),
            Color.orange.opacity(0.5),
            Color.purple.opacity(0.5)
        ]
        let hash = abs(plant.id.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Encounter Card

private struct EncounterCard: View {
    let encounter: Encounter

    var body: some View {
        FieldCard {
            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                // Date and confidence
                HStack {
                    Text(encounter.date, style: .date)
                        .font(FieldType.bodyEmphasized)
                        .foregroundColor(FieldColor.ink)

                    Spacer()

                    ConfidencePill(confidence: encounter.confidence)
                }

                // Location
                if let location = encounter.locationName {
                    HStack(spacing: FieldSpace.xs) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(FieldColor.mutedInk)

                        Text(location)
                            .font(FieldType.callout)
                            .foregroundColor(FieldColor.mutedInk)
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
                    Divider()

                    Text(notes)
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.ink)
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
