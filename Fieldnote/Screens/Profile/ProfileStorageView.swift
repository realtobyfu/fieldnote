import SwiftUI

struct ProfileStorageView: View {
    @Environment(\.syncStore) private var syncStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    BookSectionLabel(text: "Your journal")
                    Text("Kept close.").font(FieldBook.title).accessibilityAddTraits(.isHeader)
                    Text("Your saved entries live on this device and can be read offline.")
                        .font(.body).foregroundStyle(FieldColor.mutedInk)
                }
                storageSection("iCloud", symbol: "icloud") {
                    Text(syncStore.journalUsesCloudStorage ? "iCloud storage enabled" : "Using local storage")
                        .font(.headline)
                    Text(syncStore.journalUsesCloudStorage
                         ? "Your journal is set up to sync across your devices through iCloud. Updates may take time to appear."
                         : "This journal is using local storage. It is available on this device.")
                        .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    Text(syncStore.iCloudAvailable ? "iCloud account available" : syncStore.iCloudUnavailableReason ?? "iCloud is unavailable")
                        .font(.caption).foregroundStyle(FieldColor.mutedInk)
                }
                if syncStore.iCloudAvailable {
                    storageSection("Photo transfers", symbol: "photo.on.rectangle") {
                        Text(photoTransferStatus).font(.subheadline)
                            .foregroundStyle(FieldColor.mutedInk)
                        if syncStore.isPhotosSyncing {
                            ProgressView().tint(FieldBook.cover)
                                .accessibilityLabel("Photo transfers in progress")
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle("Storage & iCloud")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { syncStore.checkiCloudAvailability() }
        }
    }

    private var photoTransferStatus: String {
        if case .error(let message) = syncStore.photoSyncStatus {
            return "Photo transfer needs attention: \(message)"
        }
        if syncStore.isPhotosSyncing {
            return "\(syncStore.pendingPhotoUploads) to upload · \(syncStore.pendingPhotoDownloads) to download"
        }
        return "No photo transfers in progress."
    }

    private func storageSection<Content: View>(_ title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(FieldBook.heading).accessibilityAddTraits(.isHeader)
            Divider()
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
