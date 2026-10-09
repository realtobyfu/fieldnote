import SwiftUI
import SwiftData

/// The personal endpaper of the book: a record of the observer's practice.
struct ProfileView: View {
    @Environment(\.appStore) private var store
    @Environment(\.gamificationService) private var gamification
    @Environment(\.subscriptionStore) private var subscriptionStore
    @Environment(\.syncStore) private var syncStore
    @Environment(\.capturePlant) private var capturePlant
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            if let store {
                VStack(alignment: .leading, spacing: 0) {
                    opening(store)
                    VStack(alignment: .leading, spacing: 28) {
                        monthlyNotes(store)
                        journalIndex(store)
                        if let gamification { milestones(gamification) }
                        essentials
                    }
                    .padding(24)
                }
            }
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ProfileSettingsSection()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .accessibilityIdentifier("profile.settings")
            }
        }
    }

    private func opening(_ store: AppStore) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    BookSectionLabel(text: "A life of noticing")
                    Text("Your field journal.")
                        .font(FieldBook.title)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let firstDate = store.allEncounters.last?.date {
                        Text("First entry \(firstDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    } else {
                        Text("Every discovery starts with a closer look.")
                            .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    }
                }
                Spacer(minLength: 8)
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 29, weight: .light))
                        .foregroundStyle(FieldBook.cover)
                        .frame(width: 54, height: 68)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(FieldBook.cover.opacity(0.25), lineWidth: 1)
                        }
                        .rotationEffect(.degrees(-5))
                        .accessibilityHidden(true)
                }
            }
            Divider().overlay(FieldBook.cover.opacity(0.12))
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 14) { journalCounts(store) }
            } else {
                HStack(alignment: .top, spacing: 12) { journalCounts(store) }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FieldBook.wash)
    }

    @ViewBuilder private func journalCounts(_ store: AppStore) -> some View {
        count(store.plants.count, label: "Specimens")
        count(store.allEncounters.count, label: "Encounters")
        count(store.uniqueLocations.count, label: "Places")
    }

    private func count(_ value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value, format: .number).font(FieldBook.heading).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(FieldColor.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label.lowercased())")
    }

    private func monthlyNotes(_ store: AppStore) -> some View {
        let calendar = Calendar.current
        let entries = store.allEncounters.filter {
            calendar.isDate($0.date, equalTo: .now, toGranularity: .month)
        }
        let days = Set(entries.map { calendar.startOfDay(for: $0.date) }).count
        return VStack(alignment: .leading, spacing: 10) {
            BookSectionLabel(text: Date.now.formatted(.dateTime.month(.wide).year()))
            Text(entries.isEmpty ? "A new page awaits." : "\(days) \(days == 1 ? "day" : "days") of noticing.")
                .font(FieldBook.heading)
                .accessibilityIdentifier("profile.monthSummary")
            Text(entries.isEmpty
                 ? "Return whenever something catches your eye. Your journal grows at your pace."
                 : "\(FieldBook.encounterCount(entries.count)) recorded this month. Every return adds something to your book.")
                .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
            if store.allEncounters.isEmpty, let capturePlant {
                Button(action: capturePlant) {
                    Label("Capture a discovery", systemImage: "camera")
                        .font(.subheadline.weight(.medium))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(FieldBook.cover)
                .accessibilityIdentifier("profile.firstCapture")
            }
        }
    }

    private func journalIndex(_ store: AppStore) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inside your journal").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                NavigationLink {
                    AllEncountersView()
                } label: {
                    BookNavigationRow(symbol: "clock", title: "Encounter history", subtitle: "Revisit the things you've noticed", detail: "\(store.allEncounters.count)")
                }
                .accessibilityIdentifier("profile.history")
                Divider()
                NavigationLink {
                    LocationMapView()
                } label: {
                    BookNavigationRow(symbol: "map", title: "Your places", subtitle: "See encounters with saved coordinates")
                }
                .accessibilityIdentifier("profile.map")
                Divider()
                NavigationLink {
                    PlantManagementView()
                } label: {
                    BookNavigationRow(symbol: "square.grid.2x2", title: "Manage specimens", subtitle: "Names, illustrations, and entries")
                }
                .accessibilityIdentifier("profile.specimens")
                Divider()
            }
            .buttonStyle(.plain)
        }
    }

    private func milestones(_ gamification: GamificationService) -> some View {
        let supported = Set(BadgeCatalog.all.map(\.id))
        let earned = Set(gamification.achievements().filter { $0.unlockedAt != nil }.map(\.identifier)).intersection(supported)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Along the way").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
            NavigationLink {
                ProfileMilestonesView()
            } label: {
                BookNavigationRow(symbol: "rosette", title: "Milestones", subtitle: "Small markers of a growing practice", detail: "\(earned.count) earned")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.milestones")
            Divider()
        }
    }

    private var essentials: some View {
        VStack(alignment: .leading, spacing: 8) {
            BookSectionLabel(text: "Journal essentials")
            NavigationLink {
                SubscriptionStatusView()
            } label: {
                BookNavigationRow(symbol: "sparkles", title: "Membership", subtitle: membershipSubtitle,
                                  detail: subscriptionStore.isPremium ? "Premium" : "Free")
            }
            .accessibilityIdentifier("profile.membership")
            Divider()
            NavigationLink {
                ProfileStorageView()
            } label: {
                BookNavigationRow(symbol: "externaldrive", title: "Storage & iCloud",
                                  subtitle: "Journal saved on this device",
                                  detail: syncStore.journalUsesCloudStorage ? "iCloud" : "Local")
            }
            .accessibilityIdentifier("profile.storage")
            Divider()
            NavigationLink {
                ProfileSettingsSection()
            } label: {
                BookNavigationRow(symbol: "gearshape", title: "Settings", subtitle: "Permissions, sources, and help")
            }
            .accessibilityIdentifier("profile.settingsRow")
            Divider()
            Text("FIELDNOTE · A PERSONAL HERBARIUM")
                .font(.caption2).tracking(1.2).foregroundStyle(FieldColor.tertiaryInk)
                .padding(.top, 12)
        }
        .buttonStyle(.plain)
    }

    private var membershipSubtitle: String {
        if subscriptionStore.isPremium {
            return subscriptionStore.subscriptionType == .lifetime ? "Lifetime identification access" : "Unlimited photo identification"
        }
        let remaining = subscriptionStore.remainingFreeIdentifications
        return "\(remaining) photo \(remaining == 1 ? "identification" : "identifications") remaining · manual entries are unlimited"
    }
}

