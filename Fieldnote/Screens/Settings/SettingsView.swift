//
//  SettingsView.swift
//  Fieldnote
//
//  Settings screen with app information and options
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.appStore) private var store
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.subscriptionStore) private var subscriptionStore
    @Environment(\.syncStore) private var syncStore

    @State private var showPaywall = false

    private func sendFeedback() {
        let email = "3tobiasfu@gmail.com"
        let subject = "Fieldnote Feedback"
        let body = "\n\n---\nFieldnote v1.0.0"

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }


    var body: some View {
        Group {
            if let appStore = store {
                settingsContent(appStore: appStore)
            } else {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Please restart the app.")
                )
            }
        }
        .navigationTitle("Settings")
    }

    @ViewBuilder
    private func settingsContent(appStore: AppStore) -> some View {
        List {
            // Storage section (status display only - sync is automatic)
            Section {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    if syncStore.iCloudAvailable {
                        Label {
                            Text("Synced with iCloud")
                                .font(FieldType.bodyEmphasized)
                        } icon: {
                            Image(systemName: "icloud.fill")
                                .foregroundColor(FieldColor.accent)
                        }

                        Text("Your field journal lives on your device first, then syncs quietly to iCloud.")
                            .font(FieldType.callout)
                            .foregroundColor(FieldColor.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
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

                        Text("Sign in to iCloud to sync across devices.")
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.fadedInk)
                    }
                }
                .padding(.vertical, FieldSpace.xs)
            } header: {
                Text("Storage")
            } footer: {
                if syncStore.iCloudAvailable {
                    Text("Plant data syncs to iCloud. Photos remain stored locally.")
                }
            }
            
            // Subscription section
            Section {
                NavigationLink {
                    SubscriptionStatusView()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(subscriptionStore.isPremium ? "Premium" : "Free")
                                .font(FieldType.bodyEmphasized)
                                .foregroundColor(FieldColor.ink)

                            if !subscriptionStore.isPremium {
                                Text("\(subscriptionStore.remainingFreeIdentifications) AI IDs remaining")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                            } else {
                                Text(subscriptionStore.subscriptionType == .lifetime ? "Lifetime access" : "Annual subscription")
                                    .font(FieldType.caption)
                                    .foregroundColor(FieldColor.fadedInk)
                            }
                        }

                        Spacer()

                        if subscriptionStore.isPremium {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(FieldColor.accent)
                        } else {
                            Text("Upgrade")
                                .font(FieldType.caption)
                                .foregroundColor(FieldColor.accent)
                        }
                    }
                }
            } header: {
                Text("Subscription")
            }

            // Data section
            Section("Data") {
                NavigationLink {
                    PlantManagementView()
                } label: {
                    HStack {
                        Label("Total Plants", systemImage: "leaf.fill")
                        Spacer()
                        Text("\(appStore.plants.count)")
                            .foregroundColor(FieldColor.mutedInk)
                    }
                }

                NavigationLink {
                    AllEncountersView()
                } label: {
                    HStack {
                        Label("Total Encounters", systemImage: "camera.fill")
                        Spacer()
                        Text("\(appStore.allEncounters.count)")
                            .foregroundColor(FieldColor.mutedInk)
                    }
                }
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

                // Feedback button
                Button {
                    sendFeedback()
                } label: {
                    HStack {
                        Label("Send Feedback", systemImage: "envelope")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(FieldColor.mutedInk)
                    }
                }

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

            #if DEBUG
            Section("Developer") {
                Button("Reset Onboarding") {
                    onboardingStore.resetOnboarding()
                }
                .foregroundColor(FieldColor.errorRed)

                Button("Reset Subscription (Testing)") {
                    subscriptionStore.resetForTesting()
                }
                .foregroundColor(FieldColor.errorRed)
            }
            #endif
        }
    }
}
