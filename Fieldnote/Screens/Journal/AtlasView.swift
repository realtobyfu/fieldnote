import SwiftUI

struct AtlasVolume: Hashable {
    let type: PlantType
    let number: Int
}

enum BookUtilityRoute: Hashable {
    case history, map, profile
}

struct AtlasView: View {
    @Environment(\.appStore) private var store

    var body: some View {
        ScrollView {
            if let store {
                VStack(alignment: .leading, spacing: 0) {
                    opening(store)
                    VStack(alignment: .leading, spacing: 28) {
                        contents(store)
                        recentDiscovery(store)
                    }
                    .padding(24)
                }
            }
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle("Atlas")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: AtlasVolume.self) { volume in
            AtlasVolumeView(volume: volume)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: BookUtilityRoute.profile) {
                    Label("Profile and settings", systemImage: "person.crop.circle")
                }
            }
        }
    }

    private func opening(_ store: AppStore) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FIELDNOTE / A PERSONAL HERBARIUM")
                .font(.caption2.weight(.medium)).tracking(1.6)
                .foregroundStyle(FieldColor.mutedInk)
            VStack(alignment: .leading, spacing: 6) {
                Text("Your herbarium.").font(FieldBook.title)
                Text("A book of things you’ve noticed.")
                    .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
            }
            Divider().overlay(FieldBook.cover.opacity(0.12))
            HStack {
                Text("\(store.plants.count) specimens")
                Spacer()
                Text("\(volumes(store).count) volumes")
            }
            .font(.caption)
            .foregroundStyle(FieldColor.mutedInk)
        }
        .foregroundStyle(FieldBook.cover)
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FieldBook.wash)
    }

    private func volumes(_ store: AppStore) -> [PlantType] {
        PlantType.allCases.filter { type in store.plants.contains { $0.plantType == type } }
    }

    @ViewBuilder private func contents(_ store: AppStore) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contents").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
            if store.plants.isEmpty {
                Text("Your first discovery opens the first volume.")
                    .font(.body).foregroundStyle(FieldColor.mutedInk)
                Button("Explore nearby plants") { store.selectedTab = .explore }
                    .font(.subheadline.weight(.medium)).frame(minHeight: 44)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(volumes(store).enumerated()), id: \.element) { index, type in
                        NavigationLink(value: AtlasVolume(type: type, number: index + 1)) {
                            HStack(spacing: 16) {
                                Text(roman(index + 1)).font(FieldBook.name)
                                    .foregroundStyle(FieldColor.botanicalBrown).frame(width: 28)
                                Text(type.label).font(FieldBook.name)
                                Spacer()
                                Text("\(store.plants.filter { $0.plantType == type }.count)")
                                    .font(.caption).foregroundStyle(FieldColor.mutedInk)
                                Image(systemName: "chevron.right").font(.caption2)
                            }
                            .foregroundStyle(FieldColor.ink)
                            .padding(.vertical, 11)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder private func recentDiscovery(_ store: AppStore) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BookSectionLabel(text: "Recent discovery")
            if let plant = store.plants.max(by: {
                ($0.lastSeenDate ?? $0.createdAt) < ($1.lastSeenDate ?? $1.createdAt)
            }) {
                NavigationLink(value: plant) {
                    HStack(spacing: 20) {
                        BookPlantImage(plant: plant)
                            .frame(width: 100, height: 134)
                            .specimenSource(plant.id)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(plant.commonName).font(FieldBook.heading)
                            Text(plant.scientificName).font(.subheadline).italic()
                                .foregroundStyle(FieldColor.mutedInk)
                            Text(FieldBook.encounterCount(plant.encounterCount))
                                .font(.caption).foregroundStyle(FieldBook.cover)
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(FieldColor.ink)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Label("Capture something that catches your eye.", systemImage: "camera")
                    .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
            }
        }
    }

    private func roman(_ number: Int) -> String {
        ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"][min(number - 1, 7)]
    }
}

struct AtlasVolumeView: View {
    let volume: AtlasVolume
    @Environment(\.appStore) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BookSectionLabel(text: "Volume \(volume.number)")
                Text(volume.type.label).font(FieldBook.title)
                Divider()
                if let store {
                    ForEach(store.plants.filter { $0.plantType == volume.type }.sorted { $0.commonName < $1.commonName }) { plant in
                        NavigationLink(value: plant) { BookSpecimenRow(plant: plant) }
                            .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
            .padding(24)
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle(volume.type.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BookSpecimenRow: View {
    let plant: Plant
    var body: some View {
        HStack(spacing: 18) {
            BookPlantImage(plant: plant).frame(width: 72, height: 88).specimenSource(plant.id)
            VStack(alignment: .leading, spacing: 5) {
                Text(plant.commonName).font(FieldBook.name)
                Text(plant.scientificName).font(.caption).italic().foregroundStyle(FieldColor.mutedInk)
                Text(FieldBook.encounterCount(plant.encounterCount)).font(.caption).foregroundStyle(FieldBook.cover)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(FieldColor.mutedInk)
        }
        .foregroundStyle(FieldColor.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
