import { normalizeUrl } from "../pagespeed/client.ts";
import type { EnrichmentProvider } from "../provider.ts";
import { shouldEmitSignal } from "../run_provider.ts";
import type {
  EnrichmentContext,
  EnrichmentSignal,
  ProviderEnrichmentResult,
} from "../types.ts";
import {
  analyzeWebsite,
  cacheExpiryIso,
  WEBSITE_CACHE_MISS_TTL_DAYS,
  WEBSITE_CACHE_TTL_DAYS,
  websiteCacheKey,
  type WebsiteAnalysis,
} from "./client.ts";
import type { SocialLinks } from "./social_links.ts";

export type WebsiteCachePayload = Pick<
  WebsiteAnalysis,
  "reachable" | "https" | "http_status" | "title" | "has_viewport"
> & { social?: SocialLinks | null };

export interface WebsiteCacheAccess {
  get(cacheKey: string): WebsiteCachePayload | null;
  scheduleUpsert(args: {
    cacheKey: string;
    analysis: WebsiteCachePayload;
    fetchedAt: string;
  }): void;
}

export interface WebsiteCallBudget {
  remaining: number;
}

export interface WebsiteProviderDeps {
  cache: WebsiteCacheAccess;
  callBudget: WebsiteCallBudget;
  analyzeFn?: typeof analyzeWebsite;
}

function nowIso(): string {
  return new Date().toISOString();
}

function wantsSocial(ctx: EnrichmentContext): boolean {
  const list = ctx.options.enabledProviders;
  if (!list || list.length === 0) return false;
  return list.includes("social");
}

function toSignals(
  analysis: WebsiteAnalysis,
  fetchedAt: string,
  includeSocial: boolean,
): EnrichmentSignal[] {
  const out: EnrichmentSignal[] = [];
  const conf = analysis.reachable === true ? 0.85 : 0.5;
  const push = (
    key: string,
    value: string | number | boolean | null,
    category: EnrichmentSignal["category"] = "digital_presence",
    confidence = conf,
  ) => {
    if (!shouldEmitSignal(value)) return;
    out.push({
      key,
      category,
      value,
      source: "website",
      confidence,
      observedAt: fetchedAt,
    });
  };

  push("website_reachable", analysis.reachable);
  push("website_https", analysis.https);
  push("website_http_status", analysis.http_status);
  push("website_title", analysis.title);
  push("website_has_viewport", analysis.has_viewport);

  if (includeSocial && analysis.social) {
    const sConf = 0.75;
    push(
      "social_presence_detected",
      analysis.social.social_presence_detected,
      "digital_presence",
      sConf,
    );
    push(
      "social_network_count",
      analysis.social.social_network_count,
      "digital_presence",
      sConf,
    );
    push("facebook_url", analysis.social.facebook_url, "digital_presence", sConf);
    push("instagram_url", analysis.social.instagram_url, "digital_presence", sConf);
    push("linkedin_url", analysis.social.linkedin_url, "digital_presence", sConf);
    push("tiktok_url", analysis.social.tiktok_url, "digital_presence", sConf);
    push("youtube_url", analysis.social.youtube_url, "digital_presence", sConf);
    push("x_url", analysis.social.x_url, "digital_presence", sConf);
  }
  return out;
}

