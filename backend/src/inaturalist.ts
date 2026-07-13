// iNaturalist client for the pipeline. Keyless; identify the client via
// User-Agent and stay well under ~1 req/s.

const BASE = "https://api.inaturalist.org/v1";
const PLANTAE_TAXON_ID = 47126; // kingdom Plantae
const USER_AGENT = "Fieldnote-Backend/1.0 (region-pack pipeline)";

export interface SpeciesCount {
  taxonID: number;
  scientificName: string;
  commonName: string | null;
  count: number;
}

interface SpeciesCountsWire {
  results: Array<{
    count: number;
    taxon?: {
      id: number;
      name?: string;
      preferred_common_name?: string;
    };
  }>;
}

interface HistogramWire {
  results: {
    month_of_year?: Record<string, number>;
  };
}

/// Research-grade plant species counts across a union of place IDs (annual).
export async function speciesCounts(placeIDs: number[], limit = 200): Promise<SpeciesCount[]> {
  const url = new URL(`${BASE}/observations/species_counts`);
  url.searchParams.set("taxon_id", String(PLANTAE_TAXON_ID));
  url.searchParams.set("quality_grade", "research");
  url.searchParams.set("place_id", placeIDs.join(","));
  url.searchParams.set("per_page", String(Math.min(Math.max(limit, 1), 500)));
  url.searchParams.set("locale", "en");

  const wire = await getJSON<SpeciesCountsWire>(url);
  const out: SpeciesCount[] = [];
  for (const r of wire.results) {
    if (!r.taxon?.name) continue;
    out.push({
      taxonID: r.taxon.id,
      scientificName: r.taxon.name,
      commonName: r.taxon.preferred_common_name ?? null,
      count: r.count,
    });
  }
  return out;
}

/// Month-of-year observation histogram for a taxon within the given places,
/// normalized to 0...1 (12 entries, Jan..Dec). Null if the histogram is empty.
export async function monthlyAffinity(
  taxonID: number,
  placeIDs: number[],
): Promise<number[] | null> {
  const url = new URL(`${BASE}/observations/histogram`);
  url.searchParams.set("taxon_id", String(taxonID));
  url.searchParams.set("place_id", placeIDs.join(","));
  url.searchParams.set("quality_grade", "research");
  url.searchParams.set("date_field", "observed");
  url.searchParams.set("interval", "month_of_year");

  const wire = await getJSON<HistogramWire>(url);
  const raw = wire.results.month_of_year;
  if (!raw) return null;

  const counts = new Array<number>(12).fill(0);
  for (let m = 1; m <= 12; m++) {
    counts[m - 1] = raw[String(m)] ?? 0;
  }
  const max = Math.max(...counts);
  if (max <= 0) return null;
  return counts.map((c) => Number((c / max).toFixed(3)));
}

// CC codes we consider safe to surface a photo for (attribution still shown).
const REUSABLE_LICENSES = new Set(["cc0", "cc-by", "cc-by-nc", "cc-by-sa", "cc-by-nc-sa"]);

export interface TaxonDetail {
  iconicTaxon: string | null;
  summary: string | null;
  wikipediaURL: string | null;
  defaultPhotoURL: string | null;
  defaultPhotoAttribution: string | null;
  defaultPhotoLicenseCode: string | null;
}

interface TaxaWire {
  results: Array<{
    id: number;
    iconic_taxon_name?: string;
    wikipedia_summary?: string;
    wikipedia_url?: string;
    default_photo?: {
      medium_url?: string;
      attribution?: string;
      license_code?: string | null;
    };
  }>;
}

/// Display metadata for a set of taxa, via the batch `/v1/taxa/{ids}` endpoint
/// (<=30 IDs per call). Photos are only kept when the license permits reuse.
export async function taxaDetail(ids: number[]): Promise<Map<number, TaxonDetail>> {
  const out = new Map<number, TaxonDetail>();
  for (let i = 0; i < ids.length; i += 30) {
    const chunk = ids.slice(i, i + 30);
    const url = new URL(`${BASE}/taxa/${chunk.join(",")}`);
    const wire = await getJSON<TaxaWire>(url);
    for (const t of wire.results) {
      const photo = t.default_photo ?? {};
      const usable = !!photo.license_code && REUSABLE_LICENSES.has(photo.license_code);
      out.set(t.id, {
        iconicTaxon: t.iconic_taxon_name ?? null,
        summary: cleanSummary(t.wikipedia_summary),
        wikipediaURL: t.wikipedia_url ? t.wikipedia_url.replace(/ /g, "_") : null,
        defaultPhotoURL: usable ? photo.medium_url ?? null : null,
        defaultPhotoAttribution: usable ? photo.attribution ?? null : null,
        defaultPhotoLicenseCode: usable ? photo.license_code ?? null : null,
      });
    }
  }
  return out;
}

/// Strips HTML and truncates a Wikipedia summary to ~300 chars.
function cleanSummary(s: string | undefined): string | null {
  if (!s) return null;
  const text = s.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
  if (!text) return null;
  return text.length > 300 ? text.slice(0, 297).trimEnd() + "…" : text;
}

async function getJSON<T>(url: URL): Promise<T> {
  const res = await fetch(url.toString(), {
    headers: { "user-agent": USER_AGENT, accept: "application/json" },
  });
  if (res.status === 429) throw new Error("iNaturalist rate limited");
  if (!res.ok) throw new Error(`iNaturalist ${res.status} for ${url.pathname}`);
  return (await res.json()) as T;
}
