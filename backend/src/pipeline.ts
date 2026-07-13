// 2B — region-pack pipeline (scheduled Worker, Cron Trigger).
//
// Per region, weekly: pull iNaturalist research-grade species counts, normalize
// names through GBIF, fetch each taxon's month-of-year affinity, then write a
// versioned manifest to R2 and record the version in KV for cheap freshness.

import type { Env, RegionPack, RegionPackTaxon, RegionIndexEntry } from "./types";
import { REGIONS, type RegionConfig } from "./regions";
import * as inat from "./inaturalist";
import * as gbif from "./gbif";

// KV keys.
export const versionKey = (regionID: string) => `pack:version:${regionID}`;
export const INDEX_KEY = "pack:index";
// R2 object key.
export const packObjectKey = (regionID: string) => `regions/${regionID}.json`;

// How many taxa per region we enrich with GBIF + histograms. Bounds the number
// of iNat/GBIF calls so a weekly run stays well within rate limits.
const TAXA_PER_REGION = 120;
// Politeness delay between per-taxon calls (~1 req/s to each upstream).
const THROTTLE_MS = 700;

/// Rebuilds every region pack. Called from the cron handler; failures are
/// isolated per region so one bad region doesn't sink the whole run.
export async function runPipeline(env: Env): Promise<void> {
  const index: RegionIndexEntry[] = [];
  for (const region of REGIONS) {
    try {
      const entry = await buildRegion(env, region);
      index.push(entry);
      console.log(`Built pack ${region.regionID} v${entry.version} (${entry.taxaCount} taxa).`);
    } catch (err) {
      console.error(`Region ${region.regionID} failed: ${String(err)}`);
      // Preserve the prior index entry so the region still lists (serving its
      // last-good R2 pack) even though this run failed.
      const prior = await readIndexEntry(env, region.regionID);
      if (prior) index.push(prior);
    }
  }
  await env.META.put(INDEX_KEY, JSON.stringify(index));
}

/// Rebuilds a single region pack and returns its index entry.
export async function buildRegion(env: Env, region: RegionConfig): Promise<RegionIndexEntry> {
  const counts = await inat.speciesCounts(region.placeIDs, 200);
  const top = counts.sort((a, b) => b.count - a.count).slice(0, TAXA_PER_REGION);

  // Batch-fetch display metadata for all top taxa up front (<=30 IDs/call).
  const detail = await inat.taxaDetail(top.map((c) => c.taxonID)).catch((err) => {
    console.warn(`taxaDetail failed for ${region.regionID}: ${String(err)}`);
    return new Map<number, inat.TaxonDetail>();
  });

  const taxa: RegionPackTaxon[] = [];
  for (const c of top) {
    const [match, affinity] = await Promise.all([
      gbif.matchName(c.scientificName),
      inat.monthlyAffinity(c.taxonID, region.placeIDs).catch(() => null),
    ]);
    const d = detail.get(c.taxonID);
    taxa.push({
      gbifTaxonKey: match.gbifTaxonKey,
      inaturalistTaxonID: c.taxonID,
      acceptedScientificName: match.acceptedScientificName,
      commonName: c.commonName,
      nearbyObservationCount: c.count,
      monthlyAffinity: affinity,
      family: match.family ?? null,
      iconicTaxon: d?.iconicTaxon ?? null,
      summary: d?.summary ?? null,
      wikipediaURL: d?.wikipediaURL ?? null,
      defaultPhotoURL: d?.defaultPhotoURL ?? null,
      defaultPhotoAttribution: d?.defaultPhotoAttribution ?? null,
      defaultPhotoLicenseCode: d?.defaultPhotoLicenseCode ?? null,
      establishmentMeans: null,
    });
    await sleep(THROTTLE_MS);
  }

  const prevVersion = Number((await env.META.get(versionKey(region.regionID))) ?? 0);
  const version = prevVersion + 1;
  const generatedAt = new Date().toISOString();

  const pack: RegionPack = {
    regionID: region.regionID,
    version,
    generatedAt,
    placeIDs: region.placeIDs,
    source: "iNaturalist research-grade species_counts; names via GBIF",
    taxa,
  };

  const body = JSON.stringify(pack);
  await env.PACKS.put(packObjectKey(region.regionID), body, {
    httpMetadata: { contentType: "application/json; charset=utf-8" },
    // A content-derived tag lets delivery answer If-None-Match cheaply.
    customMetadata: { version: String(version) },
  });
  await env.META.put(versionKey(region.regionID), String(version));

  return {
    regionID: region.regionID,
    name: region.name,
    version,
    generatedAt,
    taxaCount: taxa.length,
  };
}

async function readIndexEntry(env: Env, regionID: string): Promise<RegionIndexEntry | null> {
  const raw = await env.META.get(INDEX_KEY);
  if (!raw) return null;
  try {
    const index = JSON.parse(raw) as RegionIndexEntry[];
    return index.find((e) => e.regionID === regionID) ?? null;
  } catch {
    return null;
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
