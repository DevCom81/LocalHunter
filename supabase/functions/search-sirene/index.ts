// Discovery SIRENE — coquille HTTP (Phase 9).
// Auth + métriques ; logique dans `_shared/enrichment/sirene_discovery`.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsJson, corsPreflight } from "../_shared/cors.ts";
import { searchSireneDiscovery } from "../_shared/enrichment/sirene_discovery/mod.ts";
import {
  classifyError,
  nowMs,
  recordMetric,
} from "../_shared/metrics.ts";

interface SearchRequest {
  city: string;
  sector: string;
  radiusKm?: number;
  maxResults?: number;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return corsPreflight();
  }

  const started = nowMs();
  // deno-lint-ignore no-explicit-any
  let admin: any = null;
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return corsJson({ error: "Non authentifié" }, { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userError } = await userClient.auth
      .getUser();
    if (userError || !userData.user) {
      return corsJson({ error: "Token invalide" }, { status: 401 });
    }

    const body: SearchRequest = await req.json();
    const city = body.city?.trim();
    const sector = body.sector?.trim() ?? "entreprise";
    if (!city) {
      return corsJson({ error: "city requis" }, { status: 400 });
    }

    admin = createClient(supabaseUrl, serviceKey);
    const prospects = await searchSireneDiscovery({
      city,
      sector,
      maxResults: body.maxResults ?? 20,
    });

    await recordMetric(admin, {
      source: "sirene",
      status: "success",
      durationMs: nowMs() - started,
    });

    return corsJson({
      prospects,
      fromCache: false,
      count: prospects.length,
    });
  } catch (e) {
    if (admin) {
      await recordMetric(admin, {
        source: "sirene",
        status: "failure",
        errorType: classifyError(e),
        durationMs: nowMs() - started,
      });
    }
    return corsJson({ error: String(e) }, { status: 502 });
  }
});
