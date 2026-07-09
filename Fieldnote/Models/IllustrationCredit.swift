//
//  IllustrationCredit.swift
//  Fieldnote
//
//  Attribution metadata for a botanical illustration asset.
//
//  Credits describe the *image*, not the plant, so they are keyed by asset name
//  (see IllustrationService). AI-generated house illustrations carry no credit
//  and render no attribution line — only real, human-authored public-domain
//  plates are attributed. See Docs/IllustrationSourcing.md.
//

import Foundation

/// Attribution for a single botanical illustration asset.
///
/// Present only for reproductions of real, historical botanical art (typically
/// public-domain plates). The absence of a credit is meaningful: it marks an
/// original Fieldnote (AI-generated) illustration, which is intentionally left
/// uncredited.
struct IllustrationCredit: Codable, Hashable {
    /// The artist or illustrator, e.g. "Pierre-Joseph Redouté". Required — a
    /// credit exists precisely because there is a human author to name.
    let creator: String
    /// The plate or work title, e.g. "Rosa gallica". Optional.
    let title: String?
    /// The publication the plate appeared in, e.g. "Les Roses". Optional.
    let publication: String?
    /// Year of original publication, e.g. 1817. Optional.
    let year: Int?
    /// Canonical source of the scan (Biodiversity Heritage Library, Wikimedia
    /// Commons, etc.). Optional; shown as a tappable link when present.
    let sourceURL: URL?
    /// Rights statement. Defaults to public domain, which is the only basis on
    /// which we ship third-party plates.
    let license: License

    enum License: String, Codable {
        case publicDomain = "Public Domain"
        /// Creative Commons CC0 (dedicated to the public domain).
        case cc0 = "CC0"

        var displayName: String { rawValue }
    }

    init(
        creator: String,
        title: String? = nil,
        publication: String? = nil,
        year: Int? = nil,
        sourceURL: URL? = nil,
        license: License = .publicDomain
    ) {
        self.creator = creator
        self.title = title
        self.publication = publication
        self.year = year
        self.sourceURL = sourceURL
        self.license = license
    }
}

// MARK: - Presentation

extension IllustrationCredit {
    /// A single-line attribution caption in the app's antiquarian voice, e.g.
    /// "After P.-J. Redouté · Les Roses, 1817". Built defensively so partial
    /// metadata still yields a sensible line.
    var captionText: String {
        var parts: [String] = ["After \(creator)"]

        let workComponents = [title, publication].compactMap { $0 }
        var work = workComponents.joined(separator: ", ")
        if let year {
            work = work.isEmpty ? String(year) : "\(work), \(year)"
        }
        if !work.isEmpty {
            parts.append(work)
        }

        return parts.joined(separator: " · ")
    }
}
