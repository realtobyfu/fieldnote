//
//  LibraryView.swift
//  Fieldnote
//
//  Main library screen with grid view, search, filter, and sort
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.appStore) private var store
    @State private var searchText = ""
    @State private var selectedType: PlantType?
    @State private var sortOrder: SortOrder = .recent

    enum SortOrder {
        case recent
        case name
        case confidence

        var label: String {
            switch self {
            case .recent: return "Recent"
            case .name: return "Name"
            case .confidence: return "Confidence"
            }
        }
    }

    var body: some View {
        Group {
            if let appStore = store {
                libraryContent(appStore: appStore)
            } else {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app.")
                )
            }
        }
        .background(FieldColor.paper)
        .navigationTitle("Collection")
        // Plant destination is provided by the enclosing stack (Journal / Map),
        // which now pushes this view as the "Collection" screen.
        .searchable(text: $searchText, prompt: "Search plants...")
    }

    @ViewBuilder
    private func libraryContent(appStore: AppStore) -> some View {
        let plants = filteredAndSortedPlants(from: appStore)

        if plants.isEmpty {
            if searchText.isEmpty && selectedType == nil {
                EmptyStateView(
                    icon: "leaf",
                    title: "No Plants Yet",
                    message: "Start your field journal by capturing your first plant encounter.",
                    actionLabel: "Capture Plant",
                    action: {
                        appStore.selectedTab = .capture
                    }
                )
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    message: "We couldn't find any plants matching your filters. Try adjusting your search or filters."
                )
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: FieldSpace.md) {
                    // Filter chips
                    filterChips(appStore: appStore)

                    // Sort menu
                    HStack {
                        Text("\(plants.count) plants")
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.mutedInk)

                        Spacer()

                        Menu {
                            Button("Recent") { sortOrder = .recent }
                            Button("Name") { sortOrder = .name }
                            Button("Confidence") { sortOrder = .confidence }
                        } label: {
                            HStack(spacing: FieldSpace.xs) {
                                Text(sortOrder.label)
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.ink)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(FieldColor.mutedInk)
                            }
                        }
                    }

                    // Plant grid
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: FieldSpace.md)
                    ], spacing: FieldSpace.md) {
                        ForEach(plants) { plant in
                            NavigationLink(value: plant) {
                                PlantCard(plant: plant, layout: .grid)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(FieldSpace.md)
            }
            .refreshable {
                await appStore.refresh()
            }
        }
    }

    // MARK: - Filter Chips

    /// Plant-type chips (only the types actually present in the collection), in a
    /// stable canonical order — far friendlier than raw botanical family names.
    private func filterChips(appStore: AppStore) -> some View {
        let present = Set(appStore.plants.map { $0.plantType })
        let types = PlantType.allCases.filter { present.contains($0) }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FieldSpace.xs) {
                FilterChip("All", isSelected: selectedType == nil) {
                    selectedType = nil
                }

                ForEach(types) { type in
                    FilterChip(type.label, isSelected: selectedType == type) {
                        selectedType = type
                    }
                }
            }
        }
    }

    // MARK: - Filtered and Sorted Plants

    private func filteredAndSortedPlants(from appStore: AppStore) -> [Plant] {
        var plants = appStore.plants

        // Apply search filter
        if !searchText.isEmpty {
            plants = plants.filter {
                $0.commonName.localizedCaseInsensitiveContains(searchText) ||
                $0.scientificName.localizedCaseInsensitiveContains(searchText) ||
                $0.family.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply plant-type filter
        if let selectedType {
            plants = plants.filter { $0.plantType == selectedType }
        }

        // Apply sort
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

// MARK: - Filter Chip Component

private struct FilterChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    init(_ text: String, isSelected: Bool, action: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(FieldType.chipLabel)
                .foregroundColor(isSelected ? .white : FieldColor.ink)
                .padding(.horizontal, FieldSpace.sm)
                .padding(.vertical, FieldSpace.xs)
                .background(isSelected ? FieldColor.accent : FieldColor.surface)
                .cornerRadius(FieldRadius.chip)
                .overlay(
                    RoundedRectangle(cornerRadius: FieldRadius.chip)
                        .stroke(isSelected ? FieldColor.accent : FieldColor.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

//#Preview {
//    NavigationStack {
//        LibraryView()
//            .environment(AppStore())
//    }
//}
