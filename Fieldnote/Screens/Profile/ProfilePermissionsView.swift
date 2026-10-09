import SwiftUI
import AVFoundation

struct ProfilePermissionsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var locationStatus = LocationService.shared.accessState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    BookSectionLabel(text: "Permissions & privacy")
                    Text("On your terms.").font(FieldBook.title).accessibilityAddTraits(.isHeader)
                    Text("Choose how you capture and where you explore. You can always write an entry by hand.")
                        .font(.body).foregroundStyle(FieldColor.mutedInk)
                }
                permission("Camera", symbol: "camera", status: cameraLabel,
                           explanation: "Used when you open the camera to photograph a plant.")
                permission("Location", symbol: "location", status: locationLabel,
                           explanation: "Used to find a surrounding area or add a place to an encounter when you request it.")
                VStack(alignment: .leading, spacing: 10) {
                    Label("Your photographs", systemImage: "photo").font(FieldBook.heading).accessibilityAddTraits(.isHeader)
                    Divider()
                    Text("The photo picker lets you choose individual images without granting access to your whole library.")
                        .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                    Text("Online plant identification sends your selected photo for processing. Review the suggestion before saving it to your journal.")
                        .font(.subheadline).foregroundStyle(FieldColor.mutedInk)
                }
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    Label("Open system Settings", systemImage: "arrow.up.right")
                        .font(.body.weight(.medium)).frame(minHeight: 44)
                }
                .accessibilityIdentifier("permissions.systemSettings")
                Link("Read the privacy policy", destination: ProfileAppInfo.privacyURL)
                    .font(.subheadline).frame(minHeight: 44)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(FieldBook.paper.ignoresSafeArea())
        .navigationTitle("Permissions & privacy")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, phase in if phase == .active { refreshStatus() } }
        .onAppear(perform: refreshStatus)
    }

    private func permission(_ title: String, symbol: String, status: String, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).font(FieldBook.heading).accessibilityAddTraits(.isHeader)
            Divider()
            Text(status).font(.subheadline.weight(.medium)).foregroundStyle(FieldBook.cover)
            Text(explanation).font(.subheadline).foregroundStyle(FieldColor.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cameraLabel: String {
        switch cameraStatus {
        case .authorized: return "Allowed"
        case .notDetermined: return "Not requested yet"
        case .denied: return "Not allowed"
        case .restricted: return "Restricted by this device"
        @unknown default: return "Unavailable"
        }
    }

    private var locationLabel: String {
        switch locationStatus {
        case .authorized: return "Allowed"
        case .notDetermined: return "Not requested yet"
        case .denied: return "Not allowed"
        case .servicesDisabled: return "Location services are off"
        }
    }

    private func refreshStatus() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        locationStatus = LocationService.shared.accessState
    }
}
