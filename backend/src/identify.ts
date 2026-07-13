// 2A — Pl@ntNet identify proxy.
//
// Holds the paid Pl@ntNet key server-side, gates access behind a per-app bearer
// token + a per-token daily cap + Cloudflare per-IP rate limiting, forwards the
// multipart request, and returns a slimmed candidate list.

import type { Env, IdentifyCandidate, IdentifyResponse } from "./types";
import { json, errorResponse, bearerToken, clientIP } from "./http";

// Pl@ntNet's raw response shape (only the fields we consume).
interface PlantNetResponse {
  results: Array<{
    score: number;
    species: {
      scientificNameWithoutAuthor: string;
      family?: { scientificNameWithoutAuthor?: string };
      commonNames?: string[];
    };
    gbif?: { id?: string };
  }>;
  remainingIdentificationRequests?: number;
}

const MIN_SCORE = 0.1;

export async function handleIdentify(request: Request, env: Env): Promise<Response> {
  if (request.method !== "POST") {
    return errorResponse(405, "method_not_allowed", "Use POST.");
  }

  // 1. Auth — bearer token must be in the configured allow-list.
  const token = bearerToken(request);
  if (!token || !isKnownToken(token, env)) {
    return errorResponse(401, "unauthorized", "Missing or invalid app token.");
  }

  // 2. Per-IP rate limit (cheap first line of defense against bursts).
  const ip = clientIP(request);
  const rl = await env.IDENTIFY_RATE_LIMITER.limit({ key: ip });
  if (!rl.success) {
    return errorResponse(429, "rate_limited", "Too many requests. Try again shortly.");
  }

  // 3. Per-token rolling daily cap — a leaked token can't drain the quota.
  const cap = Number(env.IDENTIFY_DAILY_CAP) || 500;
  const capKey = `identify:count:${token}:${utcDay()}`;
  const used = Number((await env.META.get(capKey)) ?? 0);
  if (used >= cap) {
    return errorResponse(429, "daily_cap", "Daily identification limit reached.");
  }

  // 4. Rebuild the multipart body for Pl@ntNet. We re-stream the incoming
  //    form so we control exactly which fields are forwarded (images, organs).
  let inbound: FormData;
  try {
    inbound = await request.formData();
  } catch {
    return errorResponse(400, "bad_request", "Expected multipart/form-data.");
  }

  // At runtime Workers returns File objects for file parts, though the types
  // model every entry as a string — filter on Blob-ness rather than the type.
  const imageParts = (inbound.getAll("images") as unknown as Array<Blob | string>)
    .filter((v): v is Blob => typeof v !== "string");
  if (imageParts.length === 0) {
    return errorResponse(400, "no_images", "At least one image is required.");
  }

  const outbound = new FormData();
  for (const image of imageParts) {
    const filename = image instanceof File ? image.name || "plant.jpg" : "plant.jpg";
    outbound.append("images", image, filename);
  }
  const organs = inbound.getAll("organs") as unknown as string[];
  if (organs.length > 0) {
    for (const organ of organs) outbound.append("organs", String(organ));
  } else {
    outbound.append("organs", "auto");
  }

  const url = new URL(env.PLANTNET_ENDPOINT);
  url.searchParams.set("api-key", env.PLANTNET_API_KEY);

  let upstream: Response;
  try {
    upstream = await fetch(url.toString(), { method: "POST", body: outbound });
  } catch {
    return errorResponse(502, "upstream_unreachable", "Could not reach the identification service.");
  }

  if (upstream.status === 404) {
    // Pl@ntNet returns 404 when nothing matches — surface as an empty result.
    return json<IdentifyResponse>({ candidates: [], remainingRequests: null });
  }
  if (upstream.status === 401) {
    // Server-side key problem — never leak upstream detail to the client.
    console.error("Pl@ntNet rejected the server key (401).");
    return errorResponse(502, "upstream_auth", "Identification service is unavailable.");
  }
  if (upstream.status === 429) {
    return errorResponse(429, "upstream_rate_limited", "Identification service is busy. Try again later.");
  }
  if (!upstream.ok) {
    console.error(`Pl@ntNet returned ${upstream.status}.`);
    return errorResponse(502, "upstream_error", "Identification service error.");
  }

  let decoded: PlantNetResponse;
  try {
    decoded = (await upstream.json()) as PlantNetResponse;
  } catch {
    return errorResponse(502, "upstream_decode", "Unexpected identification response.");
  }

  // 5. Only now count the successful call against the daily cap.
  await bumpDailyCount(env, capKey, used);

  const maxResults = Number(env.IDENTIFY_MAX_RESULTS) || 5;
  const candidates: IdentifyCandidate[] = decoded.results
    .filter((r) => r.score >= MIN_SCORE)
    .slice(0, maxResults)
    .map((r) => ({
      scientificName: r.species.scientificNameWithoutAuthor,
      commonName: r.species.commonNames?.[0] ?? r.species.scientificNameWithoutAuthor,
      family: r.species.family?.scientificNameWithoutAuthor ?? "",
      visualConfidence: r.score,
      gbifTaxonKey: parseGbifKey(r.gbif?.id),
    }));

  return json<IdentifyResponse>({
    candidates,
    remainingRequests: decoded.remainingIdentificationRequests ?? null,
  });
}

function isKnownToken(token: string, env: Env): boolean {
  const allowed = (env.APP_TOKENS ?? "")
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean);
  // Constant-time-ish: compare against each; the set is tiny.
  return allowed.some((t) => timingSafeEqual(t, token));
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}

function parseGbifKey(id: string | undefined): number | null {
  if (!id) return null;
  const n = Number.parseInt(id, 10);
  return Number.isFinite(n) ? n : null;
}

function utcDay(now: Date = new Date()): string {
  return now.toISOString().slice(0, 10); // YYYY-MM-DD
}

async function bumpDailyCount(env: Env, capKey: string, current: number): Promise<void> {
  // KV is eventually consistent, so this counter is approximate — good enough
  // for quota protection, not for billing. Expire ~48h out to self-clean.
  await env.META.put(capKey, String(current + 1), { expirationTtl: 60 * 60 * 48 });
}
