//
//  LocationPickerSheet.swift
//  Fieldnote
//
//  X/Instagram-style location picker with search, recents, and nearby places
//

import SwiftUI
import CoreLocation

struct LocationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appStore) private var store

    @Binding var selectedLocation: SelectedLocation?
    @Binding var customLabel: String

    @State private var searchText = ""
    @State private var searchResults: [SelectedLocation] = []
    @State private var nearbyPlaces: [SelectedLocation] = []
    @State private var currentLocation: CLLocationCoordinate2D?
    @State private var currentLocationPlace: SelectedLocation?
    @State private var isLoadingCurrent = false
    @State private var isLoadingNearby = false
    @State private var isSearching = false

    private var appStore: AppStore {
        guard let store = store else {
            fatalError("AppStore not found in environment")
        }
        return store
    }

    var body: some View {
        NavigationStack {
            List {
                // Search bar
                Section {
                    TextField("Search places...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                }

                // Current location button
                Section {
                    currentLocationButton
                }

                // Search results (when searching)
                if !searchText.isEmpty {
                    searchResultsSection
                } else {
                    // Recent locations
                    if !appStore.recentLocations.isEmpty {
                        recentLocationsSection
                    }

                    // Nearby places
                    nearbySection
                }

                // Custom label
                Section {
                    TextField("Custom label (optional)", text: $customLabel)
                        .textFieldStyle(.plain)
                } header: {
                    Text("Custom Label")
                } footer: {
                    Text("Add your own name for this location")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadCurrentLocation()
        }
        .onChange(of: searchText) { _, newValue in
            Task {
                await performSearch(query: newValue)
            }
        }
    }

    // MARK: - Current Location Button

    private var currentLocationButton: some View {
        Button {
            Task {
                await selectCurrentLocation()
            }
        } label: {
            HStack(spacing: FieldSpace.sm) {
                ZStack {
                    Circle()
                        .fill(FieldColor.accent)
                        .frame(width: 32, height: 32)

                    if isLoadingCurrent {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Use Current Location")
                        .font(FieldType.bodyEmphasized)
                        .foregroundColor(FieldColor.ink)

                    if let place = currentLocationPlace {
                        Text(place.name)
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.fadedInk)
                            .lineLimit(1)
                    } else if isLoadingCurrent {
                        Text("Fetching...")
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.fadedInk)
                    }
                }

                Spacer()
            }
        }
        .disabled(isLoadingCurrent)
    }

    // MARK: - Search Results Section

    @ViewBuilder
    private var searchResultsSection: some View {
        Section("Search Results") {
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if searchResults.isEmpty {
                Text("No results found")
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
            } else {
                ForEach(searchResults) { location in
                    LocationRow(
                        location: location,
                        userLocation: currentLocation,
                        isSelected: selectedLocation?.id == location.id
                    ) {
                        selectedLocation = location
                    }
                }
            }
        }
    }

    // MARK: - Recent Locations Section

    private var recentLocationsSection: some View {
        Section("Recent Locations") {
            ForEach(appStore.recentLocations) { location in
                LocationRow(
                    location: location,
                    userLocation: currentLocation,
                    isSelected: selectedLocation?.id == location.id
                ) {
                    selectedLocation = location
                }
            }
        }
    }

    // MARK: - Nearby Section

    @ViewBuilder
    private var nearbySection: some View {
        Section("Nearby") {
            if isLoadingNearby {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if nearbyPlaces.isEmpty {
                Text("No nearby places found")
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
            } else {
                ForEach(nearbyPlaces) { location in
                    LocationRow(
                        location: location,
                        userLocation: currentLocation,
                        isSelected: selectedLocation?.id == location.id
                    ) {
                        selectedLocation = location
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func loadCurrentLocation() async {
        isLoadingCurrent = true
        isLoadingNearby = true

        if let coordinate = await LocationService.shared.requestCurrentLocation() {
            currentLocation = coordinate

            // Get current location place name
            currentLocationPlace = await NearbyPlacesService.shared.currentLocationPlace(coordinate: coordinate)
            isLoadingCurrent = false

            // Load nearby places
            nearbyPlaces = await NearbyPlacesService.shared.fetchNearbyPlaces(coordinate: coordinate)
            isLoadingNearby = false
        } else {
            isLoadingCurrent = false
            isLoadingNearby = false
        }
    }

    private func selectCurrentLocation() async {
        isLoadingCurrent = true

        if let coordinate = await LocationService.shared.requestCurrentLocation() {
            currentLocation = coordinate
            let place = await NearbyPlacesService.shared.currentLocationPlace(coordinate: coordinate)
            currentLocationPlace = place
            selectedLocation = place
        }

        isLoadingCurrent = false
    }

    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        // Debounce
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        guard !Task.isCancelled else { return }

        isSearching = true
        searchResults = await NearbyPlacesService.shared.search(query: query, near: currentLocation)
        isSearching = false
    }
}

// MARK: - Location Row

struct LocationRow: View {
    let location: SelectedLocation
    let userLocation: CLLocationCoordinate2D?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: FieldSpace.sm) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? FieldColor.accent : FieldColor.fadedInk)

                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(FieldType.body)
                        .foregroundColor(FieldColor.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let subtitle = location.subtitle {
                        Text(subtitle)
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.fadedInk)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let distance = location.distanceString(from: userLocation) {
                    Text(distance)
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                }

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body)
                        .foregroundColor(FieldColor.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
