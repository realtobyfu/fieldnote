import SwiftUI

/// One milestone with the observer's standing against it.
struct MilestoneItem: Identifiable {
    let badge: BadgeDefinition
    let progress: Double
    let earnedAt: Date?

    var id: String { badge.id }
    var isEarned: Bool { earnedAt != nil }

    /// Outline glyphs read better inside a small seal than two of the catalog's filled ones.
    var symbol: String {
        switch badge.id {
        case "first_find": return "sun.horizon"
        case "species_25": return "camera.macro"
        default: return badge.symbol
        }
    }

    /// "3 of 10 species", or "0% of 25%" for catalog milestones.
    var progressLabel: String {
        let count = min(badge.target, Int((progress * Double(badge.target)).rounded()))
        if case .collectionPercent = badge.criterion { return "\(count)% of \(badge.target)%" }
        return "\(count) of \(badge.target) \(badge.progressUnit)"
    }

    /// Earned first, newest first; then the closest to being earned. Ties keep catalog order,
    /// so untouched tiers stay in order of difficulty.
    @MainActor
    static func all(from service: GamificationService) -> [MilestoneItem] {
        let stats = service.snapshot()
        let dates = service.achievements().reduce(into: [String: Date]()) { result, achievement in
            guard let date = achievement.unlockedAt else { return }
            result[achievement.identifier] = max(result[achievement.identifier] ?? .distantPast, date)
        }
        return BadgeCatalog.all.enumerated().map { index, badge in
            (index, MilestoneItem(badge: badge,
                                  progress: service.progress(for: badge, stats: stats),
                                  earnedAt: dates[badge.id]))
        }.sorted { a, b in
            if a.1.isEarned != b.1.isEarned { return a.1.isEarned }
            if let aDate = a.1.earnedAt, let bDate = b.1.earnedAt, aDate != bDate { return aDate > bDate }
            if !a.1.isEarned, a.1.progress != b.1.progress { return a.1.progress > b.1.progress }
            return a.0 < b.0
        }.map(\.1)
    }
}

/// A pressed seal: filled when earned, a wash with a progress ring until then.
struct MilestoneSeal: View {
    let item: MilestoneItem
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            if item.isEarned {
                Circle().fill(FieldBook.cover)
            } else {
                Circle().fill(FieldBook.wash)
                Circle().stroke(FieldBook.cover.opacity(0.18), lineWidth: 1)
                Circle().trim(from: 0, to: item.progress)
                    .stroke(FieldBook.cover, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Image(systemName: item.symbol)
                .font(.system(size: size * 0.38, weight: .regular))
                .foregroundStyle(item.isEarned ? Color.white : FieldColor.mutedInk)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
