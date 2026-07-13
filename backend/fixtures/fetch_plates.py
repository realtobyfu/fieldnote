#!/usr/bin/env python3
"""
Find a public-domain botanical illustration for each regional species on
Wikimedia Commons, and download a working copy for integration into the app.

For each species (scientific name) it searches Commons (namespace 6 / files),
filters to public-domain licenses, scores candidates toward historical botanical
PLATES (Britton & Brown, Köhler, Thomé, Curtis, Silva, flora engravings) and away
from photos, picks the best, and downloads a ~1600px JPEG to a staging dir plus a
manifest row (creator/title/year/source/license) for `integrate_plates.py`.

Usage:
    python3 fetch_plates.py <worklist.json> [--out staging_dir] [--start N] [--limit N]

`worklist.json` is a list of {scientificName, commonName, family, inaturalistTaxonID}.
Output: <out>/plates/<key>.jpg  and  <out>/manifest.jsonl (one row per found plate).
Keyless; identifies via User-Agent; ~1 req/sec.
"""

import argparse
import json
import os
import re
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

try:
    import certifi
    SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except Exception:  # noqa: BLE001
    SSL_CTX = ssl._create_unverified_context()

API = "https://commons.wikimedia.org/w/api.php"
UA = "Fieldnote-Backend/1.0 (botanical plate sourcing; contact fieldnote app)"
THROTTLE = 6.0

# Public-domain markers we accept (case-insensitive substring on license fields).
PD_MARKERS = ["public domain", "pd-", "cc0", "cc-zero", "no known copyright"]
# Terms that signal a historical botanical plate. A candidate must carry at least
# one of these (in title/description) to be accepted — otherwise it's assumed to
# be a photograph and we prefer the plant's iNaturalist photo instead.
PLATE_TERMS = [
    "illustration", "plate", " pl.", " pl ", "tab.", "fig.", "figure",
    "flora", "botanical magazine", "botanical", "engraving", "lithograph",
    "drawing", "watercolour", "watercolor", "köhler", "kohler", "britton",
    "thomé", "thome", "curtis", "silva", "redouté", "redoute", "medizinal",
    "icones", "hortus", "kunstformen", "deutschlands", "sertum", "flore",
    "wildflowers of", "north american wild", "line drawing", "-linedrawing",
]
# Terms that usually mark a photograph (penalize).
PHOTO_TERMS = ["photograph", "in situ", "national park", "close-up", "closeup"]


def get_json(url):
    last = None
    for i in range(5):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=30, context=SSL_CTX) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:  # noqa: PERF203
            last = e
            if e.code == 429:
                # Commons rate limit: honor Retry-After, else back off hard.
                wait = int(e.headers.get("Retry-After", 0) or 0) or (30 * (i + 1))
                time.sleep(min(wait, 120))
            else:
                time.sleep(2 * (i + 1))
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(2 * (i + 1))
    raise RuntimeError(f"GET failed: {url} ({last})")


def strip_html(s):
    if not s:
        return None
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", s)).strip() or None


def asset_key(scientific):
    return "_".join(scientific.lower().replace("×", "").split()[:2])


def search_candidates(scientific):
    """Return Commons file candidates about this species. Quoting the binomial
    keeps results relevant; the plate-term filter in score() then separates
    illustrations from the (majority) photographs."""
    q = {
        "action": "query", "format": "json", "generator": "search",
        "gsrsearch": f'"{scientific}"',
        "gsrnamespace": "6", "gsrlimit": "40",
        "prop": "imageinfo",
        "iiprop": "extmetadata|url|mime|size",
        "iiurlwidth": "1600",
    }
    data = get_json(f"{API}?{urllib.parse.urlencode(q)}")
    return list((data.get("query") or {}).get("pages", {}).values())


def is_public_domain(ext):
    fields = " ".join(
        str((ext.get(k) or {}).get("value", "")) for k in
        ("LicenseShortName", "License", "UsageTerms", "Copyrighted", "Restrictions")
    ).lower()
    return any(m in fields for m in PD_MARKERS)


