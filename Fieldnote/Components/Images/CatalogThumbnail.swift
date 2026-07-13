//
//  CatalogThumbnail.swift
//  Fieldnote
//
//  Chooses the right card imagery, illustration-first: a hand-authored botanical
//  plate whenever one exists for the plant, otherwise the licensed iNaturalist
//  photo (region-pack taxa), otherwise the illustration placeholder. Regional
//  photos also cover the illustration's loading/offline failure.
//  See RegionalizedCatalogPlan.md (C3).
//

import SwiftUI

struct CatalogThumbnail: View {
    let catalogPlant: CatalogPlant
    let isDiscovered: Bool
    var size: BotanicalIllustrationView.IllustrationSize = .card

    /// True when a hand-drawn plate exists for this plant — illustration wins.
    private var hasIllustration: Bool {
        IllustrationService.hasIllustration(
            for: catalogPlant.commonName,
            scientificName: catalogPlant.scientificName,
            family: catalogPlant.family
        )
    }

    var body: some View {
        if !hasIllustration, let url = photoURL {
            // No plate for this plant (typically a new regional taxon): show its photo.
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .saturation(isDiscovered ? 1 : 0.4)         // muted (not fully gray) when undiscovered
                        .opacity(isDiscovered ? 1 : 0.75)
                case .empty, .failure:
                    illustrationFallback
                @unknown default:
                    illustrationFallback
                }
            }
        } else {
            // Illustration exists (or nothing to show): use the plate / placeholder.
            illustrationFallback
        }
    }

    private var photoURL: URL? {
        guard let raw = catalogPlant.photoURL, !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    @ViewBuilder
    private var illustrationFallback: some View {
        if isDiscovered {
            BotanicalIllustrationView(catalogPlant.commonName, family: catalogPlant.family, scientificName: catalogPlant.scientificName, size: size)
        } else {
            UndiscoveredIllustrationView(catalogPlant.commonName, family: catalogPlant.family, scientificName: catalogPlant.scientificName, size: size)
        }
    }
}
