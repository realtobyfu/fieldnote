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
            MainTabView()
                .environment(\.appStore, appStore)
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
