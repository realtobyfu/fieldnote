//
//  JournalHomeView.swift
//  Fieldnote
//
//  The book's opening page: what you noticed, by day, and what to look for next.
//

import SwiftUI
import UIKit

struct JournalHomeView: View {
    @Environment(\.appStore) private var store
    @Environment(\.capturePlant) private var capturePlant
    @Environment(\.openURL) private var openURL
    @State private var showRegionPicker = false
    @State private var didRequestLocalCatalog = false

    var body: some View {
        ScrollView {
            if let store {
                VStack(alignment: .leading, spacing: 28) {
                    opening(store)
                    if store.allEncounters.isEmpty {
                        firstRun
                    } else {
                        thisWeek(store)
                    }
                    worthLookingFor(store)
                }
                .padding(24)
            }
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: BookUtilityRoute.map) {
                    Label("Your places", systemImage: "map")
                }
                .accessibilityIdentifier("journal.map")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: BookUtilityRoute.profile) {
                    Label("Profile and settings", systemImage: "person.crop.circle")
                }
            }
        }
        .navigationDestination(for: NearbyPlantRoute.self) { route in
            CatalogPlantDetailView(catalogPlant: route.plant, photoFirst: true)
        }
        .task {
            // Same resilient load Nearby performs: no location means no tiles, not an error.
            guard let store, !didRequestLocalCatalog else { return }
            didRequestLocalCatalog = true
            await store.refreshLocalCatalog()
        }
        .sheet(isPresented: $showRegionPicker) {
            if let store {
                RegionPickerSheet(
                    selectedRegion: store.selectedRegionOverride,
                    detectionState: store.regionDetectionState,
                    onDetect: { await store.detectRegion() },
                    onOpenSettings: openLocationSettings,
                    onSelect: { region in Task { await store.selectRegion(region) } }
                )
            }
        }
    }

    // MARK: - Opening

    private func opening(_ store: AppStore) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            BookSectionLabel(text: "Field journal")
            Text(Date.now, format: .dateTime.month(.wide))
                .font(FieldBook.title)
                .accessibilityAddTraits(.isHeader)
            Text(monthSummary(store))
                .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
        }
    }

    /// The line under the month counts that month only, so the title and the figure agree.
    private func monthSummary(_ store: AppStore) -> String {
        guard !store.allEncounters.isEmpty else { return "Your journal begins with a walk." }
        let calendar = Calendar.current
        let thisMonth = store.allEncounters.filter {
            calendar.isDate($0.date, equalTo: .now, toGranularity: .month)
        }
        guard !thisMonth.isEmpty else { return "No entries yet this month." }
        let places = Set(thisMonth.compactMap(\.displayLocationName)).count
        let entries = entryCount(thisMonth.count)
        return places > 0 ? "\(entries) across \(placeCount(places))" : entries
    }

    private func entryCount(_ count: Int) -> String { "\(count) \(count == 1 ? "entry" : "entries")" }
    private func placeCount(_ count: Int) -> String { "\(count) \(count == 1 ? "place" : "places")" }

    // MARK: - First run

    private var firstRun: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Photograph a plant that catches your eye. It will be identified and pressed in here, with the place and the day.")
                .font(.body).foregroundStyle(FieldColor.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
            if let capturePlant {
                Button(action: capturePlant) {
                    Label("Open the camera", systemImage: "camera")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(FieldBook.cover)
                .accessibilityIdentifier("journal.firstCapture")
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 18) { steps }
                VStack(alignment: .leading, spacing: 8) { steps }
            }
            .padding(.top, 6)
        }
    }

    @ViewBuilder private var steps: some View {
        step("I", "Photograph")
        step("II", "Identify")
        step("III", "Pressed into your herbarium")
    }

    private func step(_ numeral: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(numeral).font(FieldBook.name).foregroundStyle(FieldColor.botanicalBrown)
            Text(text).font(.caption).foregroundStyle(FieldColor.mutedInk)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - This week

    private func thisWeek(_ store: AppStore) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let cutoff = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let recent = store.allEncounters.filter { $0.date >= cutoff }.sorted { $0.date > $1.date }
        let days = Dictionary(grouping: recent) { calendar.startOfDay(for: $0.date) }
            .sorted { $0.key > $1.key }
        return VStack(alignment: .leading, spacing: 16) {
            Text("This week").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
            if recent.isEmpty {
                Text("Nothing noticed this week yet.")
                    .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
            }
            ForEach(days, id: \.key) { group in
                VStack(alignment: .leading, spacing: 0) {
                    BookSectionLabel(text: dayLabel(group.key, calendar: calendar))
                        .padding(.bottom, 2)
                    ForEach(group.value) { encounter in
                        if let plant = encounter.plant {
                            NavigationLink(value: plant) {
                                JournalEntryRow(encounter: encounter, plant: plant)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("journal.entry.\(plant.scientificName)")
                            Divider()
                        }
                    }
                }
            }
            NavigationLink(value: BookUtilityRoute.history) {
                HStack(spacing: 4) {
                    Text("All \(entryCount(store.allEncounters.count))")
                    Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                }
                .font(.subheadline.weight(.medium))
                .frame(minHeight: 44)
            }
            .accessibilityIdentifier("journal.history")
        }
    }

    private func dayLabel(_ day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide))
    }

    // MARK: - Worth looking for

    private func worthLookingFor(_ store: AppStore) -> some View {
        let picks = Array(store.localCatalogItems.filter { !store.isDiscovered($0.catalogPlant) }.prefix(3))
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Worth looking for").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
                BookSectionLabel(text: regionName(store).map { "Near \($0)" } ?? "Around you")
            }
            if picks.isEmpty {
                Text(store.hasLocalCatalog
                     ? "Everything reported nearby is already in your herbarium."
                     : "Choose an area to see what grows near you.")
                    .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(picks) { item in
                            NavigationLink(value: NearbyPlantRoute(plant: item.catalogPlant)) {
                                lookForTile(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -24)
            }
            Button {
                store.prepareRegionPicker()
                showRegionPicker = true
            } label: {
                // Not the map glyph: that one already means "Your places" in this screen's toolbar.
                Label(store.hasLocalCatalog ? "Change area" : "Choose an area", systemImage: "location")
                    .font(.subheadline.weight(.medium))
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("journal.changeArea")
        }
    }

    private func lookForTile(_ item: LocalCatalogItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            NearbyPlantImage(plant: item.catalogPlant)
                .frame(width: 150, height: 110).clipped()
                .clipShape(.rect(cornerRadius: 12))
            Text(item.catalogPlant.commonName).font(FieldBook.tileName)
                .lineLimit(2).multilineTextAlignment(.leading)
            Text(item.explanationCodes.contains(.commonlyReported) ? "Commonly reported" : "Reported nearby")
                .font(.caption.weight(.medium)).foregroundStyle(FieldBook.cover)
        }
        .frame(width: 150, alignment: .leading)
        .foregroundStyle(FieldColor.ink)
    }

    private func regionName(_ store: AppStore) -> String? {
        if case .some(.region(let region)) = store.selectedRegionOverride { return region.name }
        return store.localityProfile?.displayRegion
    }

    private func openLocationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

/// One encounter in the journal: the plant, where and when, and the observer's note.
private struct JournalEntryRow: View {
    let encounter: Encounter
    let plant: Plant

    private var meta: String {
        [encounter.displayLocationName, encounter.date.formatted(date: .omitted, time: .shortened)]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private var note: String? {
        let trimmed = encounter.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            BookPlantImage(plant: plant).frame(width: 56, height: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName).font(FieldBook.name)
                Text(plant.scientificName).font(FieldBook.scientificSmall).foregroundStyle(FieldColor.mutedInk)
                Text(meta).font(.caption).foregroundStyle(FieldColor.mutedInk)
                if let note {
                    Text("“\(note)”").font(FieldBook.note)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
            BookChevron().padding(.top, 8)
        }
        .foregroundStyle(FieldColor.ink)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
