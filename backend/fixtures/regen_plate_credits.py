#!/usr/bin/env python3
"""
Regenerate ONLY the credit map + asset set in
Fieldnote/Services/IllustrationService+RegionalPlates.swift, keyed to the plates
already shipped as loose HEIC in Fieldnote/BundledImagery/.

Unlike integrate_plates.py this does NOT touch any image assets — the imagery
moved to loose HEIC (see "Ship bulk imagery as loose HEIC"), so the imageset
path in that script is stale. This script only sanitizes and rewrites the Swift
attribution strings, which were scraped verbatim from Wikimedia/Archive.org and
carried boilerplate ("PLEASE COMPLETE AUTHOR INFORMATION"), HTML entities
("&amp;"), doubled "Unknown author", and library-catalogue contributor dumps
into the UI credit line.

The shipped asset set is the source of truth for WHICH plates exist; this reads
it back from the current Swift file and re-emits credits for exactly those keys.

Usage: python3 regen_plate_credits.py [--dry-run]
"""

import argparse
import glob
import html
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
STAGING = os.path.join(HERE, "plate_staging")
GEN_SWIFT = os.path.join(REPO, "Fieldnote", "Services", "IllustrationService+RegionalPlates.swift")

# Life-date ranges attached to catalogue names: "1809-1884", "1810-", "1769?-1819".
LIFE_DATES = re.compile(r",?\s*\(?\d{3,4}\??\s*[-–]\s*\d{0,4}\??\)?\.?")
# Role annotations from library metadata: ", author", "(illustrator)", "del.", "lith.".
ROLE_WORD = re.compile(
    r"[\s,;]*\(?\b(?:book author|author|translator|illustrator|artist|engraver|"
    r"editor|photographer|lithographer|del|lith|sc|fecit|pinx|delin)\b\.?\)?",
    re.I,
)
# Leading role labels: "art: Govindoo", "text:Robert Wight", "photo: X".
ROLE_LABEL = re.compile(r"^\s*(?:art|text|photo|drawing|painting|image)\s*:\s*", re.I)
# Orphan catalogue role codes left after date stripping: ". cn", "1n", "DSI".
CATALOG_CODE = re.compile(r"(?:^|[,\s.])\s*(?:cn|1n|dsi|former owner)\b\.?", re.I)
# Wikimedia filename cruft in titles: trailing "(8469933209)", "(14...)", "WFNY-122A".
FILE_ID_SUFFIX = re.compile(r"\s*\(\d{4,}\)\s*$")
# Catalogue prefixes in titles: "NAS-106 ", "BB-0134 ", "NIE 1905 ".
CATALOG_PREFIX = re.compile(r"^(?:NAS|BB|NIE)[-\s][\w-]*\s+", re.I)

# Creator strings that are not a usable human/attributable author. When the
# creator reduces to one of these, we drop the "After X" lead and let the work
# title/publication carry the caption.
JUNK_CREATOR_MARKERS = (
    "please complete author",
    "no signature",
    "unknown author",
    "anonymous",
    "united states",
    "u.s.",
    "usda",
    "war dept",
    "corps of engineers",
    "dept. of state",
    "botanical magazine dedications",
    "bentham-moxon trust",
    "internet archive book images",
)


def _tidy(name):
    """Collapse whitespace and orphaned punctuation, preserving name-initial dots
    ("William P. C. Barton") — only trims leading/trailing separators."""
    name = re.sub(r"\s*,\s*,\s*", ", ", name)      # ", ," -> ", "
    name = re.sub(r"\s+", " ", name)
    name = re.sub(r"^[\s,;.]+|[\s,;]+$", "", name)  # trim ends but keep a trailing initial dot
    return name


def surname_first_to_natural(name):
    """"Köhler, Franz Eugen" -> "Franz Eugen Köhler". Flips only a clean single
    "Last, First" (both halves alphabetic name tokens, no leftover noise)."""
    if name.count(",") != 1:
        return name
    last, first = (p.strip() for p in name.split(","))
    if not last or not first or any(c.isdigit() for c in last + first):
        return name
    # Both halves must read as names (letters, spaces, initials) — not role codes.
    token = re.compile(r"^[A-Za-zÀ-ÿ.\-'’ ]+$")
    if not (token.match(last) and token.match(first) and first[:1].isupper()):
        return name
    # The surname must be a real word, not bare initials ("M.S.") — guards against
    # flipping a two-person role list like "M.S. , J.N.Fitch".
    if not any(c.islower() for c in last):
        return name
    return f"{first} {last}"


