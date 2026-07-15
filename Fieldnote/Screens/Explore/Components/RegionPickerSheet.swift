//
//  RegionPickerSheet.swift
//  Fieldnote
//
//  One place to detect or manually choose the persistent Explore region.
//  Selecting a region changes Explore ranking only; it never changes an
//  observation's stored location.
//

import SwiftUI

struct RegionPickerSheet: View {
    let selectedRegion: ExploreRegion?
    let detectionState: RegionDetectionState
    let onDetect: () async -> Void
    let onOpenSettings: () -> Void
    let onSelect: (ExploreRegion) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var detectionTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: detectRegion) {
                        HStack(spacing: FieldSpace.sm) {
                            Image(systemName: "location.fill")
                                .font(.body)
                                .foregroundStyle(FieldColor.accent)
                                .frame(width: 28, height: 28)
                                .background(FieldColor.accent.opacity(0.12), in: Circle())
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Detect My Region")
                                    .foregroundStyle(FieldColor.ink)
                                Text(detectionSubtitle)
                                    .font(.caption)
                                    .foregroundStyle(FieldColor.fadedInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: FieldSpace.sm)

                            if detectionState == .detecting {
                                ProgressView()
                                    .controlSize(.small)
                                    .accessibilityLabel("Detecting region")
                            }
                        }
                        .frame(minHeight: 44)
                    }
                    .disabled(!canDetect)

                    if let message = detectionMessage {
                        Label(message, systemImage: detectionMessageIcon)
                            .font(.caption)
                            .foregroundStyle(detectionMessageColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if showsSettingsAction {
                        Button("Open Location Settings", action: onOpenSettings)
                            .foregroundStyle(FieldColor.accent)
                            .frame(minHeight: 44, alignment: .leading)
                    }
                } footer: {
                    Text("Uses your location once to choose a broad region. Your precise location isn’t shared with Fieldnote’s catalog service.")
                }

                Section("Choose manually") {
                    ForEach(CatalogRegion.presets) { region in
                        Button {
                            onSelect(.region(region))
                            dismiss()
                        } label: {
                            HStack(spacing: FieldSpace.sm) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(region.name)
                                        .foregroundStyle(FieldColor.ink)
                                    if let subtitle = region.subtitle {
                                        Text(subtitle)
                                            .font(.caption2)
                                            .foregroundStyle(FieldColor.fadedInk)
                                    }
                                }

                                Spacer()

                                if isSelected(region) {
                                    Image(systemName: "checkmark")
                                        .font(.callout.bold())
                                        .foregroundStyle(FieldColor.accent)
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(minHeight: 44)
                            .contentShape(.rect)
                        }
                        .accessibilityValue(isSelected(region) ? "Selected" : "")
                    }
                }
            }
            .navigationTitle("Choose Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: detectionState) { _, state in
                if case .detected = state {
                    dismiss()
                }
            }
            .onDisappear {
                if detectionState == .detecting {
                    detectionTask?.cancel()
                }
            }
        }
    }

    private var canDetect: Bool {
        switch detectionState {
        case .idle, .unavailable:
            true
        case .detecting, .detected, .permissionDenied, .servicesDisabled, .unsupported:
            false
        }
    }

    private var detectionSubtitle: String {
        switch detectionState {
        case .detecting:
            "Finding a supported region…"
        case .detected(let region):
            "Detected \(region.name)"
        default:
            "Use your location to choose automatically"
        }
    }

    private var detectionMessage: String? {
        switch detectionState {
        case .permissionDenied:
            "Location access is off. You can enable it in Settings or choose below."
        case .servicesDisabled:
            "Location Services are off. Turn them on in Settings or choose below."
        case .unavailable:
            "We couldn’t detect your region. Try again or choose below."
        case .unsupported:
            "Your area isn’t in a supported region yet. Choose a region below."
        case .idle, .detecting, .detected:
            nil
        }
    }

    private var detectionMessageIcon: String {
        switch detectionState {
        case .unsupported:
            "mappin.slash"
        default:
            "exclamationmark.circle"
        }
    }

    private var detectionMessageColor: Color {
        switch detectionState {
        case .permissionDenied, .servicesDisabled, .unavailable:
            FieldColor.errorRed
        default:
            FieldColor.fadedInk
        }
    }

    private var showsSettingsAction: Bool {
        detectionState == .permissionDenied || detectionState == .servicesDisabled
    }

    private func isSelected(_ region: CatalogRegion) -> Bool {
        selectedRegion == .region(region)
    }

    private func detectRegion() {
        detectionTask?.cancel()
        detectionTask = Task {
            await onDetect()
        }
    }
}

#if DEBUG
#Preview("Region picker · Ready") {
    RegionPickerSheet(
        selectedRegion: nil,
        detectionState: .idle,
        onDetect: {},
        onOpenSettings: {},
        onSelect: { _ in }
    )
}

#Preview("Region picker · Detecting") {
    RegionPickerSheet(
        selectedRegion: nil,
        detectionState: .detecting,
        onDetect: {},
        onOpenSettings: {},
        onSelect: { _ in }
    )
}

#Preview("Region picker · Selected") {
    RegionPickerSheet(
        selectedRegion: .region(CatalogRegion.presets[0]),
        detectionState: .idle,
        onDetect: {},
        onOpenSettings: {},
        onSelect: { _ in }
    )
}

#Preview("Region picker · Location off") {
    RegionPickerSheet(
        selectedRegion: nil,
        detectionState: .permissionDenied,
        onDetect: {},
        onOpenSettings: {},
        onSelect: { _ in }
    )
}

#Preview("Region picker · Unsupported") {
    RegionPickerSheet(
        selectedRegion: nil,
        detectionState: .unsupported(placeName: nil),
        onDetect: {},
        onOpenSettings: {},
        onSelect: { _ in }
    )
}

#Preview("Region picker · Accessibility text") {
    RegionPickerSheet(
        selectedRegion: nil,
        detectionState: .unavailable,
        onDetect: {},
        onOpenSettings: {},
        onSelect: { _ in }
    )
    .dynamicTypeSize(.accessibility3)
}
#endif
