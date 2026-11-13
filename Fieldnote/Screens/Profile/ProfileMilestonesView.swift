import SwiftUI

struct ProfileMilestonesView: View {
    @Environment(\.gamificationService) private var gamification
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedMilestone: MilestoneItem?

    var body: some View {
        ScrollView {
            if let gamification {
                let milestones = MilestoneItem.all(from: gamification)
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        BookSectionLabel(text: "Along the way")
                        Text("Milestones").font(FieldBook.title).accessibilityAddTraits(.isHeader)
                        Text("\(milestones.filter(\.isEarned).count) of \(milestones.count) earned")
                            .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
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

    private func milestoneRow(_ item: MilestoneItem) -> some View {
        HStack(alignment: .top, spacing: 16) {
            MilestoneSeal(item: item, size: 44)
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
            BookChevron().padding(.top, 12)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileMilestoneSheet: View {
    let item: MilestoneItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    MilestoneSeal(item: item, size: 76)
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
