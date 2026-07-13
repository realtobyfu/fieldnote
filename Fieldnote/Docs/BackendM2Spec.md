# Milestone 2 Backend Spec — Key Proxy + Region Packs

Spec date: June 30, 2026
Status: draft for review (no code yet)
Scope: **2A** (Pl@ntNet key proxy) and **2B** (region-pack pipeline). 2C (canonical
taxon catalog) and 2D (curated collections) are noted but out of scope here.
Platform: **Cloudflare Workers** (Workers + Cron Triggers + R2 + KV).

Companion: `LocaleAwareCatalogResearch.md`, `LocaleAwareCatalogImplementationPlan.md`.

## Why a backend now

Two concrete problems M1 left open:

1. **The Pl@ntNet API key ships in `Config.plist`** (`PlantIDAPIService`), i.e. in
   the app binary — extractable, and it gates a paid quota.
2. **Every device calls iNaturalist directly** (`INaturalistService`) and the
   catalog is the bundled 50. This doesn't scale (rate limits, bias, no offline
   pack, no path past 50 taxa).

Non-goals for M2: moving the *personal* (Stage-2) ranking server-side,
illustration sourcing (now real public-domain plates + attribution — see
`IllustrationSourcing.md`), climate enrichment (M4).

## Guiding decisions

- **Ranking stays on-device.** The backend ships the *ecological inputs* (counts,
  monthly affinity, canonical names) per region; the app keeps running
  `LocalRankingService` (Stage-1) + future personal ranking (Stage-2). This
  preserves the tested client logic and keeps personalization private.
- **Coarse data only.** The app sends a region ID or a coarse cell — never precise
  coordinates. (Already true in `LocalityProfile`.)
- **Offline-first.** App ships the bundled 50 as fallback, caches the last pack,
  shows freshness, and only refreshes when online + version changed.
- **iNaturalist is keyless**, so 2B's value is *precompute + cache + GBIF
  normalization + offline packs*, not credential hiding. The credential problem is
  Pl@ntNet (2A).

---

## 2A — Pl@ntNet identify proxy

### Endpoint
`POST /v1/identify`
- Body: multipart/form-data — `images` (one or more JPEGs), `organs` (default
  `auto`). Mirrors what `PlantIDAPIService` already builds.
- Worker forwards to `https://my-api.plantnet.org/v2/identify/all` with the
  server-held key, then returns a **slimmed candidate list** (top N) so the app
  isn't coupled to Pl@ntNet's full schema:

```json
{
  "candidates": [
    { "scientificName": "...", "commonName": "...", "family": "...",
      "visualConfidence": 0.0, "gbifTaxonKey": 123 }
  ],
  "remainingRequests": 480
}
```

This maps 1:1 onto the existing `PlantIdentificationCandidate`.

### Secrets & config
- `PLANTNET_API_KEY` — Worker secret (`wrangler secret put`), never in the repo or app.

### Abuse protection (gating a paid quota)
- **MVP:** a per-app bearer token (`Authorization: Bearer …`) checked by the
  Worker + Cloudflare rate limiting (per IP and per token). Token is obfuscated in
  the app but treated as low-trust.
- **Hardening (fast follow):** Apple **App Attest / DeviceCheck** — the app proves
  it's a genuine, unmodified install before the Worker will spend quota. Recommended
  before any public launch; the MVP token is a stopgap.
- Per-token daily cap so a leaked token can't drain the Pl@ntNet quota.

### App changes (2A)
- `PlantIDAPIService`: change `baseURL` to the Worker, drop the multipart
  `api-key` query item, add the auth header, and decode `{candidates,…}` instead
  of Pl@ntNet's raw response. The `identifyCandidates(...)` shape stays the same.
- Remove `PLANT_ID_API_KEY` from `Config.plist`. Keep the CoreML offline fallback
  (`HybridPlantIdentificationService`) untouched.
- Add the backend base URL + token to build config (not the Pl@ntNet key).

### Estimate
~1 Worker route, ~1 day including the app swap. Independent of 2B — ship first.

---

## 2B — Region-pack pipeline

### Region packs
A **region pack** is a versioned JSON manifest precomputed per region (the
existing `CatalogRegion` set: `california`, `pacific-northwest`, …). It carries the
ecological inputs the app's ranker needs.

```json
{
  "regionID": "pacific-northwest",
  "version": 7,
  "generatedAt": "2026-06-30T00:00:00Z",
  "placeIDs": [46, 10],
  "source": "iNaturalist research-grade species_counts; names via GBIF",
  "taxa": [
    {
      "gbifTaxonKey": 2879330,
      "inaturalistTaxonID": 49005,
      "acceptedScientificName": "Quercus rubra",
      "commonName": "Northern Red Oak",
      "nearbyObservationCount": 18420,
      "monthlyAffinity": [0.19,0.15,0.22,0.48,0.74,0.71,0.66,0.68,0.8,1.0,0.58,0.19]
    }
  ]
}
```

