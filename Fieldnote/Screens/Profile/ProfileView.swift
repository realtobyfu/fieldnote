import SwiftUI
import SwiftData

/// The person behind the journal: how long they have been observing, how far
/// they have come, and the account. The journal itself lives on the Journal tab.
struct ProfileView: View {
    @Environment(\.appStore) private var store
    @Environment(\.gamificationService) private var gamification
    @Environment(\.subscriptionStore) private var subscriptionStore
    @Environment(\.syncStore) private var syncStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            if let store {
                VStack(alignment: .leading, spacing: 28) {
                    identity(store)
                    Divider()
                    if let gamification { milestones(gamification) }
                    account
                }
                .padding(24)
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

    // MARK: - Identity

    private func identity(_ store: AppStore) -> some View {
        let first = store.allEncounters.map(\.date).min()
        return HStack(alignment: .center, spacing: 16) {
            if !dynamicTypeSize.isAccessibilitySize {
                ZStack {
                    Circle().fill(FieldBook.wash)
                    Image(systemName: "leaf")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(FieldBook.cover)
                }
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(first.map { "Observing since \($0.formatted(.dateTime.month(.wide).year()))" } ?? "Nothing recorded yet.")
                    .font(FieldBook.heading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(first == nil ? "Your first entry starts the journal." : counts(store))
                    .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func counts(_ store: AppStore) -> String {
        let places = store.uniqueLocations.count
        return [
            "\(store.plants.count) species",
            FieldBook.encounterCount(store.allEncounters.count),
            "\(places) \(places == 1 ? "place" : "places")"
        ].joined(separator: " · ")
    }

    // MARK: - Milestones

    private func milestones(_ gamification: GamificationService) -> some View {
        let seals = MilestoneItem.all(from: gamification)
        let earned = seals.filter(\.isEarned).count
        let columns = Array(
            repeating: GridItem(.flexible(), alignment: .top),
            count: dynamicTypeSize.isAccessibilitySize ? 2 : 4
        )
        // The whole section opens the full list, so the header carries the disclosure mark.
        return NavigationLink {
            ProfileMilestonesView()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Milestones").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("\(earned) of \(seals.count)")
                        .font(.caption).foregroundStyle(FieldColor.mutedInk).monospacedDigit()
                    BookChevron()
                }
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(seals.prefix(4)) { item in
                        MilestoneSealTile(item: item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.milestones")
    }

    // MARK: - Account

    private var account: some View {
        VStack(alignment: .leading, spacing: 8) {
            BookSectionLabel(text: "Account")
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
                                  subtitle: syncStore.journalUsesCloudStorage ? "Synced with iCloud" : "Journal saved on this device",
                                  detail: syncStore.journalUsesCloudStorage ? "iCloud" : "Local")
            }
            .accessibilityIdentifier("profile.storage")
            Divider()
            NavigationLink {
                PlantManagementView()
            } label: {
                BookNavigationRow(symbol: "square.grid.2x2", title: "Manage specimens",
                                  subtitle: "Names, illustrations, and entries")
            }
            .accessibilityIdentifier("profile.specimens")
            Divider()
            NavigationLink {
                ProfileSettingsSection()
            } label: {
                BookNavigationRow(symbol: "gearshape", title: "Settings", subtitle: "Permissions, sources, and help")
            }
            .accessibilityIdentifier("profile.settingsRow")
            Divider()
            Text("Fieldnote · \(ProfileAppInfo.version)")
                .font(.caption2).foregroundStyle(FieldColor.mutedInk)
                .frame(maxWidth: .infinity)
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

// MARK: - Milestone seals

/// A seal with its name and standing, sized for the four-across profile row.
private struct MilestoneSealTile: View {
    let item: MilestoneItem

    private var caption: String {
        guard let earnedAt = item.earnedAt else { return item.progressLabel }
        return "Earned \(earnedAt.formatted(.dateTime.day().month(.abbreviated)))"
    }

    var body: some View {
        VStack(spacing: 8) {
            MilestoneSeal(item: item)
            VStack(spacing: 2) {
                Text(item.badge.title).font(.caption.weight(.medium)).foregroundStyle(FieldColor.ink)
                Text(caption).font(.caption2)
                    .foregroundStyle(item.isEarned ? FieldBook.cover : FieldColor.mutedInk)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.badge.title), \(item.isEarned ? "earned" : item.progressLabel)")
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
