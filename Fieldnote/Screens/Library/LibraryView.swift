//
//  LibraryView.swift
//  Fieldnote
//
//  A searchable specimen index with encounter history and a personal map.
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.appStore) private var store
    @State private var searchText = ""
    @State private var selectedType: PlantType?
    @State private var sortOrder: SortOrder = .recent
    @FocusState private var searchFocused: Bool
    @Environment(\.capturePlant) private var capturePlant

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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle("Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: BookUtilityRoute.profile) {
                    Label("Profile and settings", systemImage: "person.crop.circle")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { searchFocused = false }
            }
        }
    }

    @ViewBuilder
    private func libraryContent(appStore: AppStore) -> some View {
        let plants = filteredAndSortedPlants(from: appStore)

        if appStore.plants.isEmpty {
            if searchText.isEmpty && selectedType == nil {
                VStack(alignment: .leading, spacing: 20) {
                    BookSectionLabel(text: "Your collection")
                    Text("Every book begins with a discovery.").font(FieldBook.title)
                    Text("Photograph a plant to start your herbarium. Your encounters will gather here.")
                        .font(.body).foregroundStyle(FieldColor.mutedInk)
                    Button {
                        capturePlant?()
                    } label: {
                        Label("Capture a plant", systemImage: "camera")
                            .font(.body.weight(.medium)).frame(minHeight: 48)
                    }
                    Spacer()
                }
                .padding(24)
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    message: "We couldn't find any plants matching your filters. Try adjusting your search or filters."
                )
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your collection").font(FieldBook.title)
                        Text("\(appStore.plants.count) specimens · \(appStore.allEncounters.count) encounters")
                            .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    }
                    HStack(spacing: 20) {
                        NavigationLink(value: BookUtilityRoute.history) {
                            Label("History", systemImage: "clock")
                        }
                        NavigationLink(value: BookUtilityRoute.map) {
                            Label("Your map", systemImage: "map")
                        }
                    }
                    .font(.subheadline).frame(minHeight: 44)
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(FieldColor.mutedInk)
                        TextField("Search your specimens", text: $searchText)
                            .accessibilityIdentifier("collection.search")
                            .focused($searchFocused)
                            .submitLabel(.search)
                            .onSubmit { searchFocused = false }
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .frame(width: 44, height: 44)
                            .accessibilityLabel("Clear search")
                        }
                    }
                    .padding(.horizontal, 14).frame(minHeight: 48)
                    .background(FieldBook.wash.opacity(0.6), in: .rect(cornerRadius: 12))
                    filterChips(appStore: appStore)
                    HStack {
                        BookSectionLabel(text: "Index · \(plants.count)")
                        Spacer()
                        Menu {
                            Button("Recent") { sortOrder = .recent }
                            Button("Name") { sortOrder = .name }
                            Button("Confidence") { sortOrder = .confidence }
                        } label: {
                            Label(sortOrder.label, systemImage: "arrow.up.arrow.down")
                                .font(.caption).foregroundStyle(FieldColor.mutedInk)
                        }.frame(minHeight: 44)
                    }
                    if plants.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("No matching specimens").font(FieldBook.heading)
                            Text("Try another name or show the full index.")
                                .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                            Button("Reset search & filters") {
                                searchText = ""
                                selectedType = nil
                                searchFocused = false
                            }.frame(minHeight: 44)
                        }.padding(.vertical, 20)
                    }
                    LazyVStack(spacing: 16) {
                        ForEach(plants) { plant in
                            NavigationLink(value: plant) { BookSpecimenRow(plant: plant) }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("collection.specimen.\(plant.scientificName)")
                            Divider()
                        }
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await appStore.refresh() }
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
                .padding(.horizontal, FieldSpace.md)
                .frame(minHeight: 44)
                .background(isSelected ? FieldBook.cover : FieldBook.wash.opacity(0.45))
                .cornerRadius(FieldRadius.chip)
                .overlay(
                    RoundedRectangle(cornerRadius: FieldRadius.chip)
                        .stroke(isSelected ? FieldBook.cover : FieldColor.separator, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: FieldRadius.chip))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

//#Preview {
//    NavigationStack {
//        LibraryView()
//            .environment(AppStore())
//    }
//}
