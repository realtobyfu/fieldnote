// Fieldnote backend Worker — entrypoint.
//
//   2A  POST /v1/identify            — Pl@ntNet proxy (see identify.ts)
//   2B  GET  /v1/regions             — region index (see delivery.ts)
//   2B  GET  /v1/regions/{regionID}  — region pack
//   2B  cron                         — weekly region-pack rebuild (see pipeline.ts)

import type { Env } from "./types";
import { handleIdentify } from "./identify";
import { handleRegionsIndex, handleRegionPack } from "./delivery";
import { runPipeline } from "./pipeline";
import { errorResponse, json } from "./http";

export default {
  async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, ""); // strip trailing slash

    if (path === "/v1/health") {
      return json({ ok: true });
    }

    if (path === "/v1/identify") {
      return handleIdentify(request, env);
    }

    if (path === "/v1/regions") {
      if (request.method !== "GET") return errorResponse(405, "method_not_allowed", "Use GET.");
      return handleRegionsIndex(env);
    }

    const regionMatch = /^\/v1\/regions\/([A-Za-z0-9_-]+)$/.exec(path);
    if (regionMatch) {
      if (request.method !== "GET") return errorResponse(405, "method_not_allowed", "Use GET.");
      return handleRegionPack(regionMatch[1]!, request, env);
    }

    return errorResponse(404, "not_found", "No such route.");
  },

  async scheduled(_event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(runPipeline(env));
  },
};
