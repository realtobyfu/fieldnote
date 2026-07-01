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
    @State private var syncStore = SyncStore()
    @State private var gamificationService: GamificationService
    @State private var showPremiumPromo = false

    init() {
        let schema = Schema([Plant.self, Encounter.self, FieldProfile.self, Achievement.self])

        // Try CloudKit first, fall back to local if unavailable
        var container: ModelContainer?

        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            container = try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            print("CloudKit unavailable, using local storage: \(error)")
        }

        // Fall back to local-only if CloudKit failed
        if container == nil {
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            do {
                container = try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }

        // Restyle navigation bars to the serif "paper" design language app-wide.
        FieldNavBar.applyAppearance()

        self.sharedModelContainer = container!
        let appStoreInstance = AppStore(modelContext: container!.mainContext)
        self._appStore = State(initialValue: appStoreInstance)
        self._gamificationService = State(
            initialValue: GamificationService(modelContext: container!.mainContext, appStore: appStoreInstance)
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.environment["SEED_SCREEN"] == "collection" {
                    NavigationStack { LibraryView() }
                } else if ProcessInfo.processInfo.environment["SEED_SCREEN"] == "profile" {
                    NavigationStack { ProfileView() }
                } else if ProcessInfo.processInfo.environment["SEED_SCREEN"] == "subscription" {
                    NavigationStack { SubscriptionStatusView() }
                } else if onboardingStore.shouldShowOnboarding {
                    OnboardingContainerView()
                } else {
                    MainTabView()
                }
                #else
                if onboardingStore.shouldShowOnboarding {
                    OnboardingContainerView()
                } else {
                    MainTabView()
                }
                #endif
            }
            .environment(\.appStore, appStore)
            .environment(\.onboardingStore, onboardingStore)
            .environment(\.subscriptionStore, subscriptionStore)
            .environment(\.syncStore, syncStore)
            .environment(\.gamificationService, gamificationService)
            .animation(.easeInOut(duration: 0.4), value: onboardingStore.shouldShowOnboarding)
            .tint(FieldColor.accentDeep)
            .preferredColorScheme(.light)
            .task {
                #if DEBUG
                DebugSeed.seedIfRequested(appStore: appStore, gamification: gamificationService)
                // Jump to Capture so the DEBUG review-sheet hook can present on launch.
                if ProcessInfo.processInfo.environment["SEED_REVIEW"] != nil {
                    appStore.selectedTab = .capture
                }
                #endif
                // Check subscription status on launch
                await subscriptionStore.checkAndUpdateStatus()

                // Start listening for StoreKit transaction updates
                await StoreKitService.shared.startTransactionListener { type, expirationDate in
                    await MainActor.run {
                        subscriptionStore.updateSubscription(type: type, expiresAt: expirationDate)
                    }
                }

                // Start iCloud photo sync if available
                if syncStore.iCloudAvailable {
                    // Start monitoring for remote photo changes
                    iCloudPhotoSyncService.shared.startMonitoring()

                    // Perform initial sync in background
                    Task.detached(priority: .background) {
                        await iCloudPhotoSyncService.shared.syncAllPhotos()
                    }

                    // Update sync status
                    await syncStore.updatePhotoSyncStatus()
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
