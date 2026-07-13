# Fieldnote Backend (Milestone 2)

Cloudflare Worker implementing:

- **2A — Pl@ntNet identify proxy** (`POST /v1/identify`): holds the paid Pl@ntNet
  API key server-side, gates access with a per-app bearer token + per-token daily
  cap + per-IP rate limiting, and returns a slimmed candidate list.
- **2B — Region-pack pipeline** (weekly cron + `GET /v1/regions`,
  `GET /v1/regions/{regionID}`): precomputes per-region ecological inputs
  (iNaturalist counts + GBIF-normalized names + monthly affinity) into versioned
  R2 JSON manifests, served with ETag / `If-None-Match` for cheap freshness.

Ranking stays client-side — packs carry inputs, the app runs `LocalRankingService`.

## Layout

```
src/
  index.ts         Router + scheduled (cron) handler
  identify.ts      2A: Pl@ntNet proxy
  delivery.ts      2B: /v1/regions + /v1/regions/{id}
  pipeline.ts      2B: cron rebuild -> R2 + KV
  inaturalist.ts   iNat species_counts + month-of-year histogram
  gbif.ts          GBIF /species/match name normalization
  regions.ts       Region -> place IDs (mirrors iOS CatalogRegion.presets)
  http.ts          JSON / error / auth helpers
  types.ts         Shared types + Env bindings
```

## Endpoints

| Method | Path                     | Auth   | Purpose                                  |
| ------ | ------------------------ | ------ | ---------------------------------------- |
| POST   | `/v1/identify`           | Bearer | Pl@ntNet proxy → `{candidates, remainingRequests}` |
| GET    | `/v1/regions`            | —      | Region index `{regions:[{regionID,name,version,…}]}` |
| GET    | `/v1/regions/{regionID}` | —      | Region pack (JSON), `304` on `If-None-Match` |
| GET    | `/v1/health`             | —      | Liveness                                 |

### `/v1/identify` request

`multipart/form-data` — `images` (one or more JPEGs), `organs` (optional, default
`auto`). `Authorization: Bearer <app-token>`. Mirrors what the old
`PlantIDAPIService` built, minus the `api-key` query item.

### Region pack shape

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
      "monthlyAffinity": [0.19, 0.15, 0.22, 0.48, 0.74, 0.71, 0.66, 0.68, 0.8, 1.0, 0.58, 0.19]
    }
  ]
}
```

## Setup

```bash
npm install

# Create the KV namespace and R2 bucket, then paste the KV id into wrangler.toml.
npx wrangler kv namespace create META
npx wrangler r2 bucket create fieldnote-region-packs

# Secrets (never committed):
npx wrangler secret put PLANTNET_API_KEY     # the paid Pl@ntNet key
npx wrangler secret put APP_TOKENS            # comma-separated app bearer tokens

npm run typecheck
npm run dev            # local dev; add --test-scheduled to trigger the cron
npm run deploy
```

For local dev, put secrets in `.dev.vars` (git-ignored):

```
PLANTNET_API_KEY=...
APP_TOKENS=dev-token-abc
```

Trigger a local pipeline run:

```bash
npm run pipeline:local
curl "http://localhost:8787/__scheduled?cron=0+9+*+*+1"
```

## Notes

- **Keep `src/regions.ts` in sync with iOS `CatalogRegion.presets`** (same IDs and
  iNaturalist place IDs). The pipeline builds a pack per entry here; the app looks
  it up by `regionID`.
- **App auth is a stopgap.** The bearer token is low-trust (obfuscated in the app).
  Harden with Apple App Attest / DeviceCheck before any public launch — verify the
  attestation in `identify.ts` before spending Pl@ntNet quota.
- **Current-location** stays on the app's direct iNaturalist path for M2; only
  named regions use packs.
- **Attribution:** packs cite iNaturalist + GBIF; surface in the app's Settings
  credits.
