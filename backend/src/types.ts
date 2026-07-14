// Shared types for the Fieldnote backend Worker (2A + 2B).

/// Cloudflare bindings + vars/secrets, as declared in wrangler.toml.
export interface Env {
  // Secrets
  PLANTNET_API_KEY: string;
  APP_TOKENS: string; // comma-separated bearer tokens

  // Vars
  PLANTNET_ENDPOINT: string;
  IDENTIFY_DAILY_CAP: string;
  IDENTIFY_MAX_RESULTS: string;

  // Bindings
  PACKS: R2Bucket;
  META: KVNamespace;
  IDENTIFY_RATE_LIMITER: RateLimiter;
}

/// Cloudflare rate-limit binding shape (not yet in @cloudflare/workers-types).
export interface RateLimiter {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}

// ---------------------------------------------------------------------------
// 2A — identify
// ---------------------------------------------------------------------------

/// Slimmed candidate returned to the app. Maps 1:1 onto the iOS
/// `PlantIdentificationCandidate`, so the app is not coupled to Pl@ntNet's schema.
export interface IdentifyCandidate {
  scientificName: string;
  commonName: string;
  family: string;
  visualConfidence: number; // 0...1
  gbifTaxonKey: number | null;
}

export interface IdentifyResponse {
  candidates: IdentifyCandidate[];
  remainingRequests: number | null;
}

// ---------------------------------------------------------------------------
// 2B — region packs
// ---------------------------------------------------------------------------

/// One taxon's ecological inputs inside a region pack.
export interface RegionPackTaxon {
  gbifTaxonKey: number | null;
  inaturalistTaxonID: number;
  acceptedScientificName: string;
  commonName: string | null;
  nearbyObservationCount: number;
  /// Normalized month-of-year histogram, 12 entries in 0...1. Null when the
  /// per-taxon histogram could not be fetched (the app treats absence as neutral).
  monthlyAffinity: number[] | null;

  // --- 2C display metadata (all nullable; absent on 2B-era packs) ---
  /// Family name (from GBIF match), for the display line + placeholder icon.
  family?: string | null;
  /// iNaturalist iconic taxon name (e.g. "Plantae"). Currently coarse for plants.
  iconicTaxon?: string | null;
  /// Prose summary (iNaturalist wikipedia_summary, HTML-stripped and complete).
  summary?: string | null;
  wikipediaURL?: string | null;
  /// Medium photo URL — only set when the license permits reuse.
  defaultPhotoURL?: string | null;
  /// Attribution string to render alongside the photo.
  defaultPhotoAttribution?: string | null;
  /// CC license code (e.g. "cc-by-nc"); only reuse-permitting codes are kept.
  defaultPhotoLicenseCode?: string | null;
  /// Place-scoped establishment ("native" | "introduced" | "endemic"); optional.
  establishmentMeans?: string | null;
}

/// Versioned manifest served at regions/{regionID}.json.
export interface RegionPack {
  regionID: string;
  version: number;
  generatedAt: string; // ISO 8601
  placeIDs: number[];
  source: string;
  taxa: RegionPackTaxon[];
}

/// Small KV-backed index entry per region, for `GET /v1/regions`.
export interface RegionIndexEntry {
  regionID: string;
  name: string;
  version: number;
  generatedAt: string;
  taxaCount: number;
}
