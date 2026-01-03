//
//  CatalogPlantDetailView.swift
//  Fieldnote
//
//  Detail view for undiscovered catalog plants
//

import SwiftUI

struct CatalogPlantDetailView: View {
    let catalogPlant: CatalogPlant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.lg) {
                // Hero botanical illustration (faded for undiscovered)
                heroIllustration

                // Curated photo gallery
                PlantPhotoGalleryView(plantName: catalogPlant.commonName)

                // Plant info card
                VintageCard {
                    VStack(alignment: .leading, spacing: FieldSpace.md) {
                        // Names
                        VStack(alignment: .leading, spacing: FieldSpace.xs) {
                            HStack {
                                Text(catalogPlant.commonName)
                                    .font(FieldType.displaySubtitle)
                                    .foregroundColor(FieldColor.vintageInk)

                                Spacer()

                                // Undiscovered badge
                                Text("Undiscovered")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                                    .padding(.horizontal, FieldSpace.sm)
                                    .padding(.vertical, FieldSpace.xs)
                                    .background(FieldColor.separator)
                                    .cornerRadius(FieldRadius.chip)
                            }

                            ScientificNameText(catalogPlant.scientificName, size: .callout)
                        }

                        RuledLine()

                        // Family and habitat
                        HStack {
                            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                                Text("Family")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                                Text(catalogPlant.family)
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.vintageInk)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: FieldSpace.xs) {
                                Text("Habitat")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                                Text(catalogPlant.habitat.capitalized)
                                    .font(FieldType.bodyEmphasized)
                                    .foregroundColor(FieldColor.vintageInk)
                            }
                        }

                        // Traits
                        if !catalogPlant.traits.isEmpty {
                            RuledLine()

                            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                                Text("Traits")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)

                                FlowLayout(spacing: FieldSpace.xs) {
                                    ForEach(catalogPlant.traits, id: \.self) { trait in
                                        TraitChip(trait)
                                    }
                                }
                            }
                        }

                        // Summary
                        if !catalogPlant.summary.isEmpty {
                            RuledLine()

                            Text(catalogPlant.summary)
                                .font(FieldType.callout)
                                .foregroundColor(FieldColor.ink)
                        }
                    }
                }

                // Hint to discover
                VintageCard {
                    HStack(spacing: FieldSpace.sm) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(FieldColor.accent)

                        VStack(alignment: .leading, spacing: FieldSpace.xs) {
                            Text("Haven't seen this one yet?")
                                .font(FieldType.bodyEmphasized)
                                .foregroundColor(FieldColor.vintageInk)

                            Text("Capture a photo when you find it to add it to your field journal.")
                                .font(FieldType.callout)
                                .foregroundColor(FieldColor.fadedInk)
                        }

                        Spacer()
                    }
                }
            }
            .padding(FieldSpace.md)
        }
        .background(FieldColor.agedPaper)
        .navigationTitle(catalogPlant.commonName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Illustration

    private var heroIllustration: some View {
        VStack(spacing: 0) {
            // Full color illustration in detail view
            BotanicalIllustrationView(
                catalogPlant.commonName,
                family: catalogPlant.family,
                size: .hero
            )
            .bookPageBorder(padding: FieldSpace.md, cornerRadius: FieldRadius.lg)
            .background(FieldColor.surface)
            .cornerRadius(FieldRadius.lg)

            // Scientific name plate
            ScientificNamePlate(name: catalogPlant.scientificName)
                .padding(.top, FieldSpace.sm)
                .padding(.horizontal, FieldSpace.lg)
        }
    }
}

#Preview {
    NavigationStack {
        CatalogPlantDetailView(catalogPlant: CatalogPlant.catalog.first!)
    }
}
