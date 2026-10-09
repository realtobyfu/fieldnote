import SwiftUI

/// Settings have their own destination, so the personal journal remains easy to read.
struct ProfileSettingsSection: View {
    @Environment(\.appStore) private var store
    @Environment(\.onboardingStore) private var onboardingStore
    @Environment(\.subscriptionStore) private var subscriptionStore
    @Environment(\.openURL) private var openURL
    #if DEBUG
    @State private var resetAction: DeveloperReset?
    #endif

    var body: some View {
        List {
            Section("Your journal") {
                NavigationLink { ProfileStorageView() } label: {
                    BookNavigationRow(symbol: "externaldrive", title: "Storage & iCloud", showsChevron: false)
                }
                .accessibilityIdentifier("settings.storage")
                NavigationLink { ProfilePermissionsView() } label: {
                    BookNavigationRow(symbol: "hand.raised", title: "Permissions & privacy", showsChevron: false)
                }
                .accessibilityIdentifier("settings.permissions")
                NavigationLink { SubscriptionStatusView() } label: {
                    BookNavigationRow(symbol: "sparkles", title: "Membership", showsChevron: false)
                }
            }
            .listRowBackground(FieldBook.paper)

            Section("Your records") {
                NavigationLink { PlantManagementView() } label: {
                    BookNavigationRow(symbol: "square.grid.2x2", title: "Manage specimens", detail: "\(store?.plants.count ?? 0)", showsChevron: false)
                }
                NavigationLink { AllEncountersView() } label: {
                    BookNavigationRow(symbol: "clock", title: "Encounter history", detail: "\(store?.allEncounters.count ?? 0)", showsChevron: false)
                }
            }
            .listRowBackground(FieldBook.paper)

            Section {
                NavigationLink { ProfileSourcesView() } label: {
                    BookNavigationRow(symbol: "books.vertical", title: "Sources & credits", showsChevron: false)
                }
                .accessibilityIdentifier("settings.sources")
                Button(action: sendFeedback) {
                    BookNavigationRow(symbol: "envelope", title: "Send feedback", subtitle: "Questions, ideas, or something to fix")
                }
                Link(destination: ProfileAppInfo.privacyURL) {
                    BookNavigationRow(symbol: "doc.text", title: "Privacy policy")
                }
                Link(destination: ProfileAppInfo.termsURL) {
                    BookNavigationRow(symbol: "doc.plaintext", title: "Terms of use")
                }
            } header: {
                Text("About Fieldnote")
            } footer: {
                Text("Fieldnote · \(ProfileAppInfo.version)\nA personal herbarium, one observation at a time.")
                    .padding(.top, 8)
            }
            .listRowBackground(FieldBook.paper)

            #if DEBUG
            Section("Developer") {
                Button("Reset onboarding", role: .destructive) { resetAction = .onboarding }
                    .frame(minHeight: 44)
                Button("Reset subscription", role: .destructive) { resetAction = .subscription }
                    .frame(minHeight: 44)
            }
            .listRowBackground(FieldBook.paper)
            #endif
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FieldBook.wash.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .confirmationDialog("Reset \(resetAction?.rawValue ?? "")?", isPresented: Binding(
            get: { resetAction != nil }, set: { if !$0 { resetAction = nil } }
        ), titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                switch resetAction {
                case .onboarding: onboardingStore.resetOnboarding()
                case .subscription: subscriptionStore.resetForTesting()
                case nil: break
                }
                resetAction = nil
            }
            Button("Cancel", role: .cancel) { resetAction = nil }
        } message: {
            Text("This resets the selected test state. Your journal entries are kept.")
        }
        #endif
    }

    private func sendFeedback() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "3tobiasfu@gmail.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Fieldnote Feedback"),
            URLQueryItem(name: "body", value: "\n\n---\nFieldnote \(ProfileAppInfo.version)")
        ]
        if let url = components.url { openURL(url) }
    }

    #if DEBUG
    private enum DeveloperReset: String { case onboarding, subscription }
    #endif
}

enum ProfileAppInfo {
    static var version: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    static let privacyURL = URL(string: "https://realtobyfu.github.io/fieldnote-support/privacy.html")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
