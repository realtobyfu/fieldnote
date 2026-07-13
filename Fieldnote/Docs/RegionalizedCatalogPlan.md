# Regionalized Catalog — Implementation Plan (Milestone 2C)

Plan date: July 11, 2026
Companion to: `LocaleAwareCatalogImplementationPlan.md` (M1), `BackendM2Spec.md` (2A/2B).

## What this milestone delivers

Turn region packs from a *ranking input for the bundled 50* into a **region-scoped
catalog**: taxa a region reports that aren't in the bundled 50 become **first-class,
displayable, discoverable catalog records**. A user in Florida and a user in the
Pacific Northwest see materially different catalogs — not just a reordered 50.

This is the "surfacing pack taxa as first-class records" work that
`RegionPack.swift` and `BackendM2Spec.md` explicitly deferred to 2C.

## Two settled product decisions

1. **Metadata source: server-enriched packs.** The pipeline pulls display
   metadata (family, summary, photo, native/introduced) from the iNaturalist taxa
   API + GBIF and writes it into each pack taxon. The app renders any taxon from
   pack data — no hand-authoring hundreds of records, refreshed weekly.
2. **Discovery: discoverable, region-scoped total.** Regional taxa are matchable
   on capture and count toward discovery progress. Progress reads
   "N of {taxa in your region}" — the denominator varies by region. The bundled 50
   remain the universal base layer and offline fallback.

---

## The enriched pack schema

Extends `RegionPackTaxon` (both `backend/src/types.ts` and iOS `RegionPack.swift`)
with display fields. All new fields are **optional** so an un-enriched (2B-era)
pack still decodes and ranks.

```jsonc
{
  "gbifTaxonKey": 2879330,
  "inaturalistTaxonID": 49005,
  "acceptedScientificName": "Quercus rubra",
  "commonName": "Northern Red Oak",
  "nearbyObservationCount": 18420,
  "monthlyAffinity": [0.19, 0.15, ...],   // 12 entries

  // NEW — 2C display metadata (all nullable)
  "family": "Fagaceae",                    // iNat ancestry (rank=family) or GBIF
  "iconicTaxon": "Plantae",                // iNat iconic_taxon_name
  "summary": "Fast-growing oak with...",   // iNat wikipedia_summary, HTML-stripped, ~300 chars
  "wikipediaURL": "https://en.wikipedia.org/wiki/Quercus_rubra",
  "defaultPhotoURL": "https://.../medium.jpg",
  "defaultPhotoAttribution": "(c) ..., some rights reserved (CC BY-NC)",
  "defaultPhotoLicenseCode": "cc-by-nc",   // only surfaced when license permits reuse
  "establishmentMeans": "native"           // native | introduced | endemic | null (place-scoped)
}
```

Notes:
- **No `traits`.** The bundled 50 have hand-written trait chips; there is no clean
  structured source for hundreds of taxa. Pack-only cards compose a display line
  from `family` + `establishmentMeans` + habitat heuristic instead.
- **Placeholder icon.** iNat's `iconic_taxon_name` is just "Plantae" for all plants,
  so it can't distinguish trees from flowers. We derive the SF Symbol from a
  **family → symbol table** (e.g. Fagaceae/Pinaceae/Betulaceae → `tree.fill`),
  defaulting to `leaf.fill`. Table built from the gathered taxa (see data tasks).
- **Photo licensing.** Only render a remote photo when `defaultPhotoLicenseCode`
  is a reuse-permitting CC code; always show attribution. No-derivative / all-rights
  photos fall back to the family SF Symbol.

---

## Backend changes (`backend/`)

### E1. `inaturalist.ts` — taxa detail fetch
- New `taxaDetail(ids: number[]): Promise<Map<number, TaxonDetail>>` using the
  **batch** endpoint `GET /v1/taxa/{id1,id2,...}` (up to 30 IDs/call → 120 taxa =
  4 calls, not 120). Parse `preferred_common_name`, `wikipedia_summary`,
  `wikipedia_url`, `iconic_taxon_name`, `ancestors` (rank=family), `default_photo`
  ({medium_url, attribution, license_code}).
- `establishmentMeans` is place-scoped and not in the batch response; fetch it
  best-effort per top-N taxa via `?place_id=`, else leave null. Optional / cheap-only.

### E2. `pipeline.ts` — fold detail into taxa
- After the counts/GBIF/affinity loop, batch-fetch detail for the taxon IDs and
  populate the new fields. Strip HTML from `wikipedia_summary`, truncate to ~300 chars.
