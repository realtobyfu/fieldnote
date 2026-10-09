//
//  CatalogPlantDetailView.swift
//  Fieldnote
//
//  Detail view for undiscovered catalog plants
//

import SwiftUI

struct CatalogPlantDetailView: View {
    let catalogPlant: CatalogPlant
    var photoFirst = false
    @Environment(\.appStore) private var store
    @Environment(\.capturePlant) private var capturePlant

    /// What the full-screen viewer is currently showing (nil = closed).
    @State private var fullScreen: FullScreenTarget?

    /// Licensed iNaturalist photos for the gallery. Seeded synchronously with the
    /// region pack's default photo, then replaced by the taxon's curated photo set
    /// once fetched (see `loadRemotePhotos`).
    @State private var remotePhotos: [RemoteGalleryPhoto] = []

    private enum FullScreenTarget: Identifiable {
        case illustration(String)   // asset name
        case photo(URL)
        var id: String {
            switch self {
            case .illustration(let name): return "illustration:\(name)"
            case .photo(let url): return "photo:\(url.absoluteString)"
            }
        }
    }

    /// True when a hand-drawn plate exists for this plant.
    private var hasIllustration: Bool {
        illustrationAssetName != nil
    }

    /// The resolved plate asset name for this plant, if any.
    private var illustrationAssetName: String? {
        IllustrationService.illustrationName(
            for: catalogPlant.commonName,
            scientificName: catalogPlant.scientificName,
            family: catalogPlant.family
        )
    }

