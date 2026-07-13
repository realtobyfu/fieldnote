//
//  BackendConfig.swift
//  Fieldnote
//
//  Reads the Fieldnote backend base URL + app token from Config.plist. The
//  backend (Milestone 2) holds the paid Pl@ntNet key server-side and serves
//  precomputed region packs, so the app ships only a low-trust bearer token —
//  never the Pl@ntNet key. See Docs/BackendM2Spec.md.
//

import Foundation

enum BackendConfig {
    /// Base URL of the Cloudflare Worker, e.g. "https://api.fieldnote.app".
    /// No trailing slash. `nil` when unconfigured (e.g. local builds without a
    /// backend), which callers treat as "backend unavailable".
    static let baseURL: URL? = {
        guard let raw = value(for: "BACKEND_BASE_URL"), isConfiguredValue(raw) else { return nil }
        let trimmed = raw.hasSuffix("/") ? String(raw.dropLast()) : raw
        return URL(string: trimmed)
    }()

    /// Low-trust per-app bearer token gating the identify proxy. Obfuscated in
    /// the binary; the server treats it as a stopgap until App Attest lands.
    static let appToken: String? = {
        guard let raw = value(for: "BACKEND_APP_TOKEN"), isConfiguredValue(raw) else { return nil }
        return raw
    }()

    /// A value counts as configured only if it's non-empty and not a leftover
    /// `REPLACE_WITH_…` placeholder. This lets the app fall straight through to
    /// cached/bundled region packs instead of hanging on a dead placeholder host.
    private static func isConfiguredValue(_ raw: String) -> Bool {
        !raw.isEmpty && !raw.contains("REPLACE_WITH")
    }

    /// True when both the base URL and token are present.
    static var isConfigured: Bool { baseURL != nil && appToken != nil }

    private static let config: NSDictionary? = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else { return nil }
        return NSDictionary(contentsOfFile: path)
    }()

    private static func value(for key: String) -> String? {
        config?[key] as? String
    }
}
