// Enrichissement des prospects après une recherche Places :
//   - SIRENE (INSEE)   : SIREN, NAF, date de création, état actif/fermé
//   - PageSpeed (Google): score de performance mobile du site
// Best-effort : chaque échec d'API laisse simplement le prospect
// non enrichi, la recherche n'est jamais bloquée.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  classifyError,
  nowMs,
  recordMetric,
} from "../_shared/metrics.ts";
import {
  createSireneProvider,
  SIRENE_CACHE_MISS_TTL_DAYS,
  SIRENE_CACHE_TTL_DAYS,
  SIRENE_MAX_LOOKUPS,
  sireneCacheKey,
  type SireneCacheAccess,
  type SireneCachePayload,
  type SireneMatch,
} from "../_shared/enrichment/sirene/mod.ts";
import { runSingleProvider } from "../_shared/enrichment/pipeline.ts";
import type { EnrichmentContext } from "../_shared/enrichment/types.ts";
import {
  COMPANY_CACHE_MISS_TTL_DAYS,
  COMPANY_CACHE_TTL_DAYS,
  COMPANY_CONCURRENCY,
  companyCacheKey,
  createCompanyProvider,
  type CompanyCacheAccess,
  type CompanyCachePayload,
  type CompanyInfo,
} from "../_shared/enrichment/company/mod.ts";
import {
  createPagespeedProvider,
  normalizeUrl,
  PAGESPEED_CACHE_MISS_TTL_DAYS,
  PAGESPEED_CACHE_TTL_DAYS,
  PAGESPEED_CONCURRENCY,
  PAGESPEED_MAX_SITES,
  pagespeedCacheKey,
  runWithConcurrency,
  type PagespeedCacheAccess,
  type PagespeedCachePayload,
} from "../_shared/enrichment/pagespeed/mod.ts";
import {
  createWebsiteProvider,
  WEBSITE_CACHE_MISS_TTL_DAYS,
  WEBSITE_CACHE_TTL_DAYS,
  WEBSITE_CONCURRENCY,
  WEBSITE_MAX_SITES,
  websiteCacheKey,
  websiteCountsAsApiFailure,
  type WebsiteCacheAccess,
  type WebsiteCachePayload,
} from "../_shared/enrichment/website/mod.ts";
import { cacheExpiryIso } from "../_shared/enrichment/cache_ttl.ts";

const MAX_PROSPECTS = 60;

interface ProspectInput {
  id: string;
  name: string;
  website?: string | null;
}

interface EnrichRequest {
  city: string;
  prospects: ProspectInput[];
  /** Phase 3 : si absent/vide → comportement historique (tous les providers). */
  enabledProviders?: string[];
}

/** true si le provider doit tourner (défaut = tout actif). */
function providerEnabled(
  enabled: string[] | undefined,
  id: string,
): boolean {
  if (enabled == null || enabled.length === 0) return true;
  return enabled.includes(id);
}

interface Enrichment {
  siren: string | null;
  siret: string | null;
  naf_code: string | null;
  legal_form: string | null;
  creation_date: string | null;
  active: boolean | null;
  match_score: number | null;
  match_ambiguous: boolean | null;
  pagespeed_score: number | null;
  website_reachable: boolean | null;
  website_https: boolean | null;
  website_http_status: number | null;
  website_title: string | null;
  website_has_viewport: boolean | null;
  manager_name: string | null;
  annual_revenue: number | null;
  annual_revenue_year: number | null;
  net_income: number | null;
  employee_count: number | null;
  establishment_count: number | null;
  social_checked: boolean | null;
  facebook_url: string | null;
  instagram_url: string | null;
  linkedin_url: string | null;
  tiktok_url: string | null;
  youtube_url: string | null;
  x_url: string | null;
}