def score(page, scientific):
    ii = (page.get("imageinfo") or [{}])[0]
    ext = ii.get("extmetadata") or {}
    if not is_public_domain(ext):
        return None
    mime = ii.get("mime", "")
    if mime not in ("image/jpeg", "image/png"):
        return None  # skip svg/tif for simple HEIC conversion
    desc = strip_html((ext.get("ImageDescription") or {}).get("value", "")) or ""
    obj = strip_html((ext.get("ObjectName") or {}).get("value", "")) or ""
    title = f'{page.get("title", "")} {desc} {obj}'.lower()

    # Must carry at least one illustration signal — otherwise assume photograph
    # and let the plant keep its iNaturalist photo.
    plate_hits = sum(1 for t in PLATE_TERMS if t in title)
    if plate_hits == 0:
        return None

    s = 2 * plate_hits
    s -= sum(3 for t in PHOTO_TERMS if t in title)
    if scientific.lower() in title:
        s += 2
    # Old scans (pre-1930) are the target aesthetic; mild width bonus.
    s += min((ii.get("width", 0) or 0) // 1200, 2)
    return s


def artist_year(ext):
    artist = strip_html((ext.get("Artist") or {}).get("value", "")) or None
    date = strip_html((ext.get("DateTimeOriginal") or {}).get("value", "")
                      or (ext.get("DateTime") or {}).get("value", "")) or ""
    m = re.search(r"(1[5-9]\d\d|20[0-2]\d)", date)
    year = int(m.group(1)) if m else None
    return artist, year


def download(url, path):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60, context=SSL_CTX) as r:
        data = r.read()
    with open(path, "wb") as f:
        f.write(data)
    return len(data)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("worklist")
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "plate_staging"))
    ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--limit", type=int, default=1000)
    args = ap.parse_args()

    species = json.load(open(args.worklist))[args.start:args.start + args.limit]
    plates_dir = os.path.join(args.out, "plates")
    os.makedirs(plates_dir, exist_ok=True)
    manifest = open(os.path.join(args.out, "manifest.jsonl"), "a")

    found = 0
    consecutive_errors = 0
    for i, sp in enumerate(species, 1):
        # Circuit breaker: if Commons is still penalty-boxing us, bail early so a
        # retry costs a couple minutes, not hours. Re-run later (dedupes).
        if consecutive_errors >= 6:
            print(f"\nAborting at {i}/{len(species)}: {consecutive_errors} consecutive "
                  f"failures — Commons still rate-limited. Re-run later.", file=sys.stderr)
            break
        sci = sp["scientificName"]
        key = asset_key(sci)
        try:
            cands = search_candidates(sci)
            time.sleep(THROTTLE)
            scored = []
            for p in cands:
                sc = score(p, sci)
                if sc is not None:
                    scored.append((sc, p))
            consecutive_errors = 0  # Commons responded; not a rate-limit failure
            if not scored:
                print(f"[{i}/{len(species)}] {sci}: no PD plate", file=sys.stderr)
                continue
            scored.sort(key=lambda x: x[0], reverse=True)
            best = scored[0][1]
            ii = (best.get("imageinfo") or [{}])[0]
            ext = ii.get("extmetadata") or {}
            url = ii.get("thumburl") or ii.get("url")
            artist, year = artist_year(ext)
            path = os.path.join(plates_dir, f"{key}.jpg")
            size = download(url, path)
            time.sleep(THROTTLE)
            row = {
                "assetKey": key,
                "scientificName": sci,
                "commonName": sp.get("commonName"),
                "creator": artist,
                "title": strip_html((ext.get("ObjectName") or {}).get("value", "")) or best.get("title", "").replace("File:", ""),
                "year": year,
                "sourceURL": ii.get("descriptionurl") or ii.get("descriptionshorturl"),
                "license": strip_html((ext.get("LicenseShortName") or {}).get("value", "")) or "Public domain",
                "bytes": size,
                "score": scored[0][0],
            }
            manifest.write(json.dumps(row, ensure_ascii=False) + "\n")
            manifest.flush()
            found += 1
            print(f"[{i}/{len(species)}] {sci} -> {key}.jpg  score={scored[0][0]}  {artist or '?'}")
        except Exception as e:  # noqa: BLE001
            consecutive_errors += 1
            print(f"[{i}/{len(species)}] {sci}: ERROR {e}", file=sys.stderr)
            time.sleep(THROTTLE)

    manifest.close()
    print(f"\nDone. Found {found}/{len(species)} plates in {plates_dir}")


if __name__ == "__main__":
    main()
