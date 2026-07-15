//
//  LocationMapView.swift
//  Fieldnote
//
//  Map tab — locations where plants were observed, with a themed location
//  summary and an automatically expanding plant-detail sheet.
//

import SwiftUI
import MapKit

struct LocationMapView: View {
    @Environment(\.appStore) private var store
    @Environment(TabBarVisibility.self) private var tabBar: TabBarVisibility?

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
        .safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 0) {
            recenterButton
                .padding(.trailing, FieldSpace.md)
        }
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fitAllLocations() }
        .onChange(of: selectedCluster) { _, cluster in
            tabBar?.suppressed = cluster != nil
        }
        .onDisappear {
            tabBar?.suppressed = false
        }
        .sheet(item: $selectedCluster) { cluster in
            LocationDetailSheet(cluster: cluster)
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
            Button {
                selectedCluster = cluster
            } label: {
                PlantAnnotationView(
                    count: cluster.plantCount,
                    category: cluster.category,
                    isSelected: selectedCluster?.id == cluster.id
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(cluster.name)
            .accessibilityValue("\(cluster.plantCount) plant\(cluster.plantCount == 1 ? "" : "s") observed")
            .accessibilityHint("Shows plants observed at this location")
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
                .foregroundStyle(.white)
        } else {
            Image(systemName: "leaf.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Location Detail Sheet

struct LocationDetailSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let cluster: LocationCluster

    @State private var path: [Plant] = []
    @State private var selectedDetent: PresentationDetent = .height(420)

    var body: some View {
        NavigationStack(path: $path) {
            LocationSummaryView(cluster: cluster)
                .navigationDestination(for: Plant.self) { plant in
                    PlantDetailView(plant: plant)
                }
        }
        .onChange(of: path.count) { _, depth in
            let detent: PresentationDetent = depth == 0 ? .height(420) : .large
            if reduceMotion {
                selectedDetent = detent
            } else {
                withAnimation(.snappy) {
                    selectedDetent = detent
                }
            }
        }
        .presentationDetents([.height(420), .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .presentationBackground(FieldColor.paper)
        .presentationCornerRadius(30)
    }
}

// MARK: - Location Summary

private struct LocationSummaryView: View {
    let cluster: LocationCluster

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.lg) {
            locationHeader

            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                Text("Plants found here")
                    .font(FieldType.sectionHeader)
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(FieldColor.mutedInk)
                    .accessibilityAddTraits(.isHeader)

                ScrollView(.horizontal) {
                    LazyHStack(spacing: FieldSpace.md) {
                        ForEach(cluster.plants) { plant in
                            NavigationLink(value: plant) {
                                MapPlantCard(plant: plant)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(plant.commonName)
                            .accessibilityValue(plant.scientificName)
                            .accessibilityHint("Opens plant details")
                        }
                    }
                    .padding(.vertical, FieldSpace.xs)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, FieldSpace.lg)
        .padding(.top, FieldSpace.lg)
        .padding(.bottom, FieldSpace.md)
        .background(
            LinearGradient(
                colors: [FieldColor.paper, FieldColor.canvasBottom.opacity(0.62)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var locationHeader: some View {
        HStack(alignment: .top, spacing: FieldSpace.md) {
            ZStack {
                RoundedRectangle(cornerRadius: FieldRadius.lg, style: .continuous)
                    .fill(cluster.category.color.opacity(0.14))

                Image(systemName: cluster.category.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(cluster.category.color)
            }
            .frame(width: 58, height: 58)
            .overlay {
                RoundedRectangle(cornerRadius: FieldRadius.lg, style: .continuous)
                    .stroke(cluster.category.color.opacity(0.18), lineWidth: 1)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                Text(cluster.category.label)
                    .font(FieldType.chapterLabel)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(cluster.category.color)

                Text(cluster.name)
                    .font(FieldType.title2)
                    .foregroundStyle(FieldColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Label(
                    "\(cluster.plantCount) plant\(cluster.plantCount == 1 ? "" : "s") observed",
                    systemImage: "leaf.fill"
                )
                .font(FieldType.footnote)
                .foregroundStyle(FieldColor.mutedInk)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Map Plant Card

private struct MapPlantCard: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlantIllustrationView(plant: plant, size: .card)
                .frame(width: 156, height: 108)
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.commonName)
                    .font(FieldType.callout.weight(.semibold))
                    .foregroundStyle(FieldColor.ink)
                    .lineLimit(2)

                if !plant.scientificName.isEmpty {
                    Text(plant.scientificName)
                        .font(FieldType.scientificFootnote)
                        .italic()
                        .foregroundStyle(FieldColor.mutedInk)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FieldSpace.sm)
        }
        .frame(width: 156, height: 174, alignment: .top)
        .background(FieldColor.surface, in: RoundedRectangle(cornerRadius: FieldRadius.lg, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: FieldRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: FieldRadius.lg, style: .continuous)
                .stroke(FieldColor.bookBorder.opacity(0.32), lineWidth: 0.75)
        }
        .fieldShadow(FieldShadow.card)
    }
}

#Preview("Map location sheet · Summary") {
    LocationSummaryView(
        cluster: LocationCluster(
            name: "Target",
            coordinate: CLLocationCoordinate2D(latitude: 19.65, longitude: -155.99),
            category: .urban,
            plants: Array(Plant.mockPlants.prefix(3)),
            plantIds: Set(Plant.mockPlants.prefix(3).map(\.id))
        )
    )
    .frame(height: 420, alignment: .top)
}
