#!/usr/bin/env python3
"""
Fetch an enriched region pack fixture from the live iNaturalist + GBIF APIs.

Produces backend/fixtures/regions/{regionID}.json in the enriched RegionPack
schema (see Docs/RegionalizedCatalogPlan.md). Keyless; identifies via User-Agent
and throttles to stay well under iNaturalist's ~1 req/s guidance.

Usage:
    python3 fetch_region_pack.py <regionID> <placeIDs comma-sep> [--top N]
Example:
    python3 fetch_region_pack.py california 14 --top 40
    python3 fetch_region_pack.py pacific-northwest 46,10
"""

import argparse
import json
import os
import re
import ssl
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone

# macOS system Python often lacks a CA bundle. Prefer certifi; fall back to an
# unverified context — acceptable here (keyless GETs of public read-only data).
try:
    import certifi
    SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except Exception:  # noqa: BLE001
    SSL_CTX = ssl._create_unverified_context()

INAT = "https://api.inaturalist.org/v1"
GBIF_MATCH = "https://api.gbif.org/v1/species/match"
PLANTAE = 47126
UA = "Fieldnote-Backend/1.0 (region-pack fixture builder)"
THROTTLE = 0.8  # seconds between calls
# CC codes we consider safe to display a photo for (attribution still shown).
REUSABLE_LICENSES = {"cc0", "cc-by", "cc-by-nc", "cc-by-sa", "cc-by-nc-sa"}

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "regions")


def get_json(url, attempts=4):
    last = None
    for i in range(attempts):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=30, context=SSL_CTX) as r:
                return json.load(r)
        except Exception as e:  # noqa: BLE001 - fixture tool, keep going
            last = e
            time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"GET failed after {attempts}: {url} ({last})")


def strip_html(s):
    if not s:
        return None
    text = re.sub(r"<[^>]+>", "", s)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) > 300:
        text = text[:297].rstrip() + "…"
    return text or None


def species_counts(place_ids, per_page=200):
    q = urllib.parse.urlencode({
        "taxon_id": PLANTAE, "quality_grade": "research",
        "place_id": place_ids, "per_page": per_page, "locale": "en",
    })
    data = get_json(f"{INAT}/observations/species_counts?{q}")
    out = []
    for r in data.get("results", []):
        t = r.get("taxon") or {}
        if not t.get("name"):
            continue
        out.append({
            "taxonID": t["id"], "scientificName": t["name"],
            "commonName": t.get("preferred_common_name"), "count": r.get("count", 0),
        })
    return out


def taxa_detail(ids):
    """Batch /v1/taxa/{ids} (<=30/call) -> {id: detail}."""
    detail = {}
    for i in range(0, len(ids), 30):
        chunk = ids[i:i + 30]
        data = get_json(f"{INAT}/taxa/" + ",".join(str(x) for x in chunk))
        for t in data.get("results", []):
            photo = t.get("default_photo") or {}
            license_code = photo.get("license_code")
            usable = license_code in REUSABLE_LICENSES
            detail[t["id"]] = {
                "iconicTaxon": t.get("iconic_taxon_name"),
                "summary": strip_html(t.get("wikipedia_summary")),
                "wikipediaURL": (t.get("wikipedia_url") or "").replace(" ", "_") or None,
                "defaultPhotoURL": photo.get("medium_url") if usable else None,
                "defaultPhotoAttribution": photo.get("attribution") if usable else None,
                "defaultPhotoLicenseCode": license_code if usable else None,
            }
        time.sleep(THROTTLE)
    return detail


def gbif_match(name):
    q = urllib.parse.urlencode({"name": name, "strict": "false", "kingdom": "Plantae"})
    try:
        w = get_json(f"{GBIF_MATCH}?{q}")
        if w.get("matchType") and w["matchType"] != "NONE":
            return {
                "gbifTaxonKey": w.get("acceptedUsageKey") or w.get("usageKey"),
                "acceptedScientificName": w.get("canonicalName") or w.get("scientificName") or name,
                "family": w.get("family"),
            }
    except Exception as e:  # noqa: BLE001
        print(f"  gbif miss for {name!r}: {e}", file=sys.stderr)
    return {"gbifTaxonKey": None, "acceptedScientificName": name, "family": None}


def monthly_affinity(taxon_id, place_ids):
    q = urllib.parse.urlencode({
        "taxon_id": taxon_id, "place_id": place_ids, "quality_grade": "research",
        "date_field": "observed", "interval": "month_of_year",
    })
    try:
        w = get_json(f"{INAT}/observations/histogram?{q}")
        raw = (w.get("results") or {}).get("month_of_year") or {}
        counts = [raw.get(str(m), 0) for m in range(1, 13)]
        mx = max(counts) if counts else 0
        if mx <= 0:
            return None
        return [round(c / mx, 3) for c in counts]
    except Exception:  # noqa: BLE001
        return None


def build(region_id, place_ids, top):
    print(f"[{region_id}] species_counts (places {place_ids})…")
    counts = species_counts(place_ids)
    counts.sort(key=lambda c: c["count"], reverse=True)
    counts = counts[:top]
    print(f"[{region_id}] {len(counts)} taxa; fetching detail…")

    ids = [c["taxonID"] for c in counts]
    detail = taxa_detail(ids)

    taxa = []
    for idx, c in enumerate(counts, 1):
        g = gbif_match(c["scientificName"])
        time.sleep(THROTTLE)
        aff = monthly_affinity(c["taxonID"], place_ids)
        time.sleep(THROTTLE)
        d = detail.get(c["taxonID"], {})
        taxa.append({
            "gbifTaxonKey": g["gbifTaxonKey"],
            "inaturalistTaxonID": c["taxonID"],
            "acceptedScientificName": g["acceptedScientificName"],
            "commonName": c["commonName"],
            "nearbyObservationCount": c["count"],
            "monthlyAffinity": aff,
            "family": g["family"],
            "iconicTaxon": d.get("iconicTaxon"),
            "summary": d.get("summary"),
            "wikipediaURL": d.get("wikipediaURL"),
            "defaultPhotoURL": d.get("defaultPhotoURL"),
            "defaultPhotoAttribution": d.get("defaultPhotoAttribution"),
            "defaultPhotoLicenseCode": d.get("defaultPhotoLicenseCode"),
            "establishmentMeans": None,  # place-scoped; optional, left null in fixtures
        })
        if idx % 10 == 0:
            print(f"[{region_id}]   {idx}/{len(counts)}")

    pack = {
        "regionID": region_id,
        "version": 1,
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "placeIDs": [int(p) for p in place_ids.split(",")],
        "source": "iNaturalist research-grade species_counts; names+family via GBIF; detail via iNaturalist taxa",
        "taxa": taxa,
    }
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"{region_id}.json")
    with open(out_path, "w") as f:
        json.dump(pack, f, ensure_ascii=False, indent=2)
    # Coverage report.
    n = len(taxa)
    have = lambda k: sum(1 for t in taxa if t[k])  # noqa: E731
    print(f"[{region_id}] wrote {out_path}")
    print(f"[{region_id}] coverage: family {have('family')}/{n}, summary {have('summary')}/{n}, "
          f"photo {have('defaultPhotoURL')}/{n}, affinity {have('monthlyAffinity')}/{n}, "
          f"gbifKey {have('gbifTaxonKey')}/{n}")
    return out_path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("region_id")
    ap.add_argument("place_ids", help="comma-separated iNaturalist place IDs")
    ap.add_argument("--top", type=int, default=40)
    args = ap.parse_args()
    build(args.region_id, args.place_ids, args.top)


if __name__ == "__main__":
    main()
