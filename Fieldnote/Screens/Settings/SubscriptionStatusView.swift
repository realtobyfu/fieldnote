//
//  SubscriptionStatusView.swift
//  Fieldnote
//
//  Detailed subscription status and management view
//

import SwiftUI
import StoreKit

struct SubscriptionStatusView: View {
    @Environment(\.subscriptionStore) private var subscriptionStore

    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    
    private func suggestFeature() {
        let email = "3tobiasfu@gmail.com"
        let subject = "Fieldnote Feature Suggestion"
        let body = "I'd love to see this feature in Fieldnote:\n\n\n\n---\n"

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }


    var body: some View {
        List {
            // Status section
            Section {
                statusCard
            }
            .listRowBackground(FieldBook.paper)

            // Usage section (for free users)
            if !subscriptionStore.isPremium {
                Section {
                    usageCard
                        .listRowBackground(FieldBook.paper)
                } header: {
                    Text("Photo identification")
                }
            }

            // Actions section
            Section {
                if !subscriptionStore.isPremium {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Label("Upgrade to Premium", systemImage: "sparkles")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(FieldColor.mutedInk)
                        }
                    }
                }

                Button {
                    Task {
                        await restorePurchases()
                    }
                } label: {
                    HStack {
                        Label(isRestoring ? "Restoring..." : "Restore Purchases", systemImage: "arrow.clockwise")
                        Spacer()
                        if isRestoring {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isRestoring)
            }

            .listRowBackground(FieldBook.paper)

            // Manage subscription (for subscribers)
            if subscriptionStore.isPremium && subscriptionStore.subscriptionType == .annual {
                Section {
                    Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                        HStack {
                            Label("Manage Subscription", systemImage: "gear")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(FieldColor.mutedInk)
                        }
                    }
                } footer: {
                    Text("Opens in App Store to manage your subscription, including cancellation.")
                        .font(.caption2)
                }
                .listRowBackground(FieldBook.paper)
            }

            // Info section
            Section {

                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Text("About Premium")
                        .font(.headline)
                        .foregroundStyle(FieldColor.ink)

                    Text("Premium includes unlimited photo identification. The free plan includes \(SubscriptionStore.freeIdentificationLimit) photo identifications. Manual journal entries are always unlimited.")
                        .font(.subheadline)
                        .foregroundStyle(FieldColor.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, FieldSpace.xs)
                
                // Suggest Feature button
                Button {
                    suggestFeature()
                } label: {
                    HStack {
                        Label("Suggest a Feature", systemImage: "lightbulb")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(FieldColor.mutedInk)
                    }
                }
            }
            .listRowBackground(FieldBook.paper)
        }
        .scrollContentBackground(.hidden)
        .background(FieldBook.wash.ignoresSafeArea())
        .navigationTitle("Membership")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: FieldSpace.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionStore.isPremium ? "Premium" : "Free")
                        .font(FieldBook.heading)
                        .foregroundStyle(FieldColor.vintageInk)

                    statusSubtitle
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(subscriptionStore.isPremium ? FieldColor.accent.opacity(0.1) : FieldColor.separator)
                        .frame(width: 60, height: 60)

                    Image(systemName: subscriptionStore.isPremium ? "sparkles" : "book.closed")
                        .font(.system(size: 28))
                        .foregroundStyle(subscriptionStore.isPremium ? FieldColor.accent : FieldColor.mutedInk)
                }
            }
        }
        .padding(.vertical, FieldSpace.sm)
    }

    @ViewBuilder
    private var statusSubtitle: some View {
        if subscriptionStore.isPremium {
            switch subscriptionStore.subscriptionType {
            case .lifetime:
                Text("Lifetime access")
                    .font(.subheadline)
                    .foregroundStyle(FieldColor.fadedInk)
            case .annual:
                if let expiration = subscriptionStore.subscriptionExpirationDate {
                    Text("Access through \(expiration.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(FieldColor.fadedInk)
                } else {
                    Text("Annual subscription")
                        .font(.subheadline)
                        .foregroundStyle(FieldColor.fadedInk)
                }
            case .none:
                EmptyView()
            }
        } else {
            Text("Photo identification and unlimited manual entries")
                .font(.subheadline)
                .foregroundStyle(FieldColor.fadedInk)
        }
    }

    // MARK: - Usage Card

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(subscriptionStore.remainingFreeIdentifications) remaining")
                .font(FieldBook.heading)
                .foregroundStyle(FieldColor.ink)
            ProgressView(value: Double(subscriptionStore.aiIdentificationsUsed),
                         total: Double(SubscriptionStore.freeIdentificationLimit))
                .tint(FieldBook.cover)
                .accessibilityLabel("Photo identification allowance used")
                .accessibilityValue("\(subscriptionStore.aiIdentificationsUsed) of \(SubscriptionStore.freeIdentificationLimit)")
            Text("\(subscriptionStore.aiIdentificationsUsed) of \(SubscriptionStore.freeIdentificationLimit) used")
                .font(.caption).foregroundStyle(FieldColor.mutedInk)
            if subscriptionStore.remainingFreeIdentifications == 0 {
                Text("Upgrade for more photo identifications, or keep adding entries by hand.")
                    .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, FieldSpace.sm)
    }

    // MARK: - Actions

    private func restorePurchases() async {
        isRestoring = true
        do {
            try await StoreKitService.shared.restorePurchases()
            let type = await StoreKitService.shared.checkCurrentEntitlements()
            if type != .none {
                let expirationDate = await StoreKitService.shared.getSubscriptionExpirationDate()
                subscriptionStore.updateSubscription(type: type, expiresAt: expirationDate)
            } else {
                errorMessage = "No previous purchases found"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isRestoring = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionStatusView()
    }
}
