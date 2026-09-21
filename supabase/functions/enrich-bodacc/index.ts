// Enrichissement BODACC différé (C4.1 / pipeline Phase 2).
// Best-effort : une erreur n'échoue jamais la campagne appelante.
// HTTP + auth + ownership ici ; logique métier dans `_shared/enrichment`.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  createBodaccProvider,
  BODACC_CONCURRENCY,
  BODACC_CACHE_MISS_TTL_DAYS,
  BODACC_CACHE_TTL_DAYS,
  BODACC_MAX_PROSPECTS,
  cacheExpiryIso,
  cacheKey,
  normalizeSiren,
  persistBodaccResult,
  type BodaccCacheAccess,
  type BodaccRawRecord,
  type SignalKey,
} from "../_shared/enrichment/bodacc/mod.ts";
import { runWithConcurrency } from "../_shared/enrichment/concurrency.ts";
import { runSingleProvider } from "../_shared/enrichment/pipeline.ts";
import type { EnrichmentContext } from "../_shared/enrichment/types.ts";
import {
  classifyError,
  nowMs,
  recordMetric,
} from "../_shared/metrics.ts";

interface ProspectInput {
  id: string;
  siren: string;
  /** false = SIRENE indique fermé / inactif. */
  sireneActive?: boolean | null;
}