function successResult(
  analysis: WebsiteAnalysis,
  cacheStatus: "hit" | "miss" | "bypass",
  fetchedAt: string,
  includeSocial: boolean,
): ProviderEnrichmentResult {
  const data: Record<string, unknown> = {
    reachable: analysis.reachable,
    https: analysis.https,
    http_status: analysis.http_status,
    title: analysis.title,
    has_viewport: analysis.has_viewport,
    error_type: analysis.error_type ?? null,
    website_reachable: analysis.reachable,
    website_https: analysis.https,
    website_http_status: analysis.http_status,
    website_title: analysis.title,
    website_has_viewport: analysis.has_viewport,
  };
  if (includeSocial) {
    const s = analysis.social;
    data.social_checked = true;
    data.facebook_url = s?.facebook_url ?? null;
    data.instagram_url = s?.instagram_url ?? null;
    data.linkedin_url = s?.linkedin_url ?? null;
    data.tiktok_url = s?.tiktok_url ?? null;
    data.youtube_url = s?.youtube_url ?? null;
    data.x_url = s?.x_url ?? null;
    data.social_network_count = s?.social_network_count ?? 0;
    data.social_presence_detected = s?.social_presence_detected ?? false;
  }
  return {
    provider: "website",
    status: "success",
    data,
    signals: toSignals(analysis, fetchedAt, includeSocial),
    confidence: analysis.reachable === true ? 0.85 : 0.5,
    fetchedAt,
    expiresAt: cacheExpiryIso(
      analysis.reachable
        ? WEBSITE_CACHE_TTL_DAYS
        : WEBSITE_CACHE_MISS_TTL_DAYS,
    ),
    metadata: { cacheStatus },
  };
}

export function createWebsiteProvider(
  deps: WebsiteProviderDeps,
): EnrichmentProvider {
  const analyzeFn = deps.analyzeFn ?? analyzeWebsite;

  return {
    name: "website",
    dependencyLevel: 3,

    canRun(ctx: EnrichmentContext): boolean {
      const raw = ctx.knownData.websiteUrl;
      if (raw == null || raw === "") return false;
      return normalizeUrl(raw) != null;
    },

    async enrich(ctx: EnrichmentContext): Promise<ProviderEnrichmentResult> {
      const fetchedAt = nowIso();
      const includeSocial = wantsSocial(ctx);
      const rawUrl = ctx.knownData.websiteUrl ?? "";
      const normalized = normalizeUrl(rawUrl);
      if (!normalized) {
        return {
          provider: "website",
          status: "skipped",
          data: {},
          signals: [],
          fetchedAt,
          error: {
            type: "skipped",
            message: "invalid_url",
            retryable: false,
          },
          metadata: { cacheStatus: "none" },
        };
      }

      const forceRefresh = ctx.options.forceRefresh === true;
      const key = websiteCacheKey(normalized, includeSocial);

      if (!forceRefresh) {
        const cached = deps.cache.get(key);
        if (cached != null && typeof cached.reachable === "boolean") {
          return successResult(
            { ...cached, error_type: undefined, social: cached.social },
            "hit",
            fetchedAt,
            includeSocial,
          );
        }
      }

      if (deps.callBudget.remaining <= 0) {
        return {
          provider: "website",
          status: "skipped",
          data: {},
          signals: [],
          fetchedAt,
          error: {
            type: "cap",
            message: "website_cap",
            retryable: true,
          },
          metadata: { cacheStatus: "none" },
        };
      }

      deps.callBudget.remaining -= 1;

      const analysis = await analyzeFn(rawUrl, {
        extractSocial: includeSocial,
      });

      deps.cache.scheduleUpsert({
        cacheKey: key,
        analysis: {
          reachable: analysis.reachable,
          https: analysis.https,
          http_status: analysis.http_status,
          title: analysis.title,
          has_viewport: analysis.has_viewport,
          social: includeSocial ? (analysis.social ?? null) : undefined,
        },
        fetchedAt,
      });

      return successResult(
        analysis,
        forceRefresh ? "bypass" : "miss",
        fetchedAt,
        includeSocial,
      );
    },
  };
}

export function websiteCanRunKnownData(known: {
  websiteUrl?: string | null;
}): boolean {
  const raw = known.websiteUrl;
  if (raw == null || raw === "") return false;
  return normalizeUrl(raw) != null;
}

export function websiteCountsAsApiFailure(errorType?: string): boolean {
  return errorType === "ssrf" || errorType === "timeout";
}
