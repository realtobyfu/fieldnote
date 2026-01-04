//
//  LocationMapView.swift
//  Fieldnote
//
//  Map view showing locations where plants were observed
//

import SwiftUI
import MapKit

struct LocationMapView: View {
    @Environment(\.appStore) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCluster: LocationCluster?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showDetailSheet = false

    private var clusters: [LocationCluster] {
        store?.locationsWithCoordinates ?? []
    }

    var body: some View {
        mainContent
            .animation(.easeInOut(duration: 0.25), value: showDetailSheet)
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onChange(of: selectedCluster) { _, newValue in
                if newValue != nil {
                    showDetailSheet = true
                }
            }
            .onAppear {
                fitAllLocations()
            }
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant)
            }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            mapView
            detailSheetOverlay
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $cameraPosition) {
            ForEach(clusters) { cluster in
                annotationForCluster(cluster)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    private func annotationForCluster(_ cluster: LocationCluster) -> some MapContent {
        Annotation(
            cluster.name,
            coordinate: cluster.coordinate,
            anchor: .bottom
        ) {
            PlantAnnotationView(
                count: cluster.plantCount,
                category: cluster.category,
                isSelected: selectedCluster?.id == cluster.id
            )
            .onTapGesture {
                selectedCluster = cluster
                showDetailSheet = true
            }
        }
    }

    // MARK: - Detail Sheet Overlay

    @ViewBuilder
    private var detailSheetOverlay: some View {
        if let cluster = selectedCluster, showDetailSheet {
            LocationDetailSheet(
                cluster: cluster,
                isPresented: $showDetailSheet
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    fitAllLocations()
                } label: {
                    Label("Show All", systemImage: "arrow.up.left.and.arrow.down.right")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Helper Methods

    private func fitAllLocations() {
        let clusters = self.clusters
        guard !clusters.isEmpty else { return }

        if clusters.count == 1 {
            let cluster = clusters[0]
            cameraPosition = .region(MKCoordinateRegion(
                center: cluster.coordinate,
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
            shadowCircle
            mainCircle
            countOrIcon
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }

    private var shadowCircle: some View {
        Circle()
            .fill(Color.black.opacity(0.15))
            .frame(width: 44, height: 44)
            .offset(y: 2)
    }

    private var mainCircle: some View {
        Circle()
            .fill(isSelected ? category.color : category.color.opacity(0.9))
            .frame(width: 40, height: 40)
            .overlay(
                Circle()
                    .stroke(FieldColor.surface, lineWidth: 2)
            )
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
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            handleBar
            headerSection
            divider
            plantCardsSection
        }
        .frame(maxWidth: .infinity)
        .background(sheetBackground)
        .padding(.horizontal, FieldSpace.sm)
        .padding(.bottom, FieldSpace.sm)
    }

    private var handleBar: some View {
        Capsule()
            .fill(FieldColor.separator)
            .frame(width: 36, height: 4)
            .padding(.top, FieldSpace.sm)
    }

    private var headerSection: some View {
        HStack(spacing: FieldSpace.sm) {
            LocationIcon(category: cluster.category, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(cluster.name)
                    .font(FieldType.bodyEmphasized)
                    .foregroundColor(FieldColor.vintageInk)
                    .lineLimit(1)

                Text("\(cluster.plantCount) plant\(cluster.plantCount == 1 ? "" : "s")")
                    .font(FieldType.caption)
                    .foregroundColor(FieldColor.fadedInk)
            }

            Spacer()

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(FieldColor.fadedInk)
            }
        }
        .padding(.horizontal, FieldSpace.md)
        .padding(.top, FieldSpace.sm)
    }

    private var divider: some View {
        RuledLine()
            .padding(.vertical, FieldSpace.sm)
    }

    private var plantCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FieldSpace.sm) {
                ForEach(cluster.plants) { plant in
                    NavigationLink(value: plant) {
                        MapPlantCard(plant: plant)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, FieldSpace.md)
        }
        .padding(.bottom, FieldSpace.md)
    }

    private var sheetBackground: some View {
        RoundedRectangle(cornerRadius: FieldRadius.lg)
            .fill(FieldColor.surface)
            .shadow(color: .black.opacity(0.1), radius: 10, y: -2)
    }
}

// MARK: - Map Plant Card

private struct MapPlantCard: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.xs) {
            PlantIllustrationView(plant: plant, size: .card)
                .frame(width: 120, height: 90)

            Text(plant.commonName)
                .font(FieldType.caption)
                .foregroundColor(FieldColor.vintageInk)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)
        }
        .frame(width: 120)
    }
}
