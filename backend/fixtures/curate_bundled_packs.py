#!/usr/bin/env python3
"""
Derive the app's bundled region packs (Fieldnote/Resources/RegionPacks/) from the
raw fixture snapshots (backend/fixtures/regions/, top-40 each).

Selects a curated ~25 taxa per region, preferring taxa that have a display photo
AND summary (so every card renders well), ordered by observation count. This is
the on-device regional catalog used when no live backend pack is available.

Deterministic: same inputs -> same output. Re-run after refreshing fixtures.
"""

import json
import glob
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "regions")
DST = os.path.abspath(os.path.join(HERE, "..", "..", "Fieldnote", "Resources", "RegionPacks"))
TARGET = 25


def quality(t):
    """Higher = better card: full data first, then by observation count."""
    has_photo = 1 if t.get("defaultPhotoURL") else 0
    has_summary = 1 if t.get("summary") else 0
    return (has_photo + has_summary, t.get("nearbyObservationCount", 0))


def curate(taxa):
    # Prefer complete, high-count taxa; keep the top TARGET, then re-sort the
    # chosen set by raw observation count for a natural "most reported first" order.
    chosen = sorted(taxa, key=quality, reverse=True)[:TARGET]
    return sorted(chosen, key=lambda t: t.get("nearbyObservationCount", 0), reverse=True)


def main():
    os.makedirs(DST, exist_ok=True)
    for path in sorted(glob.glob(os.path.join(SRC, "*.json"))):
        pack = json.load(open(path))
        pack["taxa"] = curate(pack["taxa"])
        # Bump version so a device replacing an older bundled copy treats it as new.
        pack["version"] = int(pack.get("version", 1))
        out = os.path.join(DST, f"{pack['regionID']}.json")
        with open(out, "w") as f:
            json.dump(pack, f, ensure_ascii=False, indent=2)
        n = len(pack["taxa"])
        photos = sum(1 for t in pack["taxa"] if t.get("defaultPhotoURL"))
        print(f"{pack['regionID']:18} {n} taxa  ({photos} with photos)  -> {out}")


if __name__ == "__main__":
    main()
