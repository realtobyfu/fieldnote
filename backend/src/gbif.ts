// GBIF name normalization. Maps an iNaturalist scientific name onto GBIF's
// accepted name + taxon key, giving the pack a canonical identity (2C-ready).

const MATCH_URL = "https://api.gbif.org/v1/species/match";
const USER_AGENT = "Fieldnote-Backend/1.0 (region-pack pipeline)";

export interface GbifMatch {
  gbifTaxonKey: number | null;
  acceptedScientificName: string;
  family: string | null;
}

interface GbifMatchWire {
  usageKey?: number;
  acceptedUsageKey?: number;
  scientificName?: string;
  canonicalName?: string;
  family?: string;
  matchType?: string; // EXACT | FUZZY | HIGHERRANK | NONE
}

/// Normalizes a scientific name through GBIF. Falls back to the input name when
/// GBIF has no confident match, so a taxon is never dropped from the pack.
export async function matchName(scientificName: string): Promise<GbifMatch> {
  const url = new URL(MATCH_URL);
  url.searchParams.set("name", scientificName);
  url.searchParams.set("strict", "false");
  url.searchParams.set("kingdom", "Plantae");

  try {
    const res = await fetch(url.toString(), {
      headers: { "user-agent": USER_AGENT, accept: "application/json" },
    });
    if (!res.ok) throw new Error(`GBIF ${res.status}`);
    const wire = (await res.json()) as GbifMatchWire;

    if (wire.matchType && wire.matchType !== "NONE") {
      return {
        // Prefer the accepted usage key (resolves synonyms to the accepted taxon).
        gbifTaxonKey: wire.acceptedUsageKey ?? wire.usageKey ?? null,
        acceptedScientificName: wire.canonicalName ?? wire.scientificName ?? scientificName,
        family: wire.family ?? null,
      };
    }
  } catch (err) {
    console.warn(`GBIF match failed for "${scientificName}": ${String(err)}`);
  }

  return { gbifTaxonKey: null, acceptedScientificName: scientificName, family: null };
}
