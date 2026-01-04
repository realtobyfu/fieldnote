//
//  NearMeSection.swift
//  Fieldnote
//
//  GPS-based section showing plants commonly found nearby
//

import SwiftUI
import CoreLocation

struct NearMeSection: View {
    @Environment(\.appStore) private var store

    @State private var currentLocation: CLLocationCoordinate2D?
    @State private var nearbyPlaces: [SelectedLocation] = []
    @State private var habitatType: String?
    @State private var isLoading = false
    @State private var hasLoaded = false

    private var appStore: AppStore {
        guard let store = store else {
            fatalError("AppStore not found in environment")
        }
        return store
    }

    private var nearbyPlants: [CatalogPlant] {
        guard let habitat = habitatType else { return [] }
        return Array(appStore.undiscoveredPlantsNearby(habitatType: habitat).prefix(15))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            // Header
            HStack {
                SectionHeader(title: "Near Me")
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !nearbyPlants.isEmpty {
                    Text("\(nearbyPlants.count)")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }
            .padding(.horizontal, FieldSpace.md)

            // Habitat subtitle
            if let habitat = habitatType, !isLoading {
                Text("Plants common in \(habitat) areas")
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.fadedInk)
                    .padding(.horizontal, FieldSpace.md)
            }

            // Content
            if isLoading {
                loadingState
            } else if !hasLoaded {
                enableLocationState
            } else if nearbyPlants.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.sm) {
                        ForEach(nearbyPlants) { catalogPlant in
                            NavigationLink(value: catalogPlant) {
                                UndiscoveredPlantCard(catalogPlant: catalogPlant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, FieldSpace.md)
                }
            }
        }
        .task {
            await loadNearbyLocation()
        }
    }

    // MARK: - States

    private var loadingState: some View {
        HStack {
            Spacer()
            VStack(spacing: FieldSpace.sm) {
                ProgressView()
                Text("Finding nearby plants...")
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.fadedInk)
            }
            Spacer()
        }
        .padding(.vertical, FieldSpace.lg)
    }

    private var enableLocationState: some View {
        HStack {
            Spacer()
            VStack(spacing: FieldSpace.sm) {
                Image(systemName: "location.slash")
                    .font(.title2)
                    .foregroundColor(FieldColor.fadedInk)
                Text("Enable location to see nearby plants")
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.fadedInk)
            }
            Spacer()
        }
        .padding(.vertical, FieldSpace.lg)
    }

    private var emptyState: some View {
        Text("No undiscovered plants in this area")
            .font(FieldType.callout)
            .foregroundColor(FieldColor.fadedInk)
            .italic()
            .frame(maxWidth: .infinity)
            .padding(.vertical, FieldSpace.lg)
            .padding(.horizontal, FieldSpace.md)
    }

    // MARK: - Location Loading

    private func loadNearbyLocation() async {
        guard !hasLoaded else { return }

        isLoading = true

        if let coordinate = await LocationService.shared.requestCurrentLocation() {
            currentLocation = coordinate
            nearbyPlaces = await NearbyPlacesService.shared.fetchNearbyPlaces(coordinate: coordinate)
            habitatType = appStore.inferHabitatType(from: nearbyPlaces)
        }

        isLoading = false
        hasLoaded = true
    }
}