def clean_creator(raw):
    """Return a single, readable author name, or None when the source gives no
    usable human author (empty, boilerplate, institutional, or anonymous)."""
    if not raw:
        return None
    s = html.unescape(raw).strip()

    # "File:Something.jpg: PLEASE COMPLETE... derivative work: Kenraiz" and kin.
    if s.lower().startswith("file:") or "please complete author" in s.lower():
        return None

    # Commons sometimes doubles the whole value, sometimes with a separator.
    for sep in ("", "; ", "., ", ", "):
        half = (len(s) - len(sep)) // 2
        if half > 0 and s[:half] == s[half + len(sep):]:
            s = s[:half]
            break
    s = s.replace("AnonymousUnknown author", "").replace("Unknown authorUnknown author", "")

    # Cut noise clauses and bracketed notes.
    s = re.split(r",?\s*while working for", s, maxsplit=1)[0]
    s = re.sub(r"\[[^\]]*\]", "", s)  # "[illustrator not stated, no signature]"

    # Take the first contributor from a "; "-separated library dump.
    first_contributor = s.split(";")[0]
    # Comma-role lists too: "Michaux (book author), Hillhouse (translator), ...".
    if ")," in first_contributor:
        first_contributor = first_contributor.split("),")[0] + ")"

    name = ROLE_LABEL.sub("", first_contributor)   # drop leading "art:" / "text:"
    name = re.sub(r"\s*\([^)]*\)", "", name)       # drop "(William Dunlop)" alt-name notes
    name = LIFE_DATES.sub("", name)
    name = CATALOG_CODE.sub("", name)
    name = ROLE_WORD.sub("", name)
    name = _tidy(name)

    # After role-stripping a two-person role list ("M.S. del., J.N.Fitch lith.")
    # may leave "M.S. , J.N.Fitch" — keep just the first named contributor.
    if name.count(",") >= 1 and not surname_first_to_natural(name).count(","):
        name = surname_first_to_natural(name)
    elif "," in name:
        name = _tidy(name.split(",")[0])

    name = _tidy(name)
    if not name:
        return None
    low = name.lower()
    if any(marker in low for marker in JUNK_CREATOR_MARKERS):
        return None
    if low in ("unknown", "unknown artist", "anon", "anonymous"):
        return None
    return name


def clean_title(raw):
    if not raw:
        return None
    s = html.unescape(raw).strip()
    s = CATALOG_PREFIX.sub("", s)
    s = FILE_ID_SUFFIX.sub("", s)
    s = re.sub(r"\s+", " ", s).strip()

    low = s.lower()
    # Wikimedia auto-titles that carry no information beyond the species name.
    if re.match(r"^illustration .+\d\b", low) or low.startswith("dutch:"):
        return None
    # Cropped scan-sheet titles ending mid-word (from the manifest's [:120] cut)
    # or opaque codes read as noise; keep only if reasonably self-contained.
    if len(s) < 3:
        return None
    return s


def swift_str(s):
    if s is None:
        return "nil"
    esc = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")
    return f'"{esc}"'


def swift_credit(row):
    creator = clean_creator(row.get("creator"))
    title = clean_title(row.get("title"))
    year = row.get("year")
    src = row.get("sourceURL")
    lic = (row.get("license") or "").lower()
    license_case = ".cc0" if ("cc0" in lic or "cc-zero" in lic) else ".publicDomain"

    parts = [f"creator: {swift_str(creator if creator else 'Unknown artist')}"]
    if title:
        parts.append(f"title: {swift_str(title[:120])}")
    if year:
        parts.append(f"year: {year}")
    if src:
        parts.append(f"sourceURL: URL(string: {swift_str(src)})")
    parts.append(f"license: {license_case}")
    return "IllustrationCredit(" + ", ".join(parts) + ")"


def load_manifest():
    rows = {}
    for mf in sorted(glob.glob(os.path.join(STAGING, "*", "manifest.jsonl"))):
        for line in open(mf):
            line = line.strip()
            if line:
                r = json.loads(line)
                rows[r["assetKey"]] = r
    return rows


def current_asset_keys():
    txt = open(GEN_SWIFT).read()
    m = re.search(r"regionalPlateAssets:\s*Set<String>\s*=\s*\[(.*?)\]", txt, re.S)
    return re.findall(r'"([^"]+)"', m.group(1))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    rows = load_manifest()
    keys = current_asset_keys()
    integrated = [(k, rows[k]) for k in sorted(keys) if k in rows]

    if args.dry_run:
        for k, row in integrated:
            before_c = row.get("creator")
            after = swift_credit(row)
            if clean_creator(before_c) != (before_c or None) or "&amp;" in (before_c or "") or (before_c or "").startswith("File:"):
                print(f"{k}:\n  raw creator: {before_c!r}\n  -> {after}\n")
        return

    asset_lines = ",\n".join(f"        {swift_str(k)}" for k, _ in integrated)
    credit_lines = ",\n".join(
        f"        {swift_str(k)}: {swift_credit(row)}" for k, row in integrated
    )
    swift = f'''//
//  IllustrationService+RegionalPlates.swift
//  Fieldnote
//
//  GENERATED — do not edit by hand. Produced by
//  backend/fixtures/regen_plate_credits.py from the public-domain plates sourced
//  for region-pack taxa (see Docs/RegionalizedCatalogPlan.md, IllustrationSourcing.md).
//
//  Regional plates are keyed by scientific name (genus_species, lowercase,
//  underscore). Each asset lives in Fieldnote/BundledImagery/ and carries a
//  public-domain credit. {len(integrated)} plates.
//

import Foundation

extension IllustrationService {{
    /// Asset names for regional public-domain plates (== scientific name key).
    static let regionalPlateAssets: Set<String> = [
{asset_lines}
    ]

    /// Attribution for each regional plate, keyed by asset name.
    static let regionalPlateCredits: [String: IllustrationCredit] = [
{credit_lines}
    ]
}}
'''
    with open(GEN_SWIFT, "w") as f:
        f.write(swift)
    print(f"Rewrote {len(integrated)} credits -> {GEN_SWIFT}")


if __name__ == "__main__":
    main()
