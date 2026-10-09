import SwiftUI

struct ProfileMilestonesView: View {
    @Environment(\.gamificationService) private var gamification
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedMilestone: ProfileMilestone?

    var body: some View {
        ScrollView {
            if let gamification {
                let stats = gamification.snapshot()
                let profile = gamification.profile()
                let milestones = milestoneItems(gamification, stats: stats)
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 12) {
                        BookSectionLabel(text: "Along the way")
                        Text("A growing practice.").font(FieldBook.title).accessibilityAddTraits(.isHeader)
                        Text("Small markers of curiosity, earned one entry at a time.")
                            .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                        Divider()
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Level \(profile.level)").font(FieldBook.heading)
                                Text("\(profile.xpIntoLevel) / \(profile.xpForNextLevel) XP")
                                    .font(.caption).monospacedDigit()
                            }
                        } else {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Level \(profile.level)").font(FieldBook.heading)
                                Spacer()
                                Text("\(profile.xpIntoLevel) / \(profile.xpForNextLevel) XP")
                                    .font(.caption).monospacedDigit()
                            }
                        }
                        ProgressView(value: profile.levelProgress)
                            .tint(FieldBook.cover)
                            .accessibilityLabel("Progress to level \(profile.level + 1)")
                            .accessibilityValue("\(Int(profile.levelProgress * 100)) percent")
                        Text("\(stats.currentStreak)-day current streak · \(profile.longestStreak)-day longest streak")
                            .font(.caption).foregroundStyle(FieldColor.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FieldBook.wash)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(milestones.filter(\.isEarned).count) of \(milestones.count) earned")
                            .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                        LazyVStack(spacing: 0) {
                            ForEach(milestones) { item in
                                Button { selectedMilestone = item } label: {
                                    milestoneRow(item)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("profile.milestone.\(item.id)")
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle("Milestones")
        .navigationBarTitleDisplayMode(.inline)
        .task { gamification?.reconcile() }
        .sheet(item: $selectedMilestone) { item in
            ProfileMilestoneSheet(item: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func milestoneItems(_ service: GamificationService, stats: GamificationService.Stats) -> [ProfileMilestone] {
        let dates = service.achievements().reduce(into: [String: Date]()) { result, achievement in
            guard let date = achievement.unlockedAt else { return }
            result[achievement.identifier] = max(result[achievement.identifier] ?? .distantPast, date)
        }
        return BadgeCatalog.all.map {
            ProfileMilestone(badge: $0, progress: service.progress(for: $0, stats: stats), earnedAt: dates[$0.id])
        }.sorted {
            if $0.isEarned != $1.isEarned { return $0.isEarned }
            if $0.isEarned, $0.earnedAt != $1.earnedAt {
                return ($0.earnedAt ?? .distantPast) > ($1.earnedAt ?? .distantPast)
            }
            if !$0.isEarned, $0.progress != $1.progress { return $0.progress > $1.progress }
            return $0.badge.title < $1.badge.title
        }
    }

    private func milestoneRow(_ item: ProfileMilestone) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ProfileMilestoneSeal(item: item, size: 44)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.badge.title).font(FieldBook.name).foregroundStyle(FieldColor.ink)
                Text(item.badge.requirementText).font(.caption).foregroundStyle(FieldColor.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
                if let date = item.earnedAt {
                    Text("Earned \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2).foregroundStyle(FieldBook.cover)
                } else {
                    Text(item.progressLabel).font(.caption2).foregroundStyle(FieldColor.mutedInk)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption2.weight(.medium))
                .foregroundStyle(FieldColor.tertiaryInk).padding(.top, 12)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileMilestone: Identifiable {
    let badge: BadgeDefinition
    let progress: Double
    let earnedAt: Date?
    var id: String { badge.id }
    var isEarned: Bool { earnedAt != nil }
    var progressLabel: String {
        let count = min(badge.target, Int((progress * Double(badge.target)).rounded()))
        if case .collectionPercent = badge.criterion { return "\(count)% of \(badge.target)% required" }
        return "\(count) of \(badge.target) \(badge.progressUnit)"
    }
    var symbol: String {
        switch badge.id {
        case "first_find": return "sun.horizon"
        case "species_25": return "camera.macro"
        default: return badge.symbol
        }
    }
}

private struct ProfileMilestoneSeal: View {
    let item: ProfileMilestone
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(FieldBook.wash)
            Circle().stroke(FieldBook.cover.opacity(0.18), lineWidth: 1)
            if !item.isEarned {
                Circle().trim(from: 0, to: item.progress)
                    .stroke(FieldBook.cover, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Image(systemName: item.symbol)
                .font(.system(size: size * 0.38, weight: .regular))
                .foregroundStyle(item.isEarned ? FieldBook.cover : FieldColor.mutedInk)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct ProfileMilestoneSheet: View {
    let item: ProfileMilestone
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ProfileMilestoneSeal(item: item, size: 76)
                    Text(item.badge.title).font(FieldBook.title).accessibilityAddTraits(.isHeader)
                    Text(item.badge.detail).font(.body).foregroundStyle(FieldColor.mutedInk)
                    Divider()
                    VStack(alignment: .leading, spacing: 10) {
                        BookSectionLabel(text: "Requirement")
                        Text(item.badge.requirementText).font(.body)
                        if let date = item.earnedAt {
                            Label("Earned \(date.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark.seal")
                                .font(.subheadline).foregroundStyle(FieldBook.cover)
                        } else {
                            Text(item.progressLabel).font(.subheadline)
                            ProgressView(value: item.progress).tint(FieldBook.cover)
                                .accessibilityLabel("Milestone progress")
                                .accessibilityValue("\(Int(item.progress * 100)) percent")
                        }
                        if case .collectionPercent = item.badge.criterion {
                            Text("Progress uses the currently selected catalog. Earned milestones stay in your journal.")
                                .font(.caption).foregroundStyle(FieldColor.mutedInk)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(FieldBook.paper.ignoresSafeArea())
            .navigationTitle("Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
