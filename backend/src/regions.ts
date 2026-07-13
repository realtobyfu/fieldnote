// The regions the pipeline precomputes packs for. Mirrors the iOS
// `CatalogRegion.presets` (AppStore.swift) — keep the two in sync: same IDs,
// same iNaturalist place IDs. A macro-region unions its states' place IDs.

export interface RegionConfig {
  regionID: string;
  name: string;
  placeIDs: number[];
}

export const REGIONS: RegionConfig[] = [
  { regionID: "california", name: "California", placeIDs: [14] },
  { regionID: "pacific-northwest", name: "Pacific Northwest", placeIDs: [46, 10] },
  { regionID: "desert-southwest", name: "Desert Southwest", placeIDs: [40, 50] },
  { regionID: "rocky-mountains", name: "Rocky Mountains", placeIDs: [34, 52] },
  { regionID: "texas", name: "Texas", placeIDs: [18] },
  { regionID: "florida", name: "Florida", placeIDs: [21] },
  { regionID: "northeast", name: "Northeast US", placeIDs: [48, 2, 47] },
  { regionID: "hawaii", name: "Hawai‘i", placeIDs: [11] },
];

export function regionByID(regionID: string): RegionConfig | undefined {
  return REGIONS.find((r) => r.regionID === regionID);
}
