#!/usr/bin/env python3
"""Refresh complete iNaturalist Wikipedia summaries in committed region packs."""

import json
import os

from fetch_region_pack import taxa_detail


HERE = os.path.dirname(os.path.abspath(__file__))
PACK_DIRECTORIES = (
    os.path.join(HERE, "regions"),
    os.path.join(HERE, "..", "..", "Fieldnote", "Resources", "RegionPacks"),
)


def pack_paths():
    for directory in PACK_DIRECTORIES:
        for filename in sorted(os.listdir(directory)):
            if filename.endswith(".json"):
                yield os.path.join(directory, filename)


def main():
    packs = []
    taxon_ids = set()

    for path in pack_paths():
        with open(path, encoding="utf-8") as source:
            pack = json.load(source)
        packs.append((path, pack))
        taxon_ids.update(taxon["inaturalistTaxonID"] for taxon in pack.get("taxa", []))

    details = taxa_detail(sorted(taxon_ids))

    updated = 0
    for path, pack in packs:
        changed = False
        for taxon in pack.get("taxa", []):
            summary = details.get(taxon["inaturalistTaxonID"], {}).get("summary")
            if summary and summary != taxon.get("summary"):
                taxon["summary"] = summary
                changed = True
                updated += 1

        if changed:
            with open(path, "w", encoding="utf-8") as destination:
                json.dump(pack, destination, ensure_ascii=False, indent=2)
                destination.write("\n")

    print(f"Updated {updated} summaries across {len(packs)} region-pack snapshots.")


if __name__ == "__main__":
    main()
