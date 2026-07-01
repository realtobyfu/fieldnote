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
        let body = "I'd love to see this feature in Fieldnote:\n\n\n\n---\nFieldnote v1.0.0 (Premium)"

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

            // Usage section (for free users)
            if !subscriptionStore.isPremium {
                Section {
                    usageCard
                } header: {
                    Text("AI Identification Usage")
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
                                .foregroundColor(FieldColor.mutedInk)
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

            // Manage subscription (for subscribers)
            if subscriptionStore.isPremium && subscriptionStore.subscriptionType == .annual {
                Section {
                    Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                        HStack {
                            Label("Manage Subscription", systemImage: "gear")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(FieldColor.mutedInk)
                        }
                    }
                } footer: {
                    Text("Opens in App Store to manage your subscription, including cancellation.")
                        .font(FieldType.caption2)
                }
            }

            // Info section
            Section {

                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Text("About Premium")
                        .font(FieldType.bodyEmphasized)
                        .foregroundColor(FieldColor.ink)

                    Text("Premium unlocks unlimited AI-powered plant identification. Free users can manually add plants without limits - only AI identification is restricted to \(SubscriptionStore.freeIdentificationLimit) uses.")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, FieldSpace.xs)
                
                // Suggest Feature button (Premium only)
                if subscriptionStore.isPremium {
                    Button {
                        suggestFeature()
                    } label: {
                        HStack {
                            Label("Suggest a Feature", systemImage: "lightbulb")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(FieldColor.mutedInk)
                        }
                    }
                }

            }
        }
        .fieldListBackground()
        .navigationTitle("Subscription")
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
                        .font(FieldType.title2)
                        .foregroundColor(FieldColor.vintageInk)

                    statusSubtitle
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(subscriptionStore.isPremium ? FieldColor.accent.opacity(0.1) : FieldColor.separator)
                        .frame(width: 60, height: 60)

                    Image(systemName: subscriptionStore.isPremium ? "leaf.fill" : "leaf")
                        .font(.system(size: 28))
                        .foregroundColor(subscriptionStore.isPremium ? FieldColor.accent : FieldColor.mutedInk)
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
                Text("Lifetime access - thank you!")
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
            case .annual:
                if let expiration = subscriptionStore.subscriptionExpirationDate {
                    Text("Renews \(expiration.formatted(date: .abbreviated, time: .omitted))")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.fadedInk)
                } else {
                    Text("Annual subscription")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.fadedInk)
                }
            case .none:
                EmptyView()
            }
        } else {
            Text("Limited AI identification")
                .font(FieldType.callout)
                .foregroundColor(FieldColor.fadedInk)
        }
    }

    // MARK: - Usage Card

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: FieldSpace.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(subscriptionStore.aiIdentificationsUsed) of \(SubscriptionStore.freeIdentificationLimit)")
                        .font(FieldType.title2)
                        .foregroundColor(FieldColor.vintageInk)

                    Text("AI identifications used")
                        .font(FieldType.callout)
                        .foregroundColor(FieldColor.fadedInk)
                }

                Spacer()

                // Progress circle
                ZStack {
                    Circle()
                        .stroke(FieldColor.separator, lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: CGFloat(subscriptionStore.aiIdentificationsUsed) / CGFloat(SubscriptionStore.freeIdentificationLimit))
                        .stroke(
                            subscriptionStore.remainingFreeIdentifications > 0 ? FieldColor.accent : FieldColor.errorRed,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(subscriptionStore.remainingFreeIdentifications)")
                        .font(FieldType.title3)
                        .foregroundColor(subscriptionStore.remainingFreeIdentifications > 0 ? FieldColor.accent : FieldColor.errorRed)
                }
                .frame(width: 60, height: 60)
            }

            if subscriptionStore.remainingFreeIdentifications == 0 {
                HStack(spacing: FieldSpace.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(FieldColor.warningOrange)
                    Text("Upgrade to continue using AI identification")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                }
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
