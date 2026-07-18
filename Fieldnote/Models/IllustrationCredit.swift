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
    ///
    /// When the source names no attributable artist (many public-domain scans
    /// only credit an institution or "Unknown"), the caption leads with the work
    /// instead of "After Unknown", and falls back to a plain public-domain note
    /// when there's no usable work text either.
    var captionText: String {
        let unknownCreator = creator.isEmpty
            || creator.lowercased().hasPrefix("unknown")
            || creator.lowercased() == "anonymous"

        let work = [title, publication].compactMap { $0 }.joined(separator: ", ")

        var parts: [String] = []
        if !unknownCreator {
            parts.append("After \(creator)")
        }
        if !work.isEmpty {
            parts.append(year.map { "\(work), \($0)" } ?? work)
        } else if !unknownCreator, let year {
            parts.append(String(year))
        }

        return parts.isEmpty ? "Public-domain illustration" : parts.joined(separator: " · ")
    }
}