- Bump pack `version` (existing `If-None-Match` flow ships the enriched pack to
  clients automatically; no delivery change needed).

### E3. `types.ts` — mirror the new optional fields on `RegionPackTaxon`.

Rate budget stays fine: per region = 1 counts + ~4 taxa-batch + N histograms,
weekly, 8 regions — well under 10k/day.

---

## iOS changes (`Fieldnote/`)

### C1. `RegionPack.swift` — enriched taxon + pack→catalog projection
- Add the optional display fields to `RegionPackTaxon`.
- New `RegionPack.catalogPlants(mergedWith bundled: [CatalogPlant]) -> [CatalogPlant]`:
  the **region catalog**, which is **pack-driven** — it IS the plants the region
  actually reports (the pack's taxa), ordered by observation count. A bundled-50
  record is substituted (for its richer illustration + copy, with pack-refreshed
  affinity) only when that taxon is also in the pack; bundled plants not reported in
  the region are excluded (no White Pine in the desert). Everything else is a new
  regional record from enriched pack fields. Join/dedupe by `inaturalistTaxonID`
  then `scientificNameKey`. The bundled 50 stay the fallback only when no pack exists.
- `CatalogPlant` gains a `photoURL`/`attribution`/`licenseCode` + `source`
  (`.bundled` / `.regional`) so cards know whether to load a remote photo and how
  to attribute it. Discovery matching (`match(inaturalistTaxonID:scientificName:)`)
  already keys on iNat ID / sci-name, so regional taxa match with no change.

### C2. `AppStore.swift` — region-aware `catalogPlants`
- Today `catalogPlants` is a static `let = CatalogPlant.catalog`. Make it a
  published property derived from the active region pack (bundled 50 when no pack).
  This is the load-bearing change: `isDiscovered`, `undiscoveredPlants`, journal
  progress, capture matching, and Explore all read `catalogPlants`, so region
  scoping propagates for free — including the "N / {region total}" denominator.
- `refreshLocalCatalog()` already fetches the pack; extend it to set the derived
  `catalogPlants` from `pack.catalogPlants(mergedWith:)`. Falls back to bundled 50.

### C3. Explore / cards — render regional taxa
- Card view loads a remote `AsyncImage` when `photoURL` is present and the license
  permits, else the family-derived SF Symbol; shows attribution.
- "Reported nearby" wording unchanged. Pack-only card detail: summary + family +
  native/introduced + "Reported N times in {region}".
- Discovery progress label reads the (now region-scoped) `catalogPlants.count`.

### C4. Offline / fallback
- No pack → bundled 50 only (unchanged behavior). Cached pack → its region catalog.
  Remote photos degrade to SF Symbols offline. Never an empty screen.

### C5. Tests
- `RegionPack.catalogPlants` merge/dedupe (bundled wins; pack-only appended).
- Enriched-field decode (old packs without new fields still decode).
- Region-scoped discovery count.

---

## Data-fetching tasks (delegated to Sonnet subagents)

Mechanical live-API work, no product reasoning — offloaded from the main context:

- **D1–D8. Enriched sample packs, one per region.** Hit live iNaturalist +
  GBIF, produce `backend/fixtures/regions/{regionID}.json` in the enriched schema
  (top ~40 taxa/region). These are the **test fixtures + SwiftUI preview data +
  local-dev packs** so the app builds and demos before the backend redeploys, and
  they validate that every enriched field actually populates.
- **D9. Family → SF Symbol table + bundled-50 audit.** From the gathered taxa,
  build the `family → SF Symbol` mapping (trees vs shrubs vs herbs) and verify the
  bundled 50's `inaturalistTaxonID`s still resolve to the right taxa on iNat.

---

## Sequencing

1. **PR 1 — schema + backend enrichment** (E1–E3) behind a version bump; packs
   start carrying display metadata. Fixtures (D1–D9) land alongside for tests.
2. **PR 2 — iOS region catalog** (C1–C2): `catalogPlants` becomes region-aware,
   discovery goes region-scoped. Data-only; reuses existing Explore UI.
3. **PR 3 — regional card rendering** (C3–C5): remote photos, attribution,
   pack-only detail, tests.

## Out of scope (later)

Canonical GBIF-primary identity (2D), curated editorial collections, international
regions beyond the 8 US presets, WeatherKit/ecoregion enrichment (M4), illustrated
plates for regional taxa (they use iNat photos until commissioned).
