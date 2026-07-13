# Region-pack fixtures (Milestone 2C)

Enriched sample region packs, produced by hitting the live iNaturalist + GBIF
APIs. They serve three purposes:

1. **Test fixtures** for backend + iOS unit tests.
2. **SwiftUI preview / local-dev data** so the app renders regional catalogs
   before the backend redeploys the enriched pipeline.
3. **Validation** that every enriched display field actually populates from the
   upstream APIs.

Each `regions/{regionID}.json` matches the enriched `RegionPack` schema in
`Docs/RegionalizedCatalogPlan.md` (§"The enriched pack schema"). Capped at the
top ~40 taxa per region by observation count to keep fixtures small.

Regenerate by re-running the pipeline; these are committed snapshots, not live.
