//
//  LocationMapView.swift
//  Fieldnote
//
//  Map tab — locations where plants were observed. Phase 2 polish: a real
//  detail sheet with presentation detents + glass background, a floating glass
//  recenter control, and modern (non-vintage) styling.
//

import SwiftUI
import MapKit

struct LocationMapView: View {
    @Environment(\.appStore) private var store

    @State private var selectedCluster: LocationCluster?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var clusters: [LocationCluster] {
        store?.locationsWithCoordinates ?? []
    }

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(clusters) { cluster in
                annotationForCluster(cluster)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls {
            // System map controls — Liquid Glass automatically on iOS 26.
            MapUserLocationButton()
            MapCompass()
        }
        .overlay(alignment: .bottomTrailing) {
            recenterButton
                .padding(.trailing, FieldSpace.md)
                .padding(.bottom, 96) // clear the floating tab bar
        }
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fitAllLocations() }
        .sheet(item: $selectedCluster) { cluster in
            LocationDetailSheet(cluster: cluster)
                .presentationDetents([.height(260), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.regularMaterial)
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Controls

    private var recenterButton: some View {
        Button {
            fitAllLocations()
        } label: {
            Image(systemName: "scope")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FieldColor.accentDeep)
                .frame(width: 46, height: 46)
        }
        .fieldGlass(in: Circle(), interactive: true)
        .accessibilityLabel("Show all locations")
    }

    // MARK: - Annotations

    private func annotationForCluster(_ cluster: LocationCluster) -> some MapContent {
        Annotation(cluster.name, coordinate: cluster.coordinate, anchor: .bottom) {
            PlantAnnotationView(
                count: cluster.plantCount,
                category: cluster.category,
                isSelected: selectedCluster?.id == cluster.id
            )
            .onTapGesture { selectedCluster = cluster }
        }
    }

    // MARK: - Camera

    private func fitAllLocations() {
        let clusters = self.clusters
        guard !clusters.isEmpty else { return }

        if clusters.count == 1 {
            cameraPosition = .region(MKCoordinateRegion(
                center: clusters[0].coordinate,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            ))
        } else {
            let coordinates = clusters.map { $0.coordinate }
            let minLat = coordinates.map { $0.latitude }.min() ?? 0
            let maxLat = coordinates.map { $0.latitude }.max() ?? 0
            let minLon = coordinates.map { $0.longitude }.min() ?? 0
            let maxLon = coordinates.map { $0.longitude }.max() ?? 0

            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            let latDelta = (maxLat - minLat) * 1.5 + 0.01
            let lonDelta = (maxLon - minLon) * 1.5 + 0.01

            cameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            ))
        }
    }
}

// MARK: - Plant Annotation View

struct PlantAnnotationView: View {
    let count: Int
    let category: LocationCategory
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: 44, height: 44)
                .offset(y: 2)
            Circle()
                .fill(isSelected ? category.color : category.color.opacity(0.9))
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(FieldColor.surface, lineWidth: 2))
            countOrIcon
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }

    @ViewBuilder
    private var countOrIcon: some View {
        if count > 1 {
            Text("\(count)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        } else {
            Image(systemName: "leaf.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Location Detail Sheet

struct LocationDetailSheet: View {
    let cluster: LocationCluster

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: FieldSpace.md) {
                HStack(spacing: FieldSpace.sm) {
                    LocationIcon(category: cluster.category, size: .medium)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cluster.name)
                            .font(FieldType.title3)
                            .foregroundStyle(FieldColor.ink)
                            .lineLimit(1)
                        Text("\(cluster.plantCount) plant\(cluster.plantCount == 1 ? "" : "s") observed here")
                            .font(FieldType.footnote)
                            .foregroundStyle(FieldColor.mutedInk)
                    }
                    Spacer()
                }
                .padding(.horizontal, FieldSpace.md)
                .padding(.top, FieldSpace.lg)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FieldSpace.md) {
                        ForEach(cluster.plants) { plant in
                            NavigationLink(value: plant) {
                                MapPlantCard(plant: plant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, FieldSpace.md)
                }

                Spacer(minLength: 0)
            }
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant)
            }
        }
    }
}

// MARK: - Map Plant Card

private struct MapPlantCard: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            PlantIllustrationView(plant: plant, size: .card)
                .frame(width: 120, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: FieldRadius.md, style: .continuous))

            Text(plant.commonName)
                .font(FieldType.footnote.weight(.medium))
                .foregroundStyle(FieldColor.ink)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)
        }
        .frame(width: 120)
    }
}