Notes:
- This is a **superset** of the bundled 50 — the pack is how the catalog grows.
- `inaturalistTaxonID` is the join key into the on-device catalog today;
  `gbifTaxonKey` is the canonical identity for 2C.
- `monthlyAffinity` is computed the same way the M1.5 enrichment script did
  (normalized month-of-year histogram), but server-side and refreshed.

### Pipeline (scheduled Worker, Cron Trigger)
Per region, on a weekly cron:
1. Query iNaturalist `species_counts` (place_id union, research-grade, plants).
2. Normalize each taxon's name through **GBIF** (`/species/match`) → accepted
   name + `gbifTaxonKey` + synonyms.
3. Pull the month-of-year histogram per taxon → `monthlyAffinity`.
4. Apply log-scaling / feature prep that doesn't depend on the user.
5. Bump `version`, write the manifest to **R2** at `regions/{regionID}.json`, and
   record the version in **KV** for cheap freshness checks.

Respect iNat limits (~1 req/s, 10k/day): ~8 regions × (1 counts + N histograms)
weekly is well within budget; throttle + cache intermediate results.

### Delivery endpoints
- `GET /v1/regions` → list of available regions + current versions (small, KV-backed).
- `GET /v1/regions/{regionID}` with `If-None-Match`/version → the pack, or `304`.
- R2 objects are served with strong `ETag`s; the Worker sets cache headers.

### Current-location handling
Named regions get precomputed packs. A coarse GPS cell is unbounded, so for M2:
- **Phase 1:** current-location keeps calling iNaturalist directly (today's path),
  unchanged. Only named regions use packs.
- **Phase 2 (optional):** an on-demand `GET /v1/cells/{cellID}` Worker that runs
  the same pipeline for a coarse cell and caches it in KV/R2 for reuse. Still
  keyless; the win is shared caching across nearby users.

### App changes (2B)
- New `RegionPackService` (actor): `fetchPack(regionID:) async throws ->
  RegionPack`, with `If-None-Match` against the cached version.
- `LocalCatalogCache` generalizes from "species counts" to "region pack" (same
  per-region cache file + freshness it already has).
- `AppStore.refreshLocalCatalog()`: for a `.region(...)`, download/parse the pack
  and feed its taxa into `LocalRankingService` instead of calling
  `INaturalistService`. `.currentLocation` stays on the live iNat path (Phase 1).
- Catalog join: pack taxa map onto `CatalogPlant` via `inaturalistTaxonID`
  (already supported), and for taxa not in the bundled 50 we render from pack data
  directly (name/affinity) until 2C gives them full records.

### Estimate
Pipeline Worker + R2/KV + 2 delivery routes + the app `RegionPackService`:
~3–5 days. Depends on nothing in 2A.

---

## Cross-cutting

- **Attribution:** packs cite iNaturalist + GBIF; surface in Settings credits
  (Apple Weather attribution arrives with M4).
- **Versioning/offline:** app caches last pack per region, shows "Updated N days
  ago" (already wired via `catalogFreshnessDate`), refreshes on version change.
- **Fallback:** if the backend is unreachable, named regions fall back to the
  cached pack, then to the bundled 50 — never an empty screen.
- **Cost:** Workers + R2 + KV are well within free/cheap tiers at this scale; the
  binding cost is the Pl@ntNet quota, which 2A's gating protects.
- **Repo layout (proposed):** a sibling `backend/` (or separate repo) with the
  Worker, `wrangler.toml`, and the pipeline — not in the iOS target.

## Open questions for review

1. **App auth for 2A:** ship the MVP bearer token now and add App Attest as a fast
   follow, or do App Attest from the start?
2. **Pack ranking:** ship raw counts + affinity (app ranks) — recommended — or also
   precompute a baseline `rankScore` server-side?
3. **Current-location:** keep it client-direct for M2 (Phase 1), or build the
   on-demand cell endpoint now?
4. **Hosting confirm:** Cloudflare Workers + R2 + KV as specced?

## Suggested sequence

1. **2A** — proxy + app swap + remove key from `Config.plist`. (independent, ~1d)
2. **2B** — pipeline + delivery + `RegionPackService`. (~3–5d)
3. **2C** — canonical taxon catalog (GBIF identity primary), folding pack taxa into
   real catalog records. (separate spec)
