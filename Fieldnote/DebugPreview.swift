import Foundation

/// The local design loop never needs CloudKit or a user's persisted collection.
enum DebugPreview {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["FIELDNOTE_LOCAL_PREVIEW"] == "1"
            || ProcessInfo.processInfo.arguments.contains("--fieldnote-preview")
        #else
        false
        #endif
    }
}
