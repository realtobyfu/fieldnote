//
//  GamificationService.swift
//  Fieldnote
//
//  Wave 2 gamification engine. Derives streak / XP / collection stats from the
//  live AppStore signals (so they're always recomputable), persists a FieldProfile
//  cache + Achievement unlock rows, and exposes a single recordObservation() hook
//  called from the capture save flow.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class GamificationService {
    private let modelContext: ModelContext
    private unowned let appStore: AppStore

    /// Badges newly unlocked this session, awaiting a celebration toast.
    var pendingCelebrations: [BadgeDefinition] = []

    init(modelContext: ModelContext, appStore: AppStore) {
        self.modelContext = modelContext
        self.appStore = appStore
        reconcile()
    }

    // MARK: - Stats snapshot

    struct Stats {
        var totalFinds: Int
        var uniqueSpecies: Int
        var uniqueFamilies: Int
        var uniqueLocations: Int
        var collectionPercent: Int
        var currentStreak: Int
        var season: String
        var seasonalFinds: Int
    }

    func snapshot() -> Stats {
        let encounters = appStore.allEncounters
        let catalogTotal = appStore.catalogPlants.count
        let discovered = appStore.discoveredCatalogPlants.count
        let percent = catalogTotal > 0 ? Int((Double(discovered) / Double(catalogTotal) * 100).rounded()) : 0
        let season = Self.seasonName(.now)
        let year = Calendar.current.component(.year, from: .now)
        let seasonalFinds = encounters.filter {
            Self.seasonName($0.date) == season &&
            Calendar.current.component(.year, from: $0.date) == year
        }.count

        return Stats(
            totalFinds: encounters.count,
            uniqueSpecies: appStore.plants.count,
            uniqueFamilies: appStore.uniqueFamilies.count,
            uniqueLocations: appStore.uniqueLocations.count,
            collectionPercent: percent,
            currentStreak: Self.streak(from: encounters),
            season: season,
            seasonalFinds: seasonalFinds
        )
    }

    // MARK: - Persisted reads

    func profile() -> FieldProfile {
        if let existing = (try? modelContext.fetch(FetchDescriptor<FieldProfile>()))?.first {
            return existing
        }
        let created = FieldProfile()
        modelContext.insert(created)
        return created
    }

    func achievements() -> [Achievement] {
        (try? modelContext.fetch(FetchDescriptor<Achievement>())) ?? []
    }

    private func unlockedIdentifiers() -> Set<String> {
        Set(achievements().filter { $0.unlockedAt != nil }.map(\.identifier))
    }

    // MARK: - Hook

    /// Called once from the capture save flow after an encounter is added.
    func recordObservation() {
        reconcile(celebrate: true)
    }

    func markCelebrationsSeen() {
        pendingCelebrations.removeAll()
    }

    // MARK: - Reconcile

    /// Recompute derived stats, unlock any newly-satisfied badges, and persist.
    func reconcile(celebrate: Bool = false) {
        let stats = snapshot()
        var unlocked = unlockedIdentifiers()

        for badge in BadgeCatalog.all where !unlocked.contains(badge.id) {
            if Self.isSatisfied(badge.criterion, stats: stats) {
                modelContext.insert(Achievement(identifier: badge.id, unlockedAt: .now))
                unlocked.insert(badge.id)
                if celebrate { pendingCelebrations.append(badge) }
            }
        }

        let p = profile()
        p.currentStreak = stats.currentStreak
        p.longestStreak = max(p.longestStreak, stats.currentStreak)
        p.totalXP = Self.xp(for: stats, unlockedCount: unlocked.count)
        p.lastObservationDate = appStore.allEncounters.first?.date

        try? modelContext.save()
    }

    // MARK: - Badge evaluation

    static func isSatisfied(_ criterion: BadgeCriterion, stats: Stats) -> Bool {
        switch criterion {
        case .totalFinds(let n): return stats.totalFinds >= n
        case .uniqueSpecies(let n): return stats.uniqueSpecies >= n
        case .uniqueFamilies(let n): return stats.uniqueFamilies >= n
        case .uniqueLocations(let n): return stats.uniqueLocations >= n
        case .collectionPercent(let n): return stats.collectionPercent >= n
        case .streak(let n): return stats.currentStreak >= n
        case .seasonalFinds(let season, let count):
            return stats.season == season && stats.seasonalFinds >= count
        }
    }

    func progress(for badge: BadgeDefinition, stats: Stats) -> Double {
        let current: Int
        switch badge.criterion {
        case .totalFinds: current = stats.totalFinds
        case .uniqueSpecies: current = stats.uniqueSpecies
        case .uniqueFamilies: current = stats.uniqueFamilies
        case .uniqueLocations: current = stats.uniqueLocations
        case .collectionPercent: current = stats.collectionPercent
        case .streak: current = stats.currentStreak
        case .seasonalFinds(let season, _): current = stats.season == season ? stats.seasonalFinds : 0
        }
        return badge.target > 0 ? min(1, Double(current) / Double(badge.target)) : 0
    }

    // MARK: - Derivation helpers

    static func xp(for stats: Stats, unlockedCount: Int) -> Int {
        stats.totalFinds * 10 + stats.uniqueSpecies * 15 + stats.uniqueFamilies * 20 + unlockedCount * 50
    }

    static func seasonName(_ date: Date) -> String {
        switch Calendar.current.component(.month, from: date) {
        case 12, 1, 2: return "Winter"
        case 3, 4, 5: return "Spring"
        case 6, 7, 8: return "Summer"
        default: return "Autumn"
        }
    }

    static func streak(from encounters: [Encounter]) -> Int {
        let cal = Calendar.current
        let days = Set(encounters.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var day = cal.startOfDay(for: .now)
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
