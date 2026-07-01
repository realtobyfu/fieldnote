//
//  ProfileView.swift
//  Fieldnote
//
//  Profile tab (Wave 2): the gamification home — level/XP, streak, collection,
//  and the badge grid — with the existing Settings reachable below.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.gamificationService) private var gamification
    @State private var isBadgeGridExpanded = false
    @State private var isSettingsExpanded = false

    var body: some View {
        ScrollView {
            VStack(spacing: FieldSpace.lg) {
                if let gamification {
                    let stats = gamification.snapshot()
                    let profile = gamification.profile()

                    levelHero(profile: profile, stats: stats)
                    statTiles(stats)
                    badgeGrid(gamification: gamification, stats: stats)
                }

                ProfileMembershipCard()

                settingsPill
                if isSettingsExpanded {
                    ProfileSettingsSection()
                        .transition(.opacity)
                }
            }
            .padding(FieldSpace.md)
            .padding(.bottom, 100)
            .animation(.smooth(duration: 0.3), value: isSettingsExpanded)
        }
        .background(
            LinearGradient(colors: [FieldColor.canvasTop, FieldColor.canvasBottom],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Level hero

    private func levelHero(profile: FieldProfile, stats: GamificationService.Stats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LEVEL")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("\(profile.level)")
                        .font(FieldType.displayTitle)
                        .foregroundStyle(.white)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "laurel.leading")
                    Text("\(profile.currentStreak)")
                        .monospacedDigit()
                    Image(systemName: "laurel.trailing")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(.white.opacity(0.18), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 7) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.25))
                        Capsule().fill(.white)
                            .frame(width: max(8, geo.size.width * profile.levelProgress))
                    }
                }
                .frame(height: 8)
                Text("\(profile.xpIntoLevel) / \(profile.xpForNextLevel) XP to level \(profile.level + 1)")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [FieldColor.accent, FieldColor.accentDeep],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .fieldShadow(FieldShadow.cardHover)
    }

    // MARK: - Stat tiles

    private func statTiles(_ stats: GamificationService.Stats) -> some View {
        HStack(spacing: FieldSpace.sm) {
            statTile(value: stats.uniqueSpecies, label: "Species")
            statTile(value: stats.uniqueFamilies, label: "Families")
            statTile(value: stats.uniqueLocations, label: "Places")
            statTile(value: stats.collectionPercent, label: "Catalog", suffix: "%")
        }
    }

    private func statTile(value: Int, label: String, suffix: String = "") -> some View {
        VStack(spacing: 3) {
            Text("\(value)\(suffix)")
                .font(FieldType.title3)
                .foregroundStyle(FieldColor.ink)
            Text(label)
                .font(FieldType.caption)
                .foregroundStyle(FieldColor.mutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(FieldColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .fieldShadow(FieldShadow.card)
    }

    // MARK: - Badges

    private func badgeGrid(gamification: GamificationService, stats: GamificationService.Stats) -> some View {
        let unlockDates = gamification.achievements().reduce(into: [String: Date]()) { dates, achievement in
            guard let unlockedAt = achievement.unlockedAt else { return }
            dates[achievement.identifier] = max(dates[achievement.identifier] ?? .distantPast, unlockedAt)
        }
        let items = BadgeCatalog.all.map { badge in
            BadgeDisplayItem(
                badge: badge,
                progress: gamification.progress(for: badge, stats: stats),
                unlockedAt: unlockDates[badge.id]
            )
        }
        let recentlyEarned = items
            .filter { $0.unlockedAt != nil }
            .sorted(by: BadgeDisplayItem.wasEarnedMoreRecently)
        let closestLocked = items
            .filter { $0.unlockedAt == nil }
            .sorted(by: BadgeDisplayItem.isCloserToCompletion)

        var featured = Array(recentlyEarned.prefix(2))
        if let closest = closestLocked.first {
            featured.append(closest)
        }
        if featured.count < 3 {
            let featuredIDs = Set(featured.map(\.id))
            featured.append(
                contentsOf: items
                    .filter { !featuredIDs.contains($0.id) }
                    .prefix(3 - featured.count)
            )
        }
        let featuredIDs = Set(featured.map(\.id))
        let remaining = items.filter { !featuredIDs.contains($0.id) }
        let unlockedCount = items.filter(\.isUnlocked).count
        let columns = [GridItem(.adaptive(minimum: 96), spacing: FieldSpace.md)]

        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Badges")
                    .font(FieldType.title3)
                    .foregroundStyle(FieldColor.ink)

                Spacer()

                Text("\(unlockedCount) / \(BadgeCatalog.all.count)")
                    .font(FieldType.footnote.weight(.semibold))
                    .foregroundStyle(FieldColor.mutedInk)

                Button(action: toggleBadgeGrid) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FieldColor.mutedInk)
                        .rotationEffect(.degrees(isBadgeGridExpanded ? 180 : 0))
                        .frame(width: 30, height: 30)
                        .background(FieldColor.separator.opacity(0.55), in: Circle())
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .contentShape(.circle)
                .accessibilityLabel(isBadgeGridExpanded ? "Hide all badges" : "Show all badges")
                .accessibilityHint(isBadgeGridExpanded ? "Collapses the remaining badges" : "Expands the remaining badges")
            }
            .padding(.horizontal, FieldSpace.md)
            .padding(.vertical, 10)

            HStack(alignment: .top, spacing: FieldSpace.sm) {
                ForEach(featured) { item in
                    FeaturedBadgeTile(item: item)
                }
            }
            .padding(.horizontal, 12)

            if isBadgeGridExpanded {

                LazyVGrid(columns: columns, spacing: FieldSpace.md) {
                    ForEach(remaining) { item in
                        BadgeCell(
                            badge: item.badge,
                            isUnlocked: item.isUnlocked,
                            progress: item.progress
                        )
                    }
                }
                .padding(.horizontal, FieldSpace.sm)
                .padding(.vertical, FieldSpace.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(FieldColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .fieldShadow(FieldShadow.card)
        .animation(.snappy(duration: 0.25), value: isBadgeGridExpanded)
    }

    private func toggleBadgeGrid() {
        isBadgeGridExpanded.toggle()
    }

    // MARK: - Settings pill

    /// Collapsed-by-default pill that expands the settings cards inline (no push).
    private var settingsPill: some View {
        Button {
            isSettingsExpanded.toggle()
        } label: {
            HStack(spacing: FieldSpace.sm) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(FieldColor.mutedInk)
                Text("Settings & Storage")
                    .font(FieldType.body)
                    .foregroundStyle(FieldColor.ink)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FieldColor.tertiaryInk)
                    .rotationEffect(.degrees(isSettingsExpanded ? 180 : 0))
            }
            .padding(16)
            .background(FieldColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .fieldShadow(FieldShadow.card)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings & Storage")
        .accessibilityHint(isSettingsExpanded ? "Collapses settings" : "Expands settings")
    }
}

// MARK: - Featured badges

private struct BadgeDisplayItem: Identifiable {
    let badge: BadgeDefinition
    let progress: Double
    let unlockedAt: Date?

    var id: String { badge.id }
    var isUnlocked: Bool { unlockedAt != nil }

    nonisolated static func wasEarnedMoreRecently(_ lhs: Self, _ rhs: Self) -> Bool {
        let lhsDate = lhs.unlockedAt ?? .distantPast
        let rhsDate = rhs.unlockedAt ?? .distantPast
        if lhsDate != rhsDate {
            return lhsDate > rhsDate
        }
        return lhs.badge.title < rhs.badge.title
    }

    nonisolated static func isCloserToCompletion(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.progress != rhs.progress {
            return lhs.progress > rhs.progress
        }
        return lhs.badge.title < rhs.badge.title
    }
}

private struct FeaturedBadgeTile: View {
    let item: BadgeDisplayItem

    var body: some View {
        VStack(spacing: FieldSpace.sm) {
            ZStack {
                Circle()
                    .fill(item.isUnlocked ? FieldColor.accent.opacity(0.16) : FieldColor.separator.opacity(0.65))

                if !item.isUnlocked {
                    Circle()
                        .stroke(FieldColor.separator, lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: item.progress)
                        .stroke(
                            FieldColor.accent.opacity(0.8),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                Image(systemName: item.badge.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(item.isUnlocked ? FieldColor.accentDeep : FieldColor.tertiaryInk)
            }
            .frame(width: 52, height: 52)

            Text(item.badge.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(item.isUnlocked ? FieldColor.ink : FieldColor.mutedInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 30, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Badge cell

private struct BadgeCell: View {
    let badge: BadgeDefinition
    let isUnlocked: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? FieldColor.accent.opacity(0.16) : FieldColor.separator.opacity(0.6))
                Image(systemName: badge.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isUnlocked ? FieldColor.accentDeep : FieldColor.tertiaryInk)
            }
            .frame(width: 58, height: 58)

            Text(badge.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isUnlocked ? FieldColor.ink : FieldColor.mutedInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 30, alignment: .top)

            if !isUnlocked {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(FieldColor.separator)
                        Capsule().fill(FieldColor.accent.opacity(0.7))
                            .frame(width: max(0, geo.size.width * progress))
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .opacity(isUnlocked ? 1 : 0.85)
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
