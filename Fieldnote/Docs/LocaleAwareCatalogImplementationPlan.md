# Locale-Aware Catalog — Implementation Plan (Milestone 1)

Plan date: June 24, 2026
Companion to: `LocaleAwareCatalogResearch.md`

## Scope

Milestone 1 only: **prove local relevance, client-side**. No backend.
iNaturalist `species_counts` is free and keyless; the Pl@ntNet key already ships
in `Config.plist`. Backend, region packs, and key-proxying are deferred to
Milestone 2.

Goal test (from research §Success measures): users in different cities see
visibly different Explore screens before recording anything.

## Current state (grounding)

- `CatalogPlant.catalog` — static 50 items, identity by random `UUID`, matched to
  results by normalized name. `Fieldnote/Models/PlantCatalog.swift`,
  `Fieldnote/Models/Mock/PlantCatalog+Mock.swift`.
- `ExploreView.browseSections` — Recently Encountered → Custom Plants → full
  catalog in bundled order. Commented-out `NearMeSection` + a GPS TODO.
  `Fieldnote/Screens/Explore/ExploreView.swift`.
- `PlantIDAPIService.identify` — keeps only `results.first`; accepts `location`
  but never sends it. `Fieldnote/Services/PlantIDAPIService.swift:153`.
- `LocationService` — one-shot fetcher for capture tagging only; does not feed the
  catalog. `Fieldnote/Services/LocationService.swift`.
- `AppStore` — exposes `catalogPlants`, `isDiscovered`, `undiscoveredPlants`,
  `refresh()`. `Fieldnote/Store/AppStore.swift`.

## Privacy posture

Send only a **coarse cell** (rounded lat/lng grid) to iNaturalist. Precise
encounter coordinates stay local to the observation. Request approximate
location; offer manual region as fallback.

---

## Workstream A — Data layer (first PR, UI untouched)

### A1. Stable taxon identity
`Fieldnote/Models/PlantCatalog.swift`
- Add optional fields to `CatalogPlant`: `gbifTaxonKey: Int?`,
  `inaturalistTaxonID: Int?`, `monthlyAffinity: [Double]?` (12 entries).
- Keep `UUID` identity for now (don't break bundled data or discovery matching).
- Add a normalized-scientific-name join helper so iNat taxa map to catalog
  entries by `scientificName` when IDs are absent (reuse existing `normalize`).

### A2. iNaturalist client
`Fieldnote/Services/INaturalistService.swift` (new) — `actor`, shaped like
`PlantIDAPIService`.
- `func speciesCounts(lat:lng:radiusKm:month:) async throws -> [INatSpeciesCount]`
- Endpoint: `GET /v1/observations/species_counts`, `quality_grade=research`,
  `taxon_id=47126` (plants), `radius`, `month`, `lat`, `lng`.
- Response model: taxon id, accepted name, common name, count, default photo URL.
- Respect ~1 req/sec, 10k/day — one fetch per cell-change or month is enough.

### A3. Locality profile + cache
`Fieldnote/Models/LocalityProfile.swift` (new)
- `coarseCellID` (rounded grid), `displayRegion`, `countryCode`, `hemisphere`,
  `currentMonth`, `generatedAt`.
`Fieldnote/Services/LocalCatalogCache.swift` (new)
- Persist last `species_counts` keyed by `coarseCellID + month` with freshness
  date. Codable file in Application Support (pattern: `PhotoStorageService`).

### A4. Stage-1 ranking (pure, testable)
`Fieldnote/Services/LocalRankingService.swift` (new)
- Pure functions, no I/O. Produces `rankScore` + `explanationCodes`
  (`nearby_now`, `seasonal_peak`, `easy_first_find`) per catalog taxon.
- **Log-scale** occurrence counts so urban weeds don't dominate.
- Stage-1 weights only (occurrence / seasonal affinity / recency). Defer the
  personal + editorial Stage-2 model to Milestone 2.
- `LocalCatalogItem` view model: `taxonID`, `nearbyObservationCount`,
  `rankScore`, `explanationCodes`.

### A5. Candidate reranking for identification
`Fieldnote/Services/PlantIDAPIService.swift`
- Return top **3–5** candidates, not `results.first` (new candidates result
  type or extend the existing one).
- Actually forward `location` to the Pl@ntNet request.
`HybridPlantIdentificationService` already plumbs `location` — stop dropping it.
- In `LocalRankingService`, combine `visualLikelihood × localPrior ×
  seasonalPrior`, **visual signal dominant** (research §291).

### A6. Tests (Swift Testing)
- `LocalRankingService`: log-scaling, explanation codes, visual-dominant combine.
- iNat → catalog name join.

---

## Workstream B — Explore + identification UI (second PR)

### B1. AppStore wiring
`Fieldnote/Store/AppStore.swift`
- Observable state: `localityProfile`, `localCatalogItems`,
  `catalogFreshnessDate`.
- `func refreshLocalCatalog() async`; call from `refresh()` and `.refreshable`.

### B2. Location-value prompt
- Pre-permission explainer ("See plants reported near you and what's active this
  season") with **Use Approximate Location** / **Choose a City**.
- Update `NSLocationWhenInUseUsageDescription` (Info.plist) to mention local
  discovery, not just observation tagging.

### B3. Explore sections
`Fieldnote/Screens/Explore/ExploreView.swift` + `Components/`
- Replace `browseSections` with ecology-led order: **Near You Now**,
  **Reported This Month**, then existing catalog as fallback. Reuse
  `NearMeSection`.
- Per-card **"Why this plant?"** line from `explanationCodes`. Use
  **"reported nearby"** wording — no abundance claims.
- Minimal **region picker**: current location vs. one chosen city (enough to
  prove the travel case). Changing Explore region must NOT change the region
  stored on an observation.

### B4. Capture review alternatives
`Fieldnote/Screens/Capture/CaptureReviewSheet.swift`
- Show reranked top candidate plus alternatives when scores are close, instead of
  presenting `results.first` as certainty.

---

## Sequencing

1. **PR 1 — data layer:** A1–A6, behind the existing Explore UI (no visible
   change). Independently reviewable.
2. **PR 2 — UI:** B1–B4.

## Out of scope (Milestone 2+)

Canonical taxon IDs as primary identity, backend scheduler + versioned region
manifests, offline region packs, saved/travel regions, curated collections,
key-proxying off-device, illustration factory, WeatherKit/ecoregion enrichment.

## Risks / safeguards (carried from research)

- Crowdsourcing bias → "reported nearby," never abundance claims.
- Location privacy → coarse cell to iNat, precise coords stay local.
- Rate limits → cache per cell + month, refresh on change only.
- Vendor dependency → keep the bundled 50-item fallback catalog working offline.
