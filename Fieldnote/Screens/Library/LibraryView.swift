//
//  LibraryView.swift
//  Fieldnote
//
//  The herbarium: every specimen, organised in volumes, with the index beneath.
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.appStore) private var store
    @Environment(\.capturePlant) private var capturePlant
    @Environment(TabBarVisibility.self) private var tabBar: TabBarVisibility?
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var selectedType: PlantType?
    @State private var sortOrder: SortOrder = .recent

    enum SortOrder: CaseIterable, Identifiable {
        case recent, name, confidence
        var id: Self { self }

        var label: String {
            switch self {
            case .recent: return "Recent first"
            case .name: return "By name"
            case .confidence: return "By confidence"
            }
        }
    }

    var body: some View {
        Group {
            if let appStore = store {
                content(appStore)
            } else {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle("Herbarium")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(
            PresentedSearchModifier(
                text: $searchText,
                isPresented: $isSearchPresented,
                prompt: "Search your specimens"
            )
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !isSearchPresented {
                    Button {
                        isSearchPresented = true
                    } label: {
                        Label("Search your specimens", systemImage: "magnifyingglass")
                    }
                    .accessibilityIdentifier("collection.search")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: BookUtilityRoute.profile) {
                    Label("Profile and settings", systemImage: "person.crop.circle")
                }
            }
        }
        .onChange(of: isSearchPresented) { _, presented in
            tabBar?.suppressed = presented
            if !presented {
                searchText = ""
            }
        }
        .onDisappear {
            tabBar?.suppressed = false
        }
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private func content(_ appStore: AppStore) -> some View {
        if appStore.plants.isEmpty {
            emptyHerbarium
        } else {
            let plants = filteredAndSortedPlants(from: appStore)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if trimmedQuery.isEmpty {
                        opening(appStore)
                        volumes(appStore)
                    }
                    index(plants)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await appStore.refresh() }
        }
    }

    // MARK: - Empty

    private var emptyHerbarium: some View {
        VStack(alignment: .leading, spacing: 20) {
            BookSectionLabel(text: "Fieldnote · Herbarium")
            Text("Every book begins with a discovery.").font(FieldBook.title)
            Text("Photograph a plant to start your herbarium. Your specimens will gather here.")
                .font(.body).foregroundStyle(FieldColor.mutedInk)
            if let capturePlant {
                // The same first action, worded and weighted as on the Journal's first run.
                Button(action: capturePlant) {
                    Label("Open the camera", systemImage: "camera")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(FieldBook.cover)
                .accessibilityIdentifier("collection.firstCapture")
            }
            Spacer()
        }
        .padding(24)
    }

    // MARK: - Opening

    private func opening(_ appStore: AppStore) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            BookSectionLabel(text: "Fieldnote · Herbarium")
            Text("Your herbarium").font(FieldBook.title).accessibilityAddTraits(.isHeader)
            summary(appStore)
            BookDoubleRule().padding(.top, 14)
        }
    }

    /// One line when it fits; otherwise the counts and the start date each keep a line,
    /// so a wrap never strands "since" or a separator.
    private func summary(_ appStore: AppStore) -> some View {
        let specimens = appStore.plants.count
        let counts = "\(specimens) \(specimens == 1 ? "specimen" : "specimens") · "
            + FieldBook.encounterCount(appStore.allEncounters.count)
        let since = appStore.allEncounters.map(\.date).min().map {
            "since \($0.formatted(.dateTime.month(.wide).year()))"
        }
        return ViewThatFits(in: .horizontal) {
            Text([counts, since].compactMap { $0 }.joined(separator: " · "))
            VStack(alignment: .leading, spacing: 2) {
                Text(counts)
                if let since { Text(since) }
            }
        }
        .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
    }

    // MARK: - Volumes

    /// Plant-type chips in canonical order, numbered like the book's volumes.
    private func volumes(_ appStore: AppStore) -> some View {
        let present = PlantType.allCases.filter { type in appStore.plants.contains { $0.plantType == type } }
        return VStack(alignment: .leading, spacing: 10) {
            BookSectionLabel(text: "Volumes")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    VolumeChip(numeral: nil, title: "All", count: appStore.plants.count,
                               isSelected: selectedType == nil) { selectedType = nil }
                    ForEach(Array(present.enumerated()), id: \.element) { index, type in
                        VolumeChip(numeral: roman(index + 1), title: type.label,
                                   count: appStore.plants.filter { $0.plantType == type }.count,
                                   isSelected: selectedType == type) { selectedType = type }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, -24)
        }
    }

    private func roman(_ number: Int) -> String {
        ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"][min(number - 1, 7)]
    }

    // MARK: - Index

    private func index(_ plants: [Plant]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                BookSectionLabel(text: "Index · \(plants.count)")
                Spacer()
                sortMenu
            }
            .padding(.bottom, 4)
            if plants.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No matching specimens").font(FieldBook.heading)
                    Text("Try another name or show the whole index.")
                        .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    Button("Show everything") {
                        searchText = ""
                        selectedType = nil
                        isSearchPresented = false
                    }
                    .frame(minHeight: 44)
                }
                .padding(.vertical, 20)
            }
            LazyVStack(spacing: 0) {
                ForEach(plants) { plant in
                    NavigationLink(value: plant) {
                        BookSpecimenRow(plant: plant).padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("collection.specimen.\(plant.scientificName)")
                    Divider()
                }
            }
        }
    }

    /// The sort control sits where the order is stated, on the index it reorders.
    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sortOrder) {
                ForEach(SortOrder.allCases) { Text($0.label).tag($0) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(sortOrder.label)
                Image(systemName: "chevron.up.chevron.down").font(.caption2.weight(.semibold))
            }
            .font(.caption.weight(.medium))
            // A 44pt target without pushing the index down the page.
            .padding(.vertical, 15).padding(.leading, 12)
            .contentShape(Rectangle())
        }
        .padding(.vertical, -15)
        .accessibilityLabel("Sort, \(sortOrder.label)")
        .accessibilityIdentifier("collection.sort")
    }

    // MARK: - Filtering and sorting

    private func filteredAndSortedPlants(from appStore: AppStore) -> [Plant] {
        var plants = appStore.plants

        if !trimmedQuery.isEmpty {
            plants = plants.filter {
                $0.commonName.localizedCaseInsensitiveContains(trimmedQuery) ||
                $0.scientificName.localizedCaseInsensitiveContains(trimmedQuery) ||
                $0.family.localizedCaseInsensitiveContains(trimmedQuery)
            }
        }

        if let selectedType {
            plants = plants.filter { $0.plantType == selectedType }
        }

        switch sortOrder {
        case .recent:
            return plants.sorted {
                ($0.lastSeenDate ?? .distantPast) > ($1.lastSeenDate ?? .distantPast)
            }
        case .name:
            return plants.sorted { $0.commonName < $1.commonName }
        case .confidence:
            return plants.sorted { $0.averageConfidence > $1.averageConfidence }
        }
    }
}

// MARK: - Volume chip

private struct VolumeChip: View {
    let numeral: String?
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    private static let numeralFont = Font.custom("CormorantGaramond-Regular", size: 18, relativeTo: .subheadline)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let numeral {
                    Text(numeral).font(Self.numeralFont)
                        .foregroundStyle(isSelected ? Color.white : FieldColor.botanicalBrown)
                }
                Text(title).font(FieldType.chipLabel)
                Text("· \(count)").font(FieldType.chipLabel).opacity(0.75)
            }
            .foregroundStyle(isSelected ? Color.white : FieldColor.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(isSelected ? FieldBook.cover : Color.clear, in: Capsule())
            .overlay(Capsule().stroke(isSelected ? FieldBook.cover : FieldColor.separator, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel([numeral, title, "\(count)"].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
