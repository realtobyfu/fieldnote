//
//  PaywallView.swift
//  Fieldnote
//
//  Premium upgrade paywall modal with vintage botanical design
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.subscriptionStore) private var subscriptionStore

    @State private var products: [Product] = []
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var isLoading = true

    // Animation states
    @State private var headerVisible = false
    @State private var usageVisible = false
    @State private var pricingVisible = false
    @State private var buttonsVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                FieldColor.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: FieldSpace.lg) {
                        // Header with botanical icon
                        headerSection
                            .scaleEffect(headerVisible ? 1 : 0.85)
                            .opacity(headerVisible ? 1 : 0)

                        // Usage indicator
                        usageIndicator
                            .offset(y: usageVisible ? 0 : 20)
                            .opacity(usageVisible ? 1 : 0)

                        // Pricing cards
                        pricingSection
                            .offset(y: pricingVisible ? 0 : 20)
                            .opacity(pricingVisible ? 1 : 0)

                        // CTA buttons
                        actionButtons
                            .offset(y: buttonsVisible ? 0 : 15)
                            .opacity(buttonsVisible ? 1 : 0)

                        // Restore purchases
                        restoreButton
                            .opacity(buttonsVisible ? 1 : 0)

                        // Legal text
                        legalText
                            .opacity(buttonsVisible ? 1 : 0)
                    }
                    .padding(FieldSpace.md)
                }
            }
            .onAppear {
                // Staggered entrance animations
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    headerVisible = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                    usageVisible = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                    pricingVisible = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                    buttonsVisible = true
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(FieldColor.accent)
                }
            }
            .task {
                await loadProducts()
            }
            .alert("Purchase Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: FieldSpace.md) {
            // Botanical icon with decorative frame
            ZStack {
                // Vintage frame background
                RoundedRectangle(cornerRadius: FieldRadius.lg)
                    .fill(FieldColor.illustrationBg)
                    .frame(width: 100, height: 100)

                // Decorative outer border
                RoundedRectangle(cornerRadius: FieldRadius.lg)
                    .stroke(FieldColor.bookBorder, lineWidth: 2)
                    .frame(width: 100, height: 100)

                // Inner decorative border
                RoundedRectangle(cornerRadius: FieldRadius.md)
                    .stroke(FieldColor.bookBorder.opacity(0.3), lineWidth: 1)
                    .frame(width: 88, height: 88)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 42))
                    .foregroundColor(FieldColor.accent)
            }
            .fieldShadow(FieldShadow.card)

            VStack(spacing: FieldSpace.xs) {
                Text("Unlock Unlimited Discovery")
                    .font(FieldType.displaySubtitle)
                    .foregroundColor(FieldColor.vintageInk)
                    .multilineTextAlignment(.center)

                Text("Identify any plant, anytime")
                    .font(FieldType.body)
                    .foregroundColor(FieldColor.fadedInk)
            }

            OrnamentalDivider(symbol: "sparkles")
        }
        .padding(.top, FieldSpace.md)
    }

    // MARK: - Usage Indicator

    private var usageIndicator: some View {
        VintageCard {
            HStack {
                VStack(alignment: .leading, spacing: FieldSpace.xs) {
                    Text("Free Identifications Used")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)

                    Text("\(subscriptionStore.aiIdentificationsUsed) of \(SubscriptionStore.freeIdentificationLimit)")
                        .font(FieldType.title2)
                        .foregroundColor(FieldColor.vintageInk)
                }

                Spacer()

                // Progress circle
                ZStack {
                    Circle()
                        .stroke(FieldColor.separator, lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: CGFloat(subscriptionStore.aiIdentificationsUsed) / CGFloat(SubscriptionStore.freeIdentificationLimit))
                        .stroke(FieldColor.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 50, height: 50)
            }
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: FieldSpace.md) {
            if isLoading {
                ProgressView()
                    .frame(height: 200)
            } else if products.isEmpty {
                Text("Unable to load products. Please try again.")
                    .font(FieldType.body)
                    .foregroundColor(FieldColor.fadedInk)
                    .frame(height: 200)
            } else {
                ForEach(products, id: \.id) { product in
                    PricingCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isAnnual: product.id == StoreKitService.annualProductID
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: FieldSpace.md) {
            PrimaryButton(
                isPurchasing ? "Processing..." : "Subscribe Now",
                isEnabled: selectedProduct != nil && !isPurchasing
            ) {
                Task {
                    await purchaseSelected()
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(FieldType.buttonLabel)
                    .foregroundColor(FieldColor.mutedInk)
            }
        }
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(FieldType.caption)
                .foregroundColor(FieldColor.accent)
                .underline()
        }
        .padding(.top, FieldSpace.sm)
    }

    // MARK: - Legal Text

    private var legalText: some View {
        VStack(spacing: FieldSpace.xs) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                .font(FieldType.caption2)
                .foregroundColor(FieldColor.mutedInk)
                .multilineTextAlignment(.center)

            HStack(spacing: FieldSpace.md) {
                Link("Terms of Use", destination: URL(string: "https://apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("Privacy Policy", destination: URL(string: "https://realtobyfu.github.io/fieldnote-support/privacy.html")!)
            }
            .font(FieldType.caption2)
            .foregroundColor(FieldColor.accent)
        }
        .padding(.top, FieldSpace.md)
        .padding(.bottom, FieldSpace.xl)
    }

    // MARK: - Actions

    private func loadProducts() async {
        isLoading = true
        do {
            products = try await StoreKitService.shared.fetchProducts()
            // Select annual by default
            selectedProduct = products.first { $0.id == StoreKitService.annualProductID }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }

    private func purchaseSelected() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        do {
            if let transaction = try await StoreKitService.shared.purchase(product) {
                // Purchase successful
                let type: SubscriptionType = product.id == StoreKitService.lifetimeProductID ? .lifetime : .annual
                let expirationDate = await StoreKitService.shared.getSubscriptionExpirationDate()
                subscriptionStore.updateSubscription(type: type, expiresAt: expirationDate)
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }

    private func restorePurchases() async {
        isPurchasing = true
        do {
            try await StoreKitService.shared.restorePurchases()
            let type = await StoreKitService.shared.checkCurrentEntitlements()
            if type != .none {
                let expirationDate = await StoreKitService.shared.getSubscriptionExpirationDate()
                subscriptionStore.updateSubscription(type: type, expiresAt: expirationDate)
                dismiss()
            } else {
                errorMessage = "No previous purchases found"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let isAnnual: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: FieldSpace.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: FieldSpace.xs) {
                            Text(isAnnual ? "Annual" : "Lifetime")
                                .font(FieldType.title3)
                                .foregroundColor(FieldColor.vintageInk)

                            if isAnnual {
                                Text("Best Value")
                                    .font(FieldType.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, FieldSpace.xs)
                                    .padding(.vertical, 2)
                                    .background(FieldColor.accent)
                                    .cornerRadius(FieldRadius.sm)
                            }
                        }

                        Text(isAnnual ? "7-day free trial" : "One-time purchase")
                            .font(FieldType.caption)
                            .foregroundColor(FieldColor.fadedInk)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(FieldType.title2)
                            .foregroundColor(FieldColor.vintageInk)

                        if isAnnual {
                            Text("per year")
                                .font(FieldType.caption)
                                .foregroundColor(FieldColor.fadedInk)
                        }
                    }
                }

                // Features
                VStack(alignment: .leading, spacing: FieldSpace.xs) {
                    FeatureRow(text: "Unlimited AI identifications")
                    FeatureRow(text: "Identify any plant instantly")
                    if !isAnnual {
                        FeatureRow(text: "Never pay again")
                    }
                }
            }
            .padding(FieldSpace.cardPadding)
            .background(FieldColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.card)
                    .stroke(isSelected ? FieldColor.accent : FieldColor.bookBorder.opacity(0.4), lineWidth: isSelected ? 2 : 0.5)
            )
            .cornerRadius(FieldRadius.card)
            .fieldShadow(FieldShadow.card)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: FieldSpace.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(FieldColor.accent)

            Text(text)
                .font(FieldType.callout)
                .foregroundColor(FieldColor.fadedInk)
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
