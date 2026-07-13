// 2B — region-pack delivery routes.
//   GET /v1/regions            -> KV-backed index of available regions + versions
//   GET /v1/regions/{regionID} -> the R2 pack, with ETag / If-None-Match -> 304

import type { Env, RegionIndexEntry } from "./types";
import { INDEX_KEY, packObjectKey } from "./pipeline";
import { regionByID } from "./regions";
import { json, errorResponse } from "./http";

export async function handleRegionsIndex(env: Env): Promise<Response> {
  const raw = await env.META.get(INDEX_KEY);
  const regions: RegionIndexEntry[] = raw ? safeParse(raw) : [];
  return json(
    { regions },
    { headers: { "cache-control": "public, max-age=3600" } },
  );
}

export async function handleRegionPack(regionID: string, request: Request, env: Env): Promise<Response> {
  if (!regionByID(regionID)) {
    return errorResponse(404, "unknown_region", `No pack for region "${regionID}".`);
  }

  const object = await env.PACKS.get(packObjectKey(regionID));
  if (!object) {
    return errorResponse(404, "pack_not_built", "This region has not been built yet.");
  }

  // Prefer the pack version as a stable ETag; fall back to R2's own etag.
  const version = object.customMetadata?.version;
  const etag = version ? `"v${version}"` : `"${object.etag}"`;

  const ifNoneMatch = request.headers.get("if-none-match");
  if (ifNoneMatch && etagMatches(ifNoneMatch, etag)) {
    return new Response(null, {
      status: 304,
      headers: { etag, "cache-control": "public, max-age=3600" },
    });
  }

  return new Response(object.body, {
    headers: {
      "content-type": "application/json; charset=utf-8",
      etag,
      "cache-control": "public, max-age=3600",
    },
  });
}

function etagMatches(ifNoneMatch: string, etag: string): boolean {
  return ifNoneMatch
    .split(",")
    .map((t) => t.trim().replace(/^W\//, ""))
    .some((t) => t === etag || t === "*");
}

function safeParse(raw: string): RegionIndexEntry[] {
  try {
    return JSON.parse(raw) as RegionIndexEntry[];
  } catch {
    return [];
  }
}
