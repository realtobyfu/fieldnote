//
//  PremiumPromoSheet.swift
//  Fieldnote
//
//  Premium promo sheet shown after onboarding - introduces premium with both options
//

import SwiftUI
import StoreKit

struct PremiumPromoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.subscriptionStore) private var subscriptionStore

    @State private var products: [Product] = []
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Animation states
    @State private var headerVisible = false
    @State private var titleVisible = false
    @State private var benefitsVisible = false
    @State private var pricingVisible = false
    @State private var buttonsVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                FieldColor.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: FieldSpace.lg) {
                        // Header icon
                        headerIcon
                            .padding(.top, FieldSpace.lg)
                            .scaleEffect(headerVisible ? 1 : 0.8)
                            .opacity(headerVisible ? 1 : 0)

                        // Title and description
                        titleSection
                            .offset(y: titleVisible ? 0 : 15)
                            .opacity(titleVisible ? 1 : 0)

                        // Benefits card
                        benefitsCard
                            .offset(y: benefitsVisible ? 0 : 20)
                            .opacity(benefitsVisible ? 1 : 0)

                        // Pricing options
                        pricingSection
                            .offset(y: pricingVisible ? 0 : 20)
                            .opacity(pricingVisible ? 1 : 0)

                        // CTA buttons
                        actionButtons
                            .offset(y: buttonsVisible ? 0 : 15)
                            .opacity(buttonsVisible ? 1 : 0)

                        Spacer(minLength: FieldSpace.xl)
                    }
                    .padding(.horizontal, FieldSpace.md)
                }
            }
            .onAppear {
                // Staggered entrance animations
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    headerVisible = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                    titleVisible = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                    benefitsVisible = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                    pricingVisible = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
                    buttonsVisible = true
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FieldColor.mutedInk)
                    }
                }
            }
            .task {
                await loadProducts()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Header Icon

    private var headerIcon: some View {
        ZStack {
            // Vintage frame background - larger
            RoundedRectangle(cornerRadius: FieldRadius.lg)
                .fill(FieldColor.illustrationBg)
                .frame(width: 140, height: 140)

            // Decorative outer border
            RoundedRectangle(cornerRadius: FieldRadius.lg)
                .stroke(FieldColor.bookBorder, lineWidth: 2)
                .frame(width: 140, height: 140)

            // Inner decorative border
            RoundedRectangle(cornerRadius: FieldRadius.md)
                .stroke(FieldColor.bookBorder.opacity(0.3), lineWidth: 1)
                .frame(width: 126, height: 126)

            // Combined icon - larger
            ZStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(FieldColor.accent)

                Image(systemName: "sparkles")
                    .font(.system(size: 22))
                    .foregroundColor(FieldColor.accent)
                    .offset(x: 30, y: -26)
            }
        }
        .fieldShadow(FieldShadow.card)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: FieldSpace.sm) {
            Text("Discover More with")
                .font(FieldType.body)
                .foregroundColor(FieldColor.fadedInk)

            Text("Premium")
                .font(FieldType.displayTitle)
                .foregroundColor(FieldColor.vintageInk)

            OrnamentalDivider(symbol: "sparkles")
                .padding(.top, FieldSpace.xs)
        }
    }

    // MARK: - Benefits Card

    private var benefitsCard: some View {
        VintageCard {
            VStack(alignment: .leading, spacing: FieldSpace.md) {
                BenefitRow(
                    icon: "infinity",
                    text: "Unlimited AI identifications"
                )

                BenefitRow(
                    icon: "camera.viewfinder",
                    text: "Identify any plant instantly"
                )

                BenefitRow(
                    icon: "heart.fill",
                    text: "Support independent development"
                )
            }
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: FieldSpace.md) {
            if isLoading {
                ProgressView()
                    .frame(height: 150)
            } else if products.isEmpty {
                Text("Unable to load products")
                    .font(FieldType.callout)
                    .foregroundColor(FieldColor.fadedInk)
                    .frame(height: 150)
            } else {
                ForEach(products, id: \.id) { product in
                    PromoPricingCard(
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
                isPurchasing ? "Processing..." : purchaseButtonTitle,
                isEnabled: selectedProduct != nil && !isPurchasing
            ) {
                Task {
                    await purchaseSelected()
                }
            }

            Button {
                dismiss()
            } label: {
                VStack(spacing: 2) {
                    Text("Continue with 5 Free IDs")
                        .font(FieldType.buttonLabel)
                        .foregroundColor(FieldColor.mutedInk)

                    Text("No credit card required")
                        .font(FieldType.caption2)
                        .foregroundColor(FieldColor.fadedInk)
                }
            }
        }
        .padding(.top, FieldSpace.md)
    }

    private var purchaseButtonTitle: String {
        guard let product = selectedProduct else {
            return "Select a Plan"
        }
        if product.id == StoreKitService.annualProductID {
            return "Start 7-Day Free Trial"
        } else {
            return "Purchase Lifetime"
        }
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
            if let _ = try await StoreKitService.shared.purchase(product) {
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
}

// MARK: - Promo Pricing Card

private struct PromoPricingCard: View {
    let product: Product
    let isSelected: Bool
    let isAnnual: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: FieldSpace.xs) {
                        Text(isAnnual ? "Annual" : "Lifetime")
                            .font(FieldType.bodyEmphasized)
                            .foregroundColor(FieldColor.vintageInk)

                        if isAnnual {
                            Text("7-day free trial")
                                .font(FieldType.caption2)
                                .foregroundColor(FieldColor.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(FieldColor.accent.opacity(0.1))
                                .cornerRadius(FieldRadius.sm)
                        }
                    }

                    Text(isAnnual ? "Then \(product.displayPrice)/year" : "One-time purchase")
                        .font(FieldType.caption)
                        .foregroundColor(FieldColor.fadedInk)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(FieldType.title3)
                    .foregroundColor(FieldColor.vintageInk)
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

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: FieldSpace.md) {
            ZStack {
                Circle()
                    .fill(FieldColor.accent.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(FieldColor.accent)
            }

            Text(text)
                .font(FieldType.body)
                .foregroundColor(FieldColor.vintageInk)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    PremiumPromoSheet()
}
