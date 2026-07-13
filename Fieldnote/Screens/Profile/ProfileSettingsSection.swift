//
//  ProfileSettingsSection.swift
//  Fieldnote
//
//  Settings, folded into the Profile tab as paper cards that flow below the
//  badge grid — so settings feel like a continuation of Profile scrolling
//  downward rather than a jump to a stock system List. Deeper destinations
//  (membership, plant catalog, all encounters) still push as their own pages.
//

import SwiftUI

struct ProfileSettingsSection: View {
    @Environment(\.appStore) private var store
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.subscriptionStore) private var subscriptionStore
    @Environment(\.syncStore) private var syncStore

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.lg) {
            storageSection
            if let store { dataSection(store) }
            dataSourcesSection
            aboutSection
            #if DEBUG
            developerSection
            #endif
        }
    }

    // MARK: - Storage

    private var storageSection: some View {
        SettingsGroup(title: "Storage") {
            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                if syncStore.iCloudAvailable {
                    SettingsStatusHeader(
                        icon: "icloud.fill",
                        title: "Synced with iCloud"
                    )
                    Text("Your field journal lives on your device first, then syncs quietly to iCloud across your devices.")
                        .settingsBodyText()
                    HStack(spacing: FieldSpace.xs) {
                        if syncStore.isPhotosSyncing {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: "photo.fill")
                                .font(.caption)
                                .foregroundStyle(FieldColor.tertiaryInk)
                        }
                        Text(syncStore.photoSyncStatusText)
                            .font(FieldType.caption)
                            .foregroundStyle(FieldColor.tertiaryInk)
                    }
                    .padding(.top, 2)
                } else {
                    SettingsStatusHeader(
                        icon: "icloud.slash.fill",
                        title: "Offline-First"
                    )
                    Text("Fieldnote stores every observation locally on your device — your field journal is yours, always accessible without a connection.")
                        .settingsBodyText()
                    Text("Sign in to iCloud to sync across devices.")
                        .font(FieldType.caption)
                        .foregroundStyle(FieldColor.tertiaryInk)
                }
            }
            .padding(FieldSpace.md)
        }
    }

    // MARK: - Data

    private func dataSection(_ store: AppStore) -> some View {
        SettingsGroup(title: "Your Data") {
            VStack(spacing: 0) {
                NavigationLink {
                    PlantManagementView()
                } label: {
                    SettingsRow(icon: "leaf.fill", title: "Plant catalog") {
                        Text("\(store.plants.count)")
                            .font(FieldType.footnote)
                            .foregroundStyle(FieldColor.mutedInk)
                        SettingsChevron()
                    }
                }
                .buttonStyle(.plain)

                SettingsDivider()

                NavigationLink {
                    AllEncountersView()
                } label: {
                    SettingsRow(icon: "camera.fill", title: "All encounters") {
                        Text("\(store.allEncounters.count)")
                            .font(FieldType.footnote)
                            .foregroundStyle(FieldColor.mutedInk)
                        SettingsChevron()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Data Sources & Attribution

    /// Credits the open datasets behind local discovery. Regional occurrence and
    /// seasonality come from iNaturalist research-grade observations with names
    /// normalized via GBIF; visual identification is powered by Pl@ntNet.
    private var dataSourcesSection: some View {
        SettingsGroup(title: "Data Sources") {
            VStack(alignment: .leading, spacing: FieldSpace.xs) {
                Text("Where discovery data comes from")
                    .font(FieldType.bodyEmphasized)
                    .foregroundStyle(FieldColor.ink)
                Text("Which plants are common near you, and when they're active, is drawn from iNaturalist research-grade observations, with scientific names normalized through GBIF.")
                    .settingsBodyText()
                Text("Photo identification is powered by Pl@ntNet.")
                    .settingsBodyText()
                    .padding(.top, 2)
            }
            .padding(FieldSpace.md)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        SettingsGroup(title: "About") {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: FieldSpace.xs) {
                    Text("Fieldnote")
                        .font(FieldType.title3)
                        .foregroundStyle(FieldColor.ink)
                    Text("A field journal for mindful plant observation — document your encounters with the botanical world, one observation at a time.")
                        .settingsBodyText()
                    Text("We never over-claim certainty. Every identification carries a confidence level: low-confidence finds are invitations to learn, not failures.")
                        .settingsBodyText()
                        .padding(.top, 2)
                }
                .padding(FieldSpace.md)

                SettingsDivider()

                Button(action: sendFeedback) {
                    SettingsRow(icon: "envelope.fill", title: "Send feedback") {
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FieldColor.tertiaryInk)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sendFeedback() {
        let subject = "Fieldnote Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = "\n\n---\nFieldnote v1.0.0".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:3tobiasfu@gmail.com?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Developer

    #if DEBUG
    private var developerSection: some View {
        SettingsGroup(title: "Developer") {
            VStack(spacing: 0) {
                Button { onboardingStore.resetOnboarding() } label: {
                    SettingsRow(icon: "arrow.counterclockwise", title: "Reset onboarding", tint: FieldColor.errorRed)
                }
                .buttonStyle(.plain)

                SettingsDivider()

                Button { subscriptionStore.resetForTesting() } label: {
                    SettingsRow(icon: "creditcard", title: "Reset subscription", tint: FieldColor.errorRed)
                }
                .buttonStyle(.plain)
            }
        }
    }
    #endif
}

// MARK: - Membership (always visible on Profile)

/// Membership status card. Lives on Profile permanently (not inside the collapsed
/// settings) since it's the one at-a-glance item not already surfaced by the stat
/// tiles, and the upgrade prompt wants to stay visible.
struct ProfileMembershipCard: View {
    @Environment(\.subscriptionStore) private var subscriptionStore

    var body: some View {
        SettingsGroup(title: "Membership") {
            NavigationLink {
                SubscriptionStatusView()
            } label: {
                SettingsRow(
                    icon: subscriptionStore.isPremium ? "checkmark.seal.fill" : "sparkles",
                    title: subscriptionStore.isPremium ? "Premium" : "Free plan",
                    subtitle: subtitle
                ) {
                    if subscriptionStore.isPremium {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(FieldColor.accent)
                    } else {
                        Text("Upgrade")
                            .font(FieldType.footnote.weight(.semibold))
                            .foregroundStyle(FieldColor.accentDeep)
                    }
                    SettingsChevron()
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var subtitle: String {
        if subscriptionStore.isPremium {
            return subscriptionStore.subscriptionType == .lifetime ? "Lifetime access" : "Annual subscription"
        }
        return "\(subscriptionStore.remainingFreeIdentifications) AI IDs remaining"
    }
}

// MARK: - Building blocks

/// A labeled settings group: a small uppercase serif header over a paper card.
private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.sm) {
            Text(title.uppercased())
                .font(FieldType.sectionHeader)
                .tracking(1.4)
                .foregroundStyle(FieldColor.mutedInk)
                .padding(.leading, 4)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FieldColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .fieldShadow(FieldShadow.card)
        }
    }
}

/// A tappable settings row: tinted leading glyph, serif title/subtitle, trailing accessory.
private struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var tint: Color = FieldColor.accentDeep
    @ViewBuilder var trailing: Trailing

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        tint: Color = FieldColor.accentDeep,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: FieldSpace.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(FieldType.body)
                    .foregroundStyle(FieldColor.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(FieldType.caption)
                        .foregroundStyle(FieldColor.mutedInk)
                }
            }
            Spacer(minLength: FieldSpace.sm)
            trailing
        }
        .padding(.horizontal, FieldSpace.md)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

/// Status header (icon + title) for non-navigating info cards like Storage.
private struct SettingsStatusHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: FieldSpace.sm) {
            Image(systemName: icon)
                .foregroundStyle(FieldColor.accent)
            Text(title)
                .font(FieldType.bodyEmphasized)
                .foregroundStyle(FieldColor.ink)
        }
    }
}

private struct SettingsChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(FieldColor.tertiaryInk)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(FieldColor.separator)
            .frame(height: 1)
            .padding(.leading, FieldSpace.md + 34 + FieldSpace.md)
    }
}

private extension View {
    func settingsBodyText() -> some View {
        font(FieldType.callout)
            .foregroundStyle(FieldColor.mutedInk)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
