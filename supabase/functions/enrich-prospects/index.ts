// Enrichissement des prospects après une recherche Places :
//   - SIRENE (INSEE)   : SIREN, NAF, date de création, état actif/fermé
//   - PageSpeed (Google): score de performance mobile du site
// Best-effort : chaque échec d'API laisse simplement le prospect
// non enrichi, la recherche n'est jamais bloquée.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { type CompanyInfo, lookupCompanyInfo } from "./finances.ts";
import {
  lookupSirene,
  normalizeForSirene,
  SIRENE_MAX_LOOKUPS,
  type SireneMatch,
} from "./sirene.ts";
import {
  normalizeUrl,
  PAGESPEED_CONCURRENCY,
  PAGESPEED_MAX_SITES,
  runPagespeed,
  runWithConcurrency,
} from "./pagespeed.ts";

const CACHE_TTL_DAYS = 30;
const CACHE_MISS_TTL_DAYS = 7;
const MAX_PROSPECTS = 60;

interface ProspectInput {
  id: string;
  name: string;
  website?: string | null;
}

interface EnrichRequest {
  city: string;
  prospects: ProspectInput[];
}

interface Enrichment {
  siren: string | null;
  siret: string | null;
  naf_code: string | null;
  legal_form: string | null;
  creation_date: string | null;
  active: boolean | null;
  pagespeed_score: number | null;
  manager_name: string | null;
  annual_revenue: number | null;
  annual_revenue_year: number | null;
  net_income: number | null;
}

type CacheRow = { cache_key: string; payload: Record<string, unknown> };

function expiry(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString();
}

// deno-lint-ignore no-explicit-any
async function loadCache(admin: any, keys: string[]) {
  const map = new Map<string, Record<string, unknown>>();
  if (keys.length === 0) return map;
  const { data } = await admin
    .from("enrichment_cache")
    .select("cache_key, payload")
    .in("cache_key", keys)
    .gt("expires_at", new Date().toISOString());
  for (const row of (data ?? []) as CacheRow[]) {
    map.set(row.cache_key, row.payload);
  }
  return map;
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

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return Response.json({ error: "Non authentifié" }, { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const inseeKey = Deno.env.get("INSEE_API_KEY");
    const googleKey = Deno.env.get("GOOGLE_PLACES_API_KEY");

    const userClient = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return Response.json({ error: "Token invalide" }, { status: 401 });
    }

    const body: EnrichRequest = await req.json();
    const city = body.city?.trim();
    const prospects = (body.prospects ?? []).slice(0, MAX_PROSPECTS);
    if (!city || prospects.length === 0) {
      return Response.json(
        { error: "city et prospects requis" },
        { status: 400 },
      );
    }

    const admin = createClient(supabaseUrl, serviceKey);
    const enriched: Record<string, Enrichment> = {};
    for (const p of prospects) {
      enriched[p.id] = {
        siren: null,
        siret: null,
        naf_code: null,
        legal_form: null,
        creation_date: null,
        active: null,
        pagespeed_score: null,
        manager_name: null,
        annual_revenue: null,
        annual_revenue_year: null,
        net_income: null,
      };
    }

    const sireneKey = (p: ProspectInput) =>
      `sirene:${normalizeForSirene(p.name)}|${normalizeForSirene(city)}`;
    const speedKey = (u: string) => `pagespeed:${u}`;

    const wantedKeys = prospects.map(sireneKey);
    for (const p of prospects) {
      const u = p.website ? normalizeUrl(p.website) : null;
      if (u) wantedKeys.push(speedKey(u));
    }
    const cache = await loadCache(admin, [...new Set(wantedKeys)]);
    const newRows: Array<Record<string, unknown>> = [];

    // --- SIRENE : cache d'abord, puis appels API plafonnés -----------------
    let sireneCalls = 0;
    if (inseeKey) {
      const tasks = prospects.map((p) => async () => {
        const key = sireneKey(p);
        const hit = cache.get(key);
        let match: SireneMatch | null;
        if (hit) {
          match = (hit.found ? hit.match : null) as SireneMatch | null;
        } else {
          if (sireneCalls >= SIRENE_MAX_LOOKUPS) return;
          sireneCalls++;
          match = await lookupSirene(inseeKey, p.name, city);
          newRows.push({
            cache_key: key,
            payload: { found: match != null, match },
            expires_at: expiry(match ? CACHE_TTL_DAYS : CACHE_MISS_TTL_DAYS),
          });
        }
        if (match) Object.assign(enriched[p.id], match);
      });
      await runWithConcurrency(tasks, 3);
    }

    // --- Dirigeant + finances (API Recherche d'entreprises, par SIREN) -----
    const sirens = [
      ...new Set(
        Object.values(enriched)
          .map((e) => e.siren)
          .filter((s): s is string => s != null),
      ),
    ];
    if (sirens.length > 0) {
      // Les SIREN ne sont connus qu'après la phase SIRENE : second
      // chargement de cache dédié aux clés company:*.
      const companyCache = await loadCache(
        admin,
        sirens.map((s) => `company:${s}`),
      );
      const infoBySiren = new Map<string, CompanyInfo | null>();
      const tasks = sirens.map((siren) => async () => {
        const key = `company:${siren}`;
        const hit = companyCache.get(key);
        if (hit) {
          infoBySiren.set(
            siren,
            (hit.found ? hit.info : null) as CompanyInfo | null,
          );
          return;
        }
        const info = await lookupCompanyInfo(siren);
        infoBySiren.set(siren, info);
        newRows.push({
          cache_key: key,
          payload: { found: info != null, info },
          expires_at: expiry(info ? CACHE_TTL_DAYS : CACHE_MISS_TTL_DAYS),
        });
      });
      await runWithConcurrency(tasks, 3);
      for (const e of Object.values(enriched)) {
        const info = e.siren ? infoBySiren.get(e.siren) : null;
        if (info) Object.assign(e, info);
      }
    }

    // --- PageSpeed : sites uniquement, plafonné ----------------------------
    let speedCalls = 0;
    if (googleKey) {
      const withSite = prospects
        .map((p) => ({ p, url: p.website ? normalizeUrl(p.website) : null }))
        .filter((x): x is { p: ProspectInput; url: string } => x.url != null);
      const tasks = withSite.map(({ p, url }) => async () => {
        const key = speedKey(url);
        const hit = cache.get(key);
        let score: number | null;
        if (hit) {
          score = (hit.score as number | null) ?? null;
        } else {
          if (speedCalls >= PAGESPEED_MAX_SITES) return;
          speedCalls++;
          score = await runPagespeed(googleKey, p.website!);
          newRows.push({
            cache_key: key,
            payload: { score },
            expires_at: expiry(
              score != null ? CACHE_TTL_DAYS : CACHE_MISS_TTL_DAYS,
            ),
          });
          cache.set(key, { score }); // même URL partagée entre prospects
        }
        enriched[p.id].pagespeed_score = score;
      });
      await runWithConcurrency(tasks, PAGESPEED_CONCURRENCY);
    }

    // Dédoublonnage : deux prospects homonymes produiraient la même clé,
    // ce que l'upsert Postgres rejette dans un même lot.
    const seen = new Set<string>();
    const rows = newRows.filter((r) => {
      const key = r.cache_key as string;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
    if (rows.length > 0) {
      await admin
        .from("enrichment_cache")
        .upsert(rows, { onConflict: "cache_key" });
    }

    return Response.json({
      enriched,
      sireneEnabled: Boolean(inseeKey),
      pagespeedEnabled: Boolean(googleKey),
      sireneCalls,
      pagespeedCalls: speedCalls,
    });
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 502 });
  }
});
