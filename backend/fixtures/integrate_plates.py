#!/usr/bin/env python3
"""
Integrate sourced public-domain plates into the app:
  1. Merge all plate_staging/batch*/manifest.jsonl (dedupe by assetKey).
  2. Convert each staged JPEG -> HEIC (~1400px) into
     Fieldnote/Assets.xcassets/Illustrations/<assetKey>.imageset/.
  3. Generate Fieldnote/Services/IllustrationService+RegionalPlates.swift with
     `regionalPlateAssets` (Set) and `regionalPlateCredits` (asset -> credit).

Assets are keyed by scientific-name (genus_species). Excluded keys (flagged by the
visual spot-check as photos / wrong subject) are skipped.

Usage: python3 integrate_plates.py [--exclude key1,key2,...]
"""

import argparse
import glob
import json
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
STAGING = os.path.join(HERE, "plate_staging")
ASSETS = os.path.join(REPO, "Fieldnote", "Assets.xcassets", "Illustrations")
GEN_SWIFT = os.path.join(REPO, "Fieldnote", "Services", "IllustrationService+RegionalPlates.swift")
MAX_DIM = 1400

# Keys flagged by visual QC as not usable (photos / specimen sheets / wrong
# subject / blank pages). Baked in so a future re-integrate can't silently
# re-add them. asclepias_asperula is a halftone photo page, not an engraving.
DEFAULT_EXCLUDE = {
    "arctostaphylos_pungens", "artemisia_californica", "asclepias_asperula",
    "baccharis_pilularis", "berberis_repens", "datura_wrightii", "diospyros_texana",
    "encelia_californica", "eriogonum_fasciculatum", "eriogonum_umbellatum",
    "glandularia_bipinnatifida", "hedychium_gardnerianum", "hesperoyucca_whipplei",
    "impatiens_capensis", "ipomoea_cordatotriloba", "maianthemum_canadense",
    "monotropa_uniflora", "morella_cerifera", "neltuma_velutina",
    "penstemon_whippleanus", "pinus_brachyptera", "polypodium_glycyrrhiza",
    "polystichum_munitum", "salvia_mellifera", "sisyrinchium_bellum",
    "tellima_grandiflora", "verbesina_virginica", "yucca_schidigera",
}

CONTENTS_TEMPLATE = {
    "images": [
        {"filename": "", "idiom": "universal", "scale": "1x"},
        {"idiom": "universal", "scale": "2x"},
        {"idiom": "universal", "scale": "3x"},
    ],
    "info": {"author": "xcode", "version": 1},
}


def load_manifest():
    rows = {}
    for mf in sorted(glob.glob(os.path.join(STAGING, "*", "manifest.jsonl"))):
        for line in open(mf):
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            rows[row["assetKey"]] = row  # last wins; dedupe
    return rows


def staged_jpg(key):
    hits = glob.glob(os.path.join(STAGING, "*", "plates", f"{key}.jpg"))
    return hits[0] if hits else None


def clean_creator(raw):
    if not raw:
        return None
    # Commons sometimes doubles the value ("Unknown authorUnknown author").
    s = raw.strip()
    for dup in ("Unknown authorUnknown author", "Unknown author"):
        if s == dup:
            return "Unknown"
    half = len(s) // 2
    if len(s) % 2 == 0 and s[:half] == s[half:]:
        s = s[:half]
    return s or None


def swift_str(s):
    if s is None:
        return "nil"
    esc = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")
    return f'"{esc}"'


def swift_credit(row):
    creator = clean_creator(row.get("creator")) or "Unknown"
    title = row.get("title")
    year = row.get("year")
    src = row.get("sourceURL")
    lic = (row.get("license") or "").lower()
    license_case = ".cc0" if ("cc0" in lic or "cc-zero" in lic) else ".publicDomain"
    parts = [f"creator: {swift_str(creator)}"]
    if title:
        parts.append(f"title: {swift_str(title[:120])}")
    if year:
        parts.append(f"year: {year}")
    if src:
        parts.append(f"sourceURL: URL(string: {swift_str(src)})")
    parts.append(f"license: {license_case}")
    return "IllustrationCredit(" + ", ".join(parts) + ")"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--exclude", default="")
    args = ap.parse_args()
    exclude = set(DEFAULT_EXCLUDE)
    exclude |= {k.strip() for k in args.exclude.split(",") if k.strip()}

    rows = load_manifest()
    integrated = []
    skipped_missing = []
    convert_failed = []
    for key, row in sorted(rows.items()):
        if key in exclude:
            continue
        jpg = staged_jpg(key)
        if not jpg or os.path.getsize(jpg) < 2000:  # skip missing / truncated
            skipped_missing.append(key)
            continue
        imgset = os.path.join(ASSETS, f"{key}.imageset")
        heic = os.path.join(imgset, f"{key}.heic")
        try:
            os.makedirs(imgset, exist_ok=True)
            subprocess.run(
                ["sips", "-s", "format", "heic", "-Z", str(MAX_DIM), jpg, "--out", heic],
                check=True, capture_output=True,
            )
        except subprocess.CalledProcessError:
            convert_failed.append(key)
            # Leave no half-baked imageset behind.
            if os.path.isdir(imgset) and not os.path.exists(heic):
                for f in os.listdir(imgset):
                    os.remove(os.path.join(imgset, f))
                os.rmdir(imgset)
            continue
        contents = json.loads(json.dumps(CONTENTS_TEMPLATE))
        contents["images"][0]["filename"] = f"{key}.heic"
        with open(os.path.join(imgset, "Contents.json"), "w") as f:
            json.dump(contents, f, indent=2)
        integrated.append((key, row))

    # Generate the Swift registry.
    asset_lines = ",\n".join(f"        {swift_str(k)}" for k, _ in integrated)
    credit_lines = ",\n".join(
        f"        {swift_str(k)}: {swift_credit(row)}" for k, row in integrated
    )
    swift = f'''//
//  IllustrationService+RegionalPlates.swift
//  Fieldnote
//
//  GENERATED — do not edit by hand. Produced by
//  backend/fixtures/integrate_plates.py from the public-domain plates sourced for
//  region-pack taxa (see Docs/RegionalizedCatalogPlan.md, IllustrationSourcing.md).
//
//  Regional plates are keyed by scientific name (genus_species, lowercase,
//  underscore). Each asset lives in Assets.xcassets/Illustrations/ and carries a
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

    print(f"Integrated {len(integrated)} plates -> {ASSETS}")
    print(f"Generated {GEN_SWIFT}")
    if skipped_missing:
        print(f"Skipped {len(skipped_missing)} manifest rows with no/truncated image: {skipped_missing[:10]}")
    if convert_failed:
        print(f"Conversion failed (skipped) for {len(convert_failed)}: {convert_failed}")
    if exclude:
        print(f"Excluded (flagged): {sorted(exclude)}")


if __name__ == "__main__":
    main()
