//
//  FieldnoteApp.swift
//  Fieldnote
//
//  Created by Tobias on 12/21/25.
//

import SwiftUI
import SwiftData

@main
struct FieldnoteApp: App {
    let sharedModelContainer: ModelContainer
    @State private var appStore: AppStore
    @State private var onboardingStore = OnboardingStore()
    @State private var subscriptionStore = SubscriptionStore()
    @State private var showPremiumPromo = false

    init() {
        let schema = Schema([Plant.self, Encounter.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            self.sharedModelContainer = container
            self._appStore = State(initialValue: AppStore(modelContext: container.mainContext))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingStore.shouldShowOnboarding {
                    OnboardingContainerView()
                } else {
                    MainTabView()
                }
            }
            .environment(\.appStore, appStore)
            .environment(\.onboardingStore, onboardingStore)
            .environment(\.subscriptionStore, subscriptionStore)
            .animation(.easeInOut(duration: 0.4), value: onboardingStore.shouldShowOnboarding)
            .preferredColorScheme(.light)
            .task {
                // Check subscription status on launch
                await subscriptionStore.checkAndUpdateStatus()

                // Start listening for StoreKit transaction updates
                await StoreKitService.shared.startTransactionListener { type, expirationDate in
                    await MainActor.run {
                        subscriptionStore.updateSubscription(type: type, expiresAt: expirationDate)
                    }
                }
            }
            .onChange(of: onboardingStore.hasCompletedOnboarding) { _, completed in
                // Show premium promo after onboarding completes (only once)
                if completed && subscriptionStore.shouldShowPremiumPromo {
                    // Small delay to let the transition complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showPremiumPromo = true
                    }
                }
            }
            .sheet(isPresented: $showPremiumPromo) {
                // Mark as seen when dismissed
                subscriptionStore.markPromoAsSeen()
            } content: {
                PremiumPromoSheet()
                    .environment(\.subscriptionStore, subscriptionStore)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
