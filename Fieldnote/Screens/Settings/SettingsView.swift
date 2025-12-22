//
//  SettingsView.swift
//  Fieldnote
//
//  Settings screen with app information and options
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.appStore) var store

    var body: some View {
        List {
            // App Philosophy section
            Section {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Label {
                        Text("Offline-First")
                            .font(FieldType.bodyEmphasized)
                    } icon: {
                        Image(systemName: "icloud.slash.fill")
                            .foregroundColor(FieldColor.accent)
                    }

                    Text("Fieldnote stores all your observations locally on your device. Your field journal is yours, always accessible without an internet connection.")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, FieldSpace.xs)
            }

            // Data section
            Section("Data") {
                HStack {
                    Label("Total Plants", systemImage: "leaf.fill")
                    Spacer()
                    Text("\(store.plants.count)")
                        .foregroundColor(FieldColor.mutedInk)
                }

                HStack {
                    Label("Total Encounters", systemImage: "camera.fill")
                    Spacer()
                    Text("\(store.allEncounters.count)")
                        .foregroundColor(FieldColor.mutedInk)
                }

                Button {
                    // Export functionality - placeholder
                } label: {
                    HStack {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(FieldColor.mutedInk)
                    }
                }
                .disabled(true)
                .foregroundColor(FieldColor.mutedInk)
            }

            // About section
            Section("About") {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Text("Fieldnote")
                        .font(FieldType.title3)
                        .foregroundColor(FieldColor.ink)

                    Text("A field journal for mindful plant observation. Document your encounters with the botanical world, one observation at a time.")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: FieldSpace.xs) {
                        Text("Version")
                            .font(FieldType.caption)
                        Text("1.0.0")
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.mutedInk)
                    }
                    .padding(.top, FieldSpace.xs)
                }
                .padding(.vertical, FieldSpace.xs)
            }

            // Design section
            Section("Design Philosophy") {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Text("Confidence-Forward")
                        .font(FieldType.bodyEmphasized)
                        .foregroundColor(FieldColor.ink)

                    Text("We never over-claim certainty. Every identification includes a confidence level based on your observations. Low confidence plants are opportunities to learn, not failures.")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, FieldSpace.xs)
            }
        }
        .navigationTitle("Settings")
    }
}