interface BodaccRequest {
  prospects: ProspectInput[];
  forceRefresh?: boolean;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  const started = nowMs();
  // deno-lint-ignore no-explicit-any
  let admin: any = null;
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return Response.json({ error: "Non authentifié" }, { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const userClient = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return Response.json({ error: "Token invalide" }, { status: 401 });
    }
    const userId = userData.user.id;

    const body: BodaccRequest = await req.json();
    const forceRefresh = body.forceRefresh === true;
    const incoming = (body.prospects ?? []).slice(0, BODACC_MAX_PROSPECTS);
    if (incoming.length === 0) {
      return Response.json({ error: "prospects requis" }, { status: 400 });
    }

    admin = createClient(supabaseUrl, serviceKey);

    const ids = incoming.map((p) => p.id);
    const { data: ownedRows } = await admin
      .from("prospects")
      .select("id, campaign_id, campaigns!inner(user_id)")
      .in("id", ids)
      .eq("campaigns.user_id", userId);
    const ownedIds = new Set(
      ((ownedRows ?? []) as Array<{ id: string }>).map((r) => r.id),
    );

    const targets = incoming
      .map((p) => ({
        ...p,
        siren: normalizeSiren(p.siren) ?? "",
      }))
      .filter((p) => p.siren.length === 9 && ownedIds.has(p.id));

    if (targets.length === 0) {
      return Response.json({
        enriched: {},
        processed: 0,
        skipped: incoming.length,
      });
    }

    const keys = [...new Set(targets.map((t) => cacheKey(t.siren)))];
    const cacheMap = new Map<string, Record<string, unknown>>();
    if (!forceRefresh) {
      const { data: cacheRows } = await admin
        .from("enrichment_cache")
        .select("cache_key, payload, expires_at")
        .in("cache_key", keys)
        .gt("expires_at", new Date().toISOString());
      for (const row of cacheRows ?? []) {
        cacheMap.set(
          row.cache_key as string,
          row.payload as Record<string, unknown>,
        );
      }
    }

    const cacheUpserts: Array<Record<string, unknown>> = [];
    const cacheAccess: BodaccCacheAccess = {
      getRecords(siren: string): BodaccRawRecord[] | null {
        const hit = cacheMap.get(cacheKey(siren));
        if (hit && Array.isArray(hit.records)) {
          return hit.records as BodaccRawRecord[];
        }
        return null;
      },
      scheduleUpsert({ siren, records, totalCount, fetchedAt }) {
        const key = cacheKey(siren);
        cacheUpserts.push({
          cache_key: key,
          payload: {
            records,
            total_count: totalCount,
            fetched_at: fetchedAt,
          },
          expires_at: cacheExpiryIso(
            records.length > 0
              ? BODACC_CACHE_TTL_DAYS
              : BODACC_CACHE_MISS_TTL_DAYS,
          ),
        });
        cacheMap.set(key, { records });
      },
    };

    const provider = createBodaccProvider({ cache: cacheAccess });

    const enriched: Record<string, Record<string, unknown>> = {};
    let cacheHits = 0;
    let apiOk = 0;
    let apiFail = 0;
    let emptyCount = 0;
    let parseErrors = 0;
    let eventsProcessed = 0;
    const familyCounts = new Map<string, number>();

    const tasks = targets.map((p) => async () => {
      const ctx: EnrichmentContext = {
        prospectId: p.id,
        knownData: {
          siren: p.siren,
          sireneActive: p.sireneActive,
        },
        options: {
          forceRefresh,
          enabledProviders: ["bodacc"],
        },
      };

      const result = await runSingleProvider(provider, ctx);

      if (result.status === "skipped") return;

      if (result.status === "failed") {
        if (result.error?.type === "parse") parseErrors++;
        else apiFail++;
        return;
      }

      if (result.metadata?.cacheStatus === "hit") cacheHits++;
      else apiOk++;

      if (result.data.no_results === true) emptyCount++;

      const events = (result.data.events ?? []) as Array<{
        signal_key: string;
      }>;
      for (const ev of events) {
        if (ev.signal_key === "unclassified") continue;
        eventsProcessed++;
        const fam = ev.signal_key as SignalKey;
        familyCounts.set(fam, (familyCounts.get(fam) ?? 0) + 1);
      }

      const payload = await persistBodaccResult(admin, p.id, result);
      if (payload) enriched[p.id] = payload;
    });

    await runWithConcurrency(tasks, BODACC_CONCURRENCY);

    if (cacheUpserts.length > 0) {
      const seen = new Set<string>();
      const rows = cacheUpserts.filter((r) => {
        const k = r.cache_key as string;
        if (seen.has(k)) return false;
        seen.add(k);
        return true;
      });
      await admin.from("enrichment_cache").upsert(rows, {
        onConflict: "cache_key",
      });
    }

    const durationMs = nowMs() - started;
    if (cacheHits > 0) {
      await recordMetric(admin, {
        source: "bodacc",
        status: "cache_hit",
        count: cacheHits,
        durationMs,
      });
    }
    if (apiOk > 0) {
      await recordMetric(admin, {
        source: "bodacc",
        status: "success",
        count: apiOk,
        durationMs,
      });
    }
    if (apiFail > 0) {
      await recordMetric(admin, {
        source: "bodacc",
        status: "failure",
        errorType: "other",
        count: apiFail,
        durationMs,
      });
    }
    if (emptyCount > 0) {
      await recordMetric(admin, {
        source: "bodacc",
        status: "success",
        errorType: "empty",
        count: emptyCount,
        durationMs,
      });
    }
    if (parseErrors > 0) {
      await recordMetric(admin, {
        source: "bodacc",
        status: "failure",
        errorType: "parse",
        count: parseErrors,
        durationMs,
      });
    }
    if (eventsProcessed > 0) {
      await recordMetric(admin, {
        source: "bodacc",
        status: "success",
        errorType: "events",
        count: eventsProcessed,
        durationMs,
      });
    }
    for (const [family, count] of familyCounts) {
      await recordMetric(admin, {
        source: "bodacc",
        status: "success",
        errorType: `family:${family}`,
        count,
        durationMs,
      });
    }

    return Response.json({
      enriched,
      processed: Object.keys(enriched).length,
      skipped: incoming.length - targets.length,
      stats: {
        cacheHits,
        apiOk,
        apiFail,
        emptyCount,
        parseErrors,
        eventsProcessed,
      },
    });
  } catch (e) {
    if (admin) {
      await recordMetric(admin, {
        source: "bodacc",
        status: "failure",
        errorType: classifyError(e),
        durationMs: nowMs() - started,
      });
    }
    return Response.json({ error: String(e) }, { status: 502 });
  }
});