type CacheRow = { cache_key: string; payload: Record<string, unknown> };

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
    const enabled = body.enabledProviders;
    const runSirene = providerEnabled(enabled, "sirene");
    const runCompany = providerEnabled(enabled, "company");
    const runSocial = providerEnabled(enabled, "social");
    const runWebsite =
      providerEnabled(enabled, "website") || runSocial;
    const runPagespeed = providerEnabled(enabled, "pagespeed");

    admin = createClient(supabaseUrl, serviceKey);
    const enriched: Record<string, Enrichment> = {};
    for (const p of prospects) {
      enriched[p.id] = {
        siren: null,
        siret: null,
        naf_code: null,
        legal_form: null,
        creation_date: null,
        active: null,
        match_score: null,
        match_ambiguous: null,
        pagespeed_score: null,
        website_reachable: null,
        website_https: null,
        website_http_status: null,
        website_title: null,
        website_has_viewport: null,
        manager_name: null,
        annual_revenue: null,
        annual_revenue_year: null,
        net_income: null,
        employee_count: null,
        establishment_count: null,
        social_checked: null,
        facebook_url: null,
        instagram_url: null,
        linkedin_url: null,
        tiktok_url: null,
        youtube_url: null,
        x_url: null,
      };
    }

    const sireneKey = (p: ProspectInput) => sireneCacheKey(p.name, city);
    const speedKey = (u: string) => pagespeedCacheKey(u);
    const websiteKey = (u: string) => websiteCacheKey(u, runSocial);

    const wantedKeys: string[] = [];
    if (runSirene) {
      for (const p of prospects) wantedKeys.push(sireneKey(p));
    }
    for (const p of prospects) {
      const u = p.website ? normalizeUrl(p.website) : null;
      if (!u) continue;
      if (runPagespeed) wantedKeys.push(speedKey(u));
      if (runWebsite) wantedKeys.push(websiteKey(u));
    }
    const cache = await loadCache(admin, [...new Set(wantedKeys)]);
    const newRows: Array<Record<string, unknown>> = [];

    // --- SIRENE : provider partagé (cache + plafond) -----------------------
    let sireneCalls = 0;
    let sireneCacheHits = 0;
    let sireneApiOk = 0;
    let sireneApiFail = 0;
    let sireneSkip = 0;
    const sireneStarted = nowMs();
    if (runSirene && inseeKey) {
      const callBudget = { remaining: SIRENE_MAX_LOOKUPS };
      const sireneCache: SireneCacheAccess = {
        get(cacheKey: string): SireneCachePayload | null {
          const hit = cache.get(cacheKey);
          if (!hit) return null;
          return {
            found: Boolean(hit.found),
            match: (hit.found ? hit.match : null) as SireneMatch | null,
          };
        },
        scheduleUpsert({ cacheKey, found, match }) {
          const payload = { found, match };
          newRows.push({
            cache_key: cacheKey,
            payload,
            expires_at: cacheExpiryIso(
              found ? SIRENE_CACHE_TTL_DAYS : SIRENE_CACHE_MISS_TTL_DAYS,
            ),
          });
          cache.set(cacheKey, payload as unknown as Record<string, unknown>);
        },
      };
      const provider = createSireneProvider({
        apiKey: inseeKey,
        cache: sireneCache,
        callBudget,
      });
      const initialBudget = SIRENE_MAX_LOOKUPS;
      const tasks = prospects.map((p) => async () => {
        const ctx: EnrichmentContext = {
          prospectId: p.id,
          knownData: { name: p.name, city },
          options: { enabledProviders: ["sirene"] },
        };
        const result = await runSingleProvider(provider, ctx);
        if (result.status === "skipped") {
          sireneSkip++;
          return;
        }
        if (result.status === "failed") {
          sireneApiFail++;
          return;
        }
        if (result.metadata?.cacheStatus === "hit") {
          sireneCacheHits++;
        } else {
          sireneApiOk++;
        }
        const match = (result.data.match ?? null) as SireneMatch | null;
        if (match) Object.assign(enriched[p.id], match);
      });
      await runWithConcurrency(tasks, 3);
      sireneCalls = initialBudget - callBudget.remaining;
    } else if (runSirene) {
      sireneSkip = prospects.length;
    }
    const sireneDuration = nowMs() - sireneStarted;
    if (sireneCacheHits > 0) {
      await recordMetric(admin, {
        source: "sirene",
        status: "cache_hit",
        count: sireneCacheHits,
        durationMs: sireneDuration,
      });
    }
    if (sireneApiOk > 0) {
      await recordMetric(admin, {
        source: "sirene",
        status: "success",
        count: sireneApiOk,
        durationMs: sireneDuration,
      });
    }
    if (sireneApiFail > 0) {
      await recordMetric(admin, {
        source: "sirene",
        status: "failure",
        errorType: "other",
        count: sireneApiFail,
        durationMs: sireneDuration,
      });
    }
    if (sireneSkip > 0) {
      await recordMetric(admin, {
        source: "sirene",
        status: "skip",
        errorType: inseeKey ? "cap" : "disabled",
        count: sireneSkip,
        durationMs: sireneDuration,
      });
    }

    // --- Company / finances : provider partagé (par SIREN unique) ----------
    const sirens = [
      ...new Set(
        Object.values(enriched)
          .map((e) => e.siren)
          .filter((s): s is string => s != null),
      ),
    ];
    let companyCacheHits = 0;
    let companyApiOk = 0;
    let companyApiFail = 0;
    const companyStarted = nowMs();
    if (runCompany && sirens.length > 0) {
      const companyCacheMap = await loadCache(
        admin,
        sirens.map((s) => companyCacheKey(s)),
      );
      const companyCache: CompanyCacheAccess = {
        get(cacheKey: string): CompanyCachePayload | null {
          const hit = companyCacheMap.get(cacheKey);
          if (!hit) return null;
          return {
            found: Boolean(hit.found),
            info: (hit.found ? hit.info : null) as CompanyInfo | null,
          };
        },
        scheduleUpsert({ cacheKey, found, info }) {
          const payload = { found, info };
          newRows.push({
            cache_key: cacheKey,
            payload,
            expires_at: cacheExpiryIso(
              found ? COMPANY_CACHE_TTL_DAYS : COMPANY_CACHE_MISS_TTL_DAYS,
            ),
          });
          companyCacheMap.set(
            cacheKey,
            payload as unknown as Record<string, unknown>,
          );
        },
      };
      const provider = createCompanyProvider({ cache: companyCache });
      const infoBySiren = new Map<string, CompanyInfo | null>();
      const tasks = sirens.map((siren) => async () => {
        const ctx: EnrichmentContext = {
          prospectId: `company:${siren}`,
          knownData: { siren },
          options: { enabledProviders: ["company"] },
        };
        const result = await runSingleProvider(provider, ctx);
        if (result.status === "skipped") return;
        if (result.status === "failed") {
          companyApiFail++;
          infoBySiren.set(siren, null);
          return;
        }
        if (result.metadata?.cacheStatus === "hit") {
          companyCacheHits++;
        } else {
          companyApiOk++;
        }
        infoBySiren.set(
          siren,
          (result.data.info ?? null) as CompanyInfo | null,
        );
      });
      await runWithConcurrency(tasks, COMPANY_CONCURRENCY);
      for (const e of Object.values(enriched)) {
        const info = e.siren ? infoBySiren.get(e.siren) : null;
        if (info) Object.assign(e, info);
      }
    }
    const companyDuration = nowMs() - companyStarted;
    if (companyCacheHits > 0) {
      await recordMetric(admin, {
        source: "company",
        status: "cache_hit",
        count: companyCacheHits,
        durationMs: companyDuration,
      });
    }
    if (companyApiOk > 0) {
      await recordMetric(admin, {
        source: "company",
        status: "success",
        count: companyApiOk,
        durationMs: companyDuration,
      });
    }
    if (companyApiFail > 0) {
      await recordMetric(admin, {
        source: "company",
        status: "failure",
        errorType: "other",
        count: companyApiFail,
        durationMs: companyDuration,
      });
    }

    // --- Analyse site légère (C3) : provider partagé, avant PageSpeed ------
    let websiteCalls = 0;
    let websiteCacheHits = 0;
    let websiteApiOk = 0;
    let websiteApiFail = 0;
    let websiteSkip = 0;
    const websiteStarted = nowMs();
    const withSite = prospects
      .map((p) => ({ p, url: p.website ? normalizeUrl(p.website) : null }))
      .filter((x): x is { p: ProspectInput; url: string } => x.url != null);
    if (runWebsite && withSite.length > 0) {
      const callBudget = { remaining: WEBSITE_MAX_SITES };
      const websiteCache: WebsiteCacheAccess = {
        get(cacheKey: string): WebsiteCachePayload | null {
          const hit = cache.get(cacheKey);
          if (!hit || typeof hit.reachable !== "boolean") return null;
          return {
            reachable: hit.reachable as boolean,
            https: (hit.https as boolean | null) ?? null,
            http_status: (hit.http_status as number | null) ?? null,
            title: (hit.title as string | null) ?? null,
            has_viewport: (hit.has_viewport as boolean | null) ?? null,
            social: (hit.social as WebsiteCachePayload["social"]) ?? null,
          };
        },
        scheduleUpsert({ cacheKey, analysis }) {
          const payload = {
            reachable: analysis.reachable,
            https: analysis.https,
            http_status: analysis.http_status,
            title: analysis.title,
            has_viewport: analysis.has_viewport,
            social: analysis.social ?? null,
          };
          newRows.push({
            cache_key: cacheKey,
            payload,
            expires_at: cacheExpiryIso(
              analysis.reachable
                ? WEBSITE_CACHE_TTL_DAYS
                : WEBSITE_CACHE_MISS_TTL_DAYS,
            ),
          });
          cache.set(cacheKey, payload as unknown as Record<string, unknown>);
        },
      };
      const provider = createWebsiteProvider({
        cache: websiteCache,
        callBudget,
      });
      const initialBudget = WEBSITE_MAX_SITES;
      const websiteProviders = runSocial
        ? ["website", "social"]
        : ["website"];
      const tasks = withSite.map(({ p }) => async () => {
        const ctx: EnrichmentContext = {
          prospectId: p.id,
          knownData: { websiteUrl: p.website },
          options: { enabledProviders: websiteProviders },
        };
        const result = await runSingleProvider(provider, ctx);
        if (result.status === "skipped") {
          websiteSkip++;
          return;
        }
        if (result.status === "failed") {
          websiteApiFail++;
          return;
        }
        if (result.metadata?.cacheStatus === "hit") {
          websiteCacheHits++;
        } else {
          const errType = result.data.error_type as string | undefined;
          if (websiteCountsAsApiFailure(errType ?? undefined)) {
            websiteApiFail++;
          } else {
            websiteApiOk++;
          }
        }
        enriched[p.id].website_reachable =
          (result.data.website_reachable as boolean | null) ?? null;
        enriched[p.id].website_https =
          (result.data.website_https as boolean | null) ?? null;
        enriched[p.id].website_http_status =
          (result.data.website_http_status as number | null) ?? null;
        enriched[p.id].website_title =
          (result.data.website_title as string | null) ?? null;
        enriched[p.id].website_has_viewport =
          (result.data.website_has_viewport as boolean | null) ?? null;
        if (runSocial && result.data.social_checked === true) {
          enriched[p.id].social_checked = true;
          enriched[p.id].facebook_url =
            (result.data.facebook_url as string | null) ?? null;
          enriched[p.id].instagram_url =
            (result.data.instagram_url as string | null) ?? null;
          enriched[p.id].linkedin_url =
            (result.data.linkedin_url as string | null) ?? null;
          enriched[p.id].tiktok_url =
            (result.data.tiktok_url as string | null) ?? null;
          enriched[p.id].youtube_url =
            (result.data.youtube_url as string | null) ?? null;
          enriched[p.id].x_url = (result.data.x_url as string | null) ?? null;
        }
      });
      await runWithConcurrency(tasks, WEBSITE_CONCURRENCY);
      websiteCalls = initialBudget - callBudget.remaining;
    }
    const websiteDuration = nowMs() - websiteStarted;
    if (websiteCacheHits > 0) {
      await recordMetric(admin, {
        source: "website",
        status: "cache_hit",
        count: websiteCacheHits,
        durationMs: websiteDuration,
      });
    }
    if (websiteApiOk > 0) {
      await recordMetric(admin, {
        source: "website",
        status: "success",
        count: websiteApiOk,
        durationMs: websiteDuration,
      });
    }
    if (websiteApiFail > 0) {
      await recordMetric(admin, {
        source: "website",
        status: "failure",
        errorType: "other",
        count: websiteApiFail,
        durationMs: websiteDuration,
      });
    }
    if (websiteSkip > 0) {
      await recordMetric(admin, {
        source: "website",
        status: "skip",
        errorType: "cap",
        count: websiteSkip,
        durationMs: websiteDuration,
      });
    }

    // --- PageSpeed : provider partagé, plafonné ----------------------------
    let speedCalls = 0;
    let speedCacheHits = 0;
    let speedApiOk = 0;
    let speedApiFail = 0;
    let speedSkip = 0;
    const speedStarted = nowMs();
    if (runPagespeed && googleKey) {
      const callBudget = { remaining: PAGESPEED_MAX_SITES };
      const pagespeedCache: PagespeedCacheAccess = {
        get(cacheKey: string): PagespeedCachePayload | null {
          const hit = cache.get(cacheKey);
          if (!hit) return null;
          return {
            score: (hit.score as number | null) ?? null,
          };
        },
        scheduleUpsert({ cacheKey, score }) {
          const payload = { score };
          newRows.push({
            cache_key: cacheKey,
            payload,
            expires_at: cacheExpiryIso(
              score != null
                ? PAGESPEED_CACHE_TTL_DAYS
                : PAGESPEED_CACHE_MISS_TTL_DAYS,
            ),
          });
          cache.set(cacheKey, payload as unknown as Record<string, unknown>);
        },
      };
      const provider = createPagespeedProvider({
        apiKey: googleKey,
        cache: pagespeedCache,
        callBudget,
      });
      const initialBudget = PAGESPEED_MAX_SITES;
      const tasks = withSite.map(({ p }) => async () => {
        const ctx: EnrichmentContext = {
          prospectId: p.id,
          knownData: {
            websiteUrl: p.website,
            websiteReachable: enriched[p.id].website_reachable,
          },
          options: { enabledProviders: ["pagespeed"] },
        };
        const result = await runSingleProvider(provider, ctx);
        if (result.status === "skipped") {
          speedSkip++;
          return;
        }
        if (result.status === "failed") {
          speedApiFail++;
          enriched[p.id].pagespeed_score =
            (result.data.pagespeed_score as number | null) ?? null;
          return;
        }
        if (result.metadata?.cacheStatus === "hit") {
          speedCacheHits++;
        } else {
          speedApiOk++;
        }
        enriched[p.id].pagespeed_score =
          (result.data.pagespeed_score as number | null) ?? null;
      });
      await runWithConcurrency(tasks, PAGESPEED_CONCURRENCY);
      speedCalls = initialBudget - callBudget.remaining;
    } else {
      speedSkip = withSite.length;
    }
    const speedDuration = nowMs() - speedStarted;
    if (speedCacheHits > 0) {
      await recordMetric(admin, {
        source: "pagespeed",
        status: "cache_hit",
        count: speedCacheHits,
        durationMs: speedDuration,
      });
    }
    if (speedApiOk > 0) {
      await recordMetric(admin, {
        source: "pagespeed",
        status: "success",
        count: speedApiOk,
        durationMs: speedDuration,
      });
    }
    if (speedApiFail > 0) {
      await recordMetric(admin, {
        source: "pagespeed",
        status: "failure",
        errorType: "other",
        count: speedApiFail,
        durationMs: speedDuration,
      });
    }
    if (speedSkip > 0) {
      await recordMetric(admin, {
        source: "pagespeed",
        status: "skip",
        errorType: googleKey ? "cap" : "disabled",
        count: speedSkip,
        durationMs: speedDuration,
      });
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

    await recordMetric(admin, {
      source: "enrichment",
      status: "success",
      durationMs: nowMs() - started,
    });
    return Response.json({
      enriched,
      sireneEnabled: Boolean(inseeKey),
      pagespeedEnabled: Boolean(googleKey),
      sireneCalls,
      pagespeedCalls: speedCalls,
      websiteCalls,
    });
  } catch (e) {
    if (admin) {
      await recordMetric(admin, {
        source: "enrichment",
        status: "failure",
        errorType: classifyError(e),
        durationMs: nowMs() - started,
      });
    }
    return Response.json({ error: String(e) }, { status: 502 });
  }
});
