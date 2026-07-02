//
//  JournalView.swift
//  Fieldnote
//
//  The Journal home (Blend redesign): a pinned glass status header over an
//  editorial recent-finds feed with inline collection progress. Replaces the old
//  Library grid as the home; the grid lives on as the pushed "Collection" screen.
//
//  Streak + seasonal challenge are derived live from encounter history for now;
//  Wave 2 (gamification) replaces the provisional target with real SeasonalChallenge.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.appStore) private var store
    @State private var headerHeight: CGFloat = 120

    private let seasonalTarget = 10
    private let feedLimit = 12

    var body: some View {
        Group {
            if let store {
                content(store)
            } else {
                ContentUnavailableView("Unable to Load", systemImage: "exclamationmark.triangle")
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Plant.self) { plant in
            PlantDetailView(plant: plant)
        }
    }

    @ViewBuilder
    private func content(_ store: AppStore) -> some View {
        let finds = recentFinds(store)

        ZStack(alignment: .top) {
            LinearGradient(
                colors: [FieldColor.canvasTop, FieldColor.canvasBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if store.plants.isEmpty {
                EmptyStateView(
                    icon: "leaf",
                    title: "Your journal awaits",
                    message: "Capture your first plant to begin your field journal.",
                    actionLabel: "Capture a Plant",
                    action: { store.selectedTab = .capture }
                )
            } else {
                ScrollView {
                    VStack(spacing: FieldSpace.md) {
                        Color.clear.frame(height: headerHeight + FieldSpace.sm)

                        JournalStatsStrip(
                            species: store.plants.count,
                            sightings: store.allEncounters.count,
                            places: store.uniqueLocations.count
                        )

                        sectionLabel

                        ForEach(Array(finds.enumerated()), id: \.element.encounter.id) { index, find in
                            NavigationLink(value: find.plant) {
                                JournalFindCard(
                                    encounter: find.encounter,
                                    plant: find.plant,
                                    isNewSpecies: isDiscovery(find.encounter),
                                    height: index == 0 ? 330 : 240,
                                    palette: palette(for: index)
                                )
                            }
                            .buttonStyle(.plain)

                            if index == 0 {
                                NavigationLink {
                                    LibraryView()
                                } label: {
                                    CollectionProgressRow(
                                        discovered: store.discoveredCatalogPlants.count,
                                        total: store.catalogPlants.count
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, FieldSpace.md)
                    .padding(.bottom, FieldSpace.md)
                }
                .refreshable { await store.refresh() }
                .collapsesTabBarOnScroll()
            }

            header(store)
                .padding(.horizontal, 14)
                .padding(.top, FieldSpace.sm)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { headerHeight = $0 }
        }
    }

    // MARK: - Header

    private func header(_ store: AppStore) -> some View {
        JournalStatusHeader(
            greeting: greeting,
            dateLine: dateLine,
            streak: currentStreak(store),
            challengeName: "\(seasonName(Date.now)) Challenge",
            challengeProgress: min(seasonalFinds(store), seasonalTarget),
            challengeTarget: seasonalTarget
        )
    }

    private var sectionLabel: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Recent finds")
                .font(FieldType.title3)
                .foregroundStyle(FieldColor.ink)
            Spacer()
            NavigationLink {
                LibraryView()
            } label: {
                Text("All collection ›")
                    .font(FieldType.footnote.weight(.semibold))
                    .foregroundStyle(FieldColor.accentDeep)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Feed data

    private func recentFinds(_ store: AppStore) -> [(encounter: Encounter, plant: Plant)] {
        store.allEncounters.prefix(feedLimit).compactMap { encounter in
            encounter.plant.map { (encounter: encounter, plant: $0) }
        }
    }

    /// A find is a "discovery" when it's the earliest encounter for its plant.
    private func isDiscovery(_ encounter: Encounter) -> Bool {
        guard let plant = encounter.plant,
              let earliest = (plant.encounters ?? []).min(by: { $0.date < $1.date })
        else { return false }
        return earliest.id == encounter.id
    }

    private func palette(for index: Int) -> FindPalette {
        let all: [FindPalette] = [.forest, .autumn, .golden, .aster]
        return all[index % all.count]
    }

    // MARK: - Derived status

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date.now) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good evening"
        }
    }

    private var dateLine: String {
        let weekday = Date.now.formatted(.dateTime.weekday(.wide))
        let monthDay = Date.now.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday) · \(monthDay)"
    }

    private func seasonName(_ date: Date) -> String {
        switch Calendar.current.component(.month, from: date) {
        case 12, 1, 2: return "Winter"
        case 3, 4, 5: return "Spring"
        case 6, 7, 8: return "Summer"
        default: return "Autumn"
        }
    }

    private func seasonalFinds(_ store: AppStore) -> Int {
        let now = Date.now
        let season = seasonName(now)
        let year = Calendar.current.component(.year, from: now)
        return store.allEncounters.filter {
            seasonName($0.date) == season &&
            Calendar.current.component(.year, from: $0.date) == year
        }.count
    }

    /// Consecutive-day streak of logging, ending today or yesterday.
    private func currentStreak(_ store: AppStore) -> Int {
        let cal = Calendar.current
        let days = Set(store.allEncounters.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var day = cal.startOfDay(for: Date.now)
        if !days.contains(day) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day),
                  days.contains(yesterday) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
}

// MARK: - Find card with async photo

/// A recent-find card that loads the encounter's real photo (thumbnail) async,
/// falling back to a themed gradient when there's no photo.
private struct JournalFindCard: View {
    let encounter: Encounter
    let plant: Plant
    let isNewSpecies: Bool
    var height: CGFloat = 280
    var palette: FindPalette = .forest

    @State private var image: UIImage?

    var body: some View {
        RecentFindCard(
            commonName: plant.commonName,
            scientificName: plant.scientificName,
            locationName: encounter.displayLocationName ?? "Location unknown",
            relativeDate: encounter.date.formatted(.relative(presentation: .named)),
            isNewSpecies: isNewSpecies,
            height: height,
            image: image.map { Image(uiImage: $0) },
            palette: palette
        )
        .task(id: encounter.id) {
            guard let filename = encounter.allPhotoFileNames.first else { return }
            image = await PhotoStorageService.shared.loadThumbnail(filename: filename, maxSize: 800)
        }
    }
}

// MARK: - Preview

#if DEBUG
/// Populated Journal home preview. Builds an in-memory SwiftData store seeded with
/// recent sample finds so the feed, stats strip, streak, and seasonal challenge all
/// render live (photo-less cards fall back to themed gradients).
private struct JournalPreviewHost: View {
    @State private var store: AppStore
    private let container: ModelContainer

    init() {
        let schema = Schema([Plant.self, Encounter.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: schema, configurations: [config])
        self.container = container
        let context = container.mainContext
        for plant in Self.samplePlants() {
            context.insert(plant)
        }
        _store = State(initialValue: AppStore(modelContext: context))
    }

    var body: some View {
        NavigationStack {
            JournalView()
        }
        .environment(\.appStore, store)
        .modelContainer(container)
    }

    private static func samplePlants() -> [Plant] {
        func enc(_ daysAgo: Int, _ loc: String, _ confidence: Double, _ symbol: String) -> Encounter {
            Encounter(
                date: Date().addingTimeInterval(-Double(daysAgo) * 86_400),
                locationLabel: loc,
                photoPlaceholder: symbol,
                confidence: confidence
            )
        }
        return [
            Plant(commonName: "Red Maple", scientificName: "Acer rubrum", family: "Sapindaceae",
                  summary: "Common tree with red twigs and fall color.",
                  encounters: [enc(0, "Riverside Park", 0.94, "leaf.fill"),
                               enc(8, "City Park", 0.90, "leaf.fill")]),
            Plant(commonName: "Goldenrod", scientificName: "Solidago canadensis", family: "Asteraceae",
                  summary: "Tall plumes of golden late-summer flowers.",
                  encounters: [enc(1, "Lakeside Trail", 0.88, "sun.max.fill")]),
            Plant(commonName: "New England Aster", scientificName: "Symphyotrichum novae-angliae", family: "Asteraceae",
                  summary: "Purple daisy-like blooms with a golden center.",
                  encounters: [enc(2, "Meadow Loop", 0.91, "sparkles")]),
            Plant(commonName: "Eastern White Pine", scientificName: "Pinus strobus", family: "Pinaceae",
                  summary: "Soft needles in bundles of five.",
                  encounters: [enc(3, "Pine Ridge", 0.82, "tree.fill")]),
            Plant(commonName: "Common Milkweed", scientificName: "Asclepias syriaca", family: "Apocynaceae",
                  summary: "Monarch host plant with pink flower clusters.",
                  encounters: [enc(4, "Meadow Loop", 0.79, "allergens.fill")]),
            Plant(commonName: "Black-eyed Susan", scientificName: "Rudbeckia hirta", family: "Asteraceae",
                  summary: "Golden petals around a dark central cone.",
                  encounters: [enc(5, "Riverside Park", 0.86, "sun.max.fill")])
        ]
    }
}

#Preview("Populated") {
    JournalPreviewHost()
}
#endif