// MARK: - Preview

#if DEBUG
@MainActor
private struct ProfilePreviewHost: View {
    @State private var appStore: AppStore
    @State private var gamification: GamificationService

    private let container: ModelContainer

    init() {
        let schema = Schema([Plant.self, Encounter.self, FieldProfile.self, Achievement.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        for plant in Self.samplePlants() {
            context.insert(plant)
        }

        let earnedBadges: [(id: String, daysAgo: Int)] = [
            ("locations_3", 2),
            ("families_5", 5),
            ("species_5", 8),
            ("ten_finds", 12),
            ("first_find", 20),
            ("streak_7", 30)
        ]
        for earnedBadge in earnedBadges {
            context.insert(
                Achievement(
                    identifier: earnedBadge.id,
                    unlockedAt: Date.now.addingTimeInterval(-Double(earnedBadge.daysAgo) * 86_400)
                )
            )
        }
        try! context.save()

        let appStore = AppStore(modelContext: context)
        let gamification = GamificationService(modelContext: context, appStore: appStore)

        self.container = container
        _appStore = State(initialValue: appStore)
        _gamification = State(initialValue: gamification)
    }

    var body: some View {
        NavigationStack {
            ProfileView()
        }
        .environment(\.appStore, appStore)
        .environment(\.gamificationService, gamification)
        .modelContainer(container)
        .preferredColorScheme(.light)
    }

    private static func samplePlants() -> [Plant] {
        func encounter(daysAgo: Int, location: String, symbol: String) -> Encounter {
            Encounter(
                date: Date.now.addingTimeInterval(-Double(daysAgo) * 86_400),
                locationLabel: location,
                photoPlaceholder: symbol,
                confidence: 0.9
            )
        }

        return [
            Plant(
                commonName: "Red Maple",
                scientificName: "Acer rubrum",
                family: "Sapindaceae",
                encounters: [
                    encounter(daysAgo: 20, location: "Riverside Park", symbol: "leaf.fill"),
                    encounter(daysAgo: 28, location: "Botanical Garden", symbol: "leaf.fill")
                ]
            ),
            Plant(
                commonName: "Black-eyed Susan",
                scientificName: "Rudbeckia hirta",
                family: "Asteraceae",
                encounters: [
                    encounter(daysAgo: 21, location: "Meadow Loop", symbol: "sun.max.fill"),
                    encounter(daysAgo: 32, location: "Riverside Park", symbol: "sun.max.fill")
                ]
            ),
            Plant(
                commonName: "Common Milkweed",
                scientificName: "Asclepias syriaca",
                family: "Apocynaceae",
                encounters: [
                    encounter(daysAgo: 23, location: "Meadow Loop", symbol: "allergens.fill"),
                    encounter(daysAgo: 35, location: "Lakeside Trail", symbol: "allergens.fill")
                ]
            ),
            Plant(
                commonName: "Queen Anne's Lace",
                scientificName: "Daucus carota",
                family: "Apiaceae",
                encounters: [
                    encounter(daysAgo: 24, location: "Lakeside Trail", symbol: "camera.macro")
                ]
            ),
            Plant(
                commonName: "New England Aster",
                scientificName: "Symphyotrichum novae-angliae",
                family: "Asteraceae",
                encounters: [
                    encounter(daysAgo: 26, location: "Botanical Garden", symbol: "sparkles")
                ]
            ),
            Plant(
                commonName: "Garden Sage",
                scientificName: "Salvia officinalis",
                family: "Lamiaceae",
                encounters: [
                    encounter(daysAgo: 29, location: "Botanical Garden", symbol: "leaf.circle.fill")
                ]
            ),
            Plant(
                commonName: "Calendula",
                scientificName: "Calendula officinalis",
                family: "Asteraceae",
                encounters: [
                    encounter(daysAgo: 31, location: "Riverside Park", symbol: "sun.max.circle.fill")
                ]
            )
        ]
    }
}

#Preview("Profile — Mock Data") {
    ProfilePreviewHost()
}
#endif