    /// Opens the full-screen viewer on the best hero image (plate, else photo).
    private func presentHero() {
        if let name = illustrationAssetName {
            fullScreen = .illustration(name)
        } else if let url = photoURL {
            fullScreen = .photo(url)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BookIdentity(label: "Field guide", name: catalogPlant.commonName,
                             scientificName: catalogPlant.scientificName)
                if photoFirst {
                    NearbyPlantImage(plant: catalogPlant)
                        .frame(height: 236).frame(maxWidth: .infinity).clipped()
                        .clipShape(.rect(cornerRadius: 14))
                    if PlantPhotoService.photoNames(for: catalogPlant.commonName).isEmpty { photoAttributionLine }
                } else { expandableHero }
                Label(store?.isDiscovered(catalogPlant) == true ? "In your herbarium" : "Yet to discover",
                      systemImage: store?.isDiscovered(catalogPlant) == true ? "checkmark.circle" : "circle.dotted")
                    .font(.subheadline).foregroundStyle(FieldBook.cover)
                Divider()
                BookRecognition(traits: catalogPlant.traits, summary: catalogPlant.summary)
                if let existing = store?.plants.first(where: {
                    CatalogPlant.scientificNameKey($0.scientificName) == catalogPlant.scientificNameKey
                }) {
                    NavigationLink(value: existing) {
                        Label("View your \(FieldBook.encounterCount(existing.encounterCount))", systemImage: "book.closed")
                    }.font(.subheadline).frame(minHeight: 44)
                }
                if let capturePlant {
                    Button(action: capturePlant) { Label("Capture a discovery", systemImage: "camera") }
                        .font(.body.weight(.medium)).frame(minHeight: 48)
                }
                BookDisclosure(title: "Botanical details") {
                    VStack(alignment: .leading, spacing: 14) {
                        if !catalogPlant.family.isEmpty { LabeledContent("Family", value: catalogPlant.family) }
                        if !catalogPlant.habitat.isEmpty { LabeledContent("Habitat", value: catalogPlant.habitat.capitalized) }
                        if !catalogPlant.nativeRange.isEmpty { Text(catalogPlant.nativeRange) }
                    }.font(.subheadline)
                }
                BookDisclosure(title: "Photographs & botanical plate") {
                    PlantPhotoGalleryView(plantName: catalogPlant.commonName, remotePhotos: galleryRemotePhotos)
                    if photoFirst, hasIllustration { expandableHero }
                }
            }
            .foregroundStyle(FieldColor.ink)
            .padding(24)
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle(catalogPlant.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let capturePlant {
                    Button(action: capturePlant) { Label("Capture plant", systemImage: "camera") }
                }
            }
        }
        .task(id: catalogPlant.id) {
            await loadRemotePhotos()
        }
        .fullScreenCover(item: $fullScreen) { target in
            switch target {
            case .illustration(let name):
                IllustrationFullScreenView(
                    assetName: name,
                    caption: AnyView(
                        IllustrationCreditLine(
                            plantName: catalogPlant.commonName,
                            family: catalogPlant.family,
                            scientificName: catalogPlant.scientificName
                        )
                        .environment(\.colorScheme, .dark)
                    )
                )
            case .photo(let url):
                IllustrationFullScreenView(
                    assetName: nil,
                    photoURL: url,
                    caption: catalogPlant.photoAttribution.map { attribution in
                        AnyView(
                            Text("Photo: \(attribution) · iNaturalist")
                                .font(FieldType.caption)
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        )
                    }
                )
            }
        }
    }

    // MARK: - Hero Illustration

    @ViewBuilder
    private var expandableHero: some View {
        if illustrationAssetName != nil || photoURL != nil {
            Button(action: presentHero) {
                heroIllustration
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View \(catalogPlant.commonName) image full screen")
        } else {
            heroIllustration
        }
    }

    private var heroIllustration: some View {
        VStack(spacing: 0) {
            if hasIllustration {
                // Plate leads.
                BotanicalIllustrationView(
                    catalogPlant.commonName,
                    family: catalogPlant.family,
                    scientificName: catalogPlant.scientificName,
                    size: .hero, fill: true
                )
                .frame(height: 240)

                // Attribution — renders only for real, human-authored plates.
                IllustrationCreditLine(
                    plantName: catalogPlant.commonName,
                    family: catalogPlant.family,
                    scientificName: catalogPlant.scientificName
                )
                .padding(.top, FieldSpace.xs)
                .padding(.horizontal, FieldSpace.lg)
            } else if let url = photoURL {
                // No plate (typically a new regional taxon): the photo is the hero.
                photoHero(url)

                photoAttributionLine
            } else {
                // Neither plate nor photo: the illustration placeholder.
                BotanicalIllustrationView(
                    catalogPlant.commonName,
                    family: catalogPlant.family,
                    scientificName: catalogPlant.scientificName,
                    size: .hero, fill: true
                )
                .frame(height: 240)
            }
        }
    }

    // MARK: - Remote photos

    /// The remote photos the gallery should show. When the hero *is* the photo
    /// (no plate), the hero image is dropped from the gallery to avoid showing
    /// the same picture twice on one screen.
    private var galleryRemotePhotos: [RemoteGalleryPhoto] {
        guard !hasIllustration, let heroURL = photoURL else { return remotePhotos }
        return remotePhotos.filter { $0.url != heroURL }
    }

    private func loadRemotePhotos() async {
        // Seed instantly with the pack's licensed default photo, so the gallery
        // isn't empty while the taxon fetch is in flight (or offline).
        if remotePhotos.isEmpty, let url = photoURL {
            remotePhotos = [
                RemoteGalleryPhoto(
                    url: url,
                    fullURL: url,
                    attribution: catalogPlant.photoAttribution
                )
            ]
        }

        guard let taxonID = catalogPlant.inaturalistTaxonID else { return }
        guard let photos = try? await INaturalistService.shared.taxonPhotos(taxonID: taxonID),
              !photos.isEmpty else { return }

        remotePhotos = photos.map {
            RemoteGalleryPhoto(
                url: $0.mediumURL,
                fullURL: $0.largeURL ?? $0.mediumURL,
                attribution: $0.attribution
            )
        }
    }

    private func photoHero(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty:
                ProgressView().frame(maxWidth: .infinity, minHeight: 240)
            case .failure:
                Color.clear.frame(height: 0)
            @unknown default:
                Color.clear.frame(height: 0)
            }
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: FieldRadius.lg))
        .background(FieldColor.surface)
    }

    @ViewBuilder
    private var photoAttributionLine: some View {
        if let attribution = catalogPlant.photoAttribution, !attribution.isEmpty {
            Text("Photo: \(attribution) · iNaturalist")
                .font(FieldType.caption)
                .foregroundColor(FieldColor.fadedInk)
                .multilineTextAlignment(.center)
                .padding(.top, FieldSpace.xs)
                .padding(.horizontal, FieldSpace.lg)
        }
    }

    private var photoURL: URL? {
        guard let raw = catalogPlant.photoURL, !raw.isEmpty else { return nil }
        return URL(string: raw)
    }
}

#Preview("Plant detail · Illustration") {
    NavigationStack {
        CatalogPlantDetailView(catalogPlant: CatalogPlant.catalog.first!)
    }
}
