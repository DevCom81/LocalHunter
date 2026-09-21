// Analyse légère d'un site prospect (C3) — module partagé (Phase 5).
// Joignabilité HTTP(S), titre, meta viewport. Plafonné, timeout court, SSRF.
// Best-effort : ne jette jamais vers l'appelant métier.
// Aucune extension fonctionnelle : comportement C3 strictement conservé.

import { normalizeUrl } from "../pagespeed/client.ts";
import { extractSocialLinks, type SocialLinks } from "./social_links.ts";

export const WEBSITE_MAX_SITES = 10;
export const WEBSITE_CONCURRENCY = 3;
export const WEBSITE_TIMEOUT_MS = 8_000;
export const WEBSITE_MAX_BYTES = 256_000;
export const WEBSITE_MAX_REDIRECTS = 3;
export const WEBSITE_CACHE_TTL_DAYS = 30;
export const WEBSITE_CACHE_MISS_TTL_DAYS = 7;

export interface WebsiteAnalysis {
  reachable: boolean | null;
  https: boolean | null;
  http_status: number | null;
  title: string | null;
  has_viewport: boolean | null;
  /** Rempli seulement si extractSocial=true. */
  social?: SocialLinks | null;
  /** Pour métriques uniquement — jamais d'URL. */
  error_type?: string;
}

const BLOCKED_HOSTS = new Set([
  "localhost",
  "metadata.google.internal",
  "metadata",
]);

/** v2 : payload peut inclure les liens sociaux. */
export function websiteCacheKey(normalizedUrl: string, extractSocial: boolean): string {
  return extractSocial
    ? `website_v2_social:${normalizedUrl}`
    : `website_v2:${normalizedUrl}`;
}

export { cacheExpiryIso } from "../cache_ttl.ts";

/** Exposé pour tests / revue SSRF. */
export function isPrivateOrReservedIp(ip: string): boolean {
  const v4 = ip.includes(".") && !ip.includes(":");
  if (v4) return isPrivateIpv4(ip);
  return isPrivateIpv6(ip);
}

function isPrivateIpv4(ip: string): boolean {
  const parts = ip.split(".").map((p) => Number(p));
  if (
    parts.length !== 4 ||
    parts.some((n) => !Number.isInteger(n) || n < 0 || n > 255)
  ) {
    return true; // malformed → reject
  }
  const [a, b] = parts;
  if (a === 0 || a === 10 || a === 127) return true;
  if (a === 169 && b === 254) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a === 192 && b === 168) return true;
  if (a === 100 && b >= 64 && b <= 127) return true; // CGNAT
  if (a >= 224) return true; // multicast / reserved
  return false;
}

function isPrivateIpv6(ip: string): boolean {
  const lower = ip.toLowerCase();
  if (lower === "::1") return true;
  if (lower.startsWith("fc") || lower.startsWith("fd")) return true; // ULA
  if (lower.startsWith("fe80")) return true; // link-local
  const mapped = lower.match(/::ffff:(\d+\.\d+\.\d+\.\d+)$/);
  if (mapped) return isPrivateIpv4(mapped[1]);
  return false;
}

function isBlockedHostname(hostname: string): boolean {
  const host = hostname.toLowerCase().replace(/\.$/, "");
  if (BLOCKED_HOSTS.has(host)) return true;
  if (host.endsWith(".local") || host.endsWith(".localhost")) return true;
  if (host.endsWith(".internal")) return true;
  return false;
}

function isIpLiteral(hostname: string): boolean {
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(hostname)) return true;
  if (hostname.includes(":")) return true;
  return false;
}

/** Valide schéma / host / DNS avant tout fetch. */
export async function assertSafeUrl(raw: string): Promise<URL> {
  const withScheme = raw.startsWith("http://") || raw.startsWith("https://")
    ? raw
    : `https://${raw}`;
  let url: URL;
  try {
    url = new URL(withScheme);
  } catch {
    throw new Error("invalid_url");
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error("bad_scheme");
  }
  if (url.username || url.password) throw new Error("credentials");
  if (isBlockedHostname(url.hostname)) throw new Error("blocked_host");

  if (isIpLiteral(url.hostname)) {
    if (isPrivateOrReservedIp(url.hostname)) throw new Error("private_ip");
    return url;
  }

  const ips = await resolveHostIps(url.hostname);
  if (ips.length === 0) throw new Error("dns_empty");
  for (const ip of ips) {
    if (isPrivateOrReservedIp(ip)) throw new Error("private_ip");
  }
  return url;
}

async function resolveHostIps(hostname: string): Promise<string[]> {
  const ips: string[] = [];
  try {
    ips.push(...await Deno.resolveDns(hostname, "A"));
  } catch {
    // ignore
  }
  try {
    ips.push(...await Deno.resolveDns(hostname, "AAAA"));
  } catch {
    // ignore
  }
  return [...new Set(ips)];
}

function parseTitle(html: string): string | null {
  const m = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  if (!m) return null;
  const title = m[1].replace(/\s+/g, " ").trim().slice(0, 200);
  return title.length > 0 ? title : null;
}

function hasViewportMeta(html: string): boolean {
  return /<meta[^>]+name\s*=\s*["']viewport["']/i.test(html);
}

async function readBodyLimited(
  res: Response,
  maxBytes: number,
): Promise<string> {
  if (!res.body) return "";
  const reader = res.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    if (!value) continue;
    if (total + value.byteLength > maxBytes) {
      chunks.push(value.subarray(0, maxBytes - total));
      total = maxBytes;
      try {
        await reader.cancel();
      } catch {
        // ignore
      }
      break;
    }
    chunks.push(value);
    total += value.byteLength;
  }
  const merged = new Uint8Array(total);
  let offset = 0;
  for (const c of chunks) {
    merged.set(c, offset);
    offset += c.byteLength;
  }
  return new TextDecoder("utf-8", { fatal: false }).decode(merged);
}

async function fetchHop(
  url: URL,
  redirectsLeft: number,
): Promise<{ status: number; finalUrl: URL; html: string }> {
  const res = await fetch(url.toString(), {
    method: "GET",
    redirect: "manual",
    headers: {
      "User-Agent": "LocalHunterWebsiteCheck/1.0",
      Accept: "text/html,application/xhtml+xml;q=0.9,*/*;q=0.8",
    },
    signal: AbortSignal.timeout(WEBSITE_TIMEOUT_MS),
  });

  if (res.status >= 300 && res.status < 400) {
    const location = res.headers.get("location");
    if (!location || redirectsLeft <= 0) {
      return { status: res.status, finalUrl: url, html: "" };
    }
    const next = new URL(location, url);
    const safe = await assertSafeUrl(next.toString());
    return fetchHop(safe, redirectsLeft - 1);
  }

  const html = await readBodyLimited(res, WEBSITE_MAX_BYTES);
  return { status: res.status, finalUrl: url, html };
}

/**
 * Analyse légère. Ne jette jamais : unreachable / erreur → champs null + error_type.
 * [extractSocial] : parse les liens réseaux (Facebook…X) depuis le HTML.
 */
export async function analyzeWebsite(
  rawWebsite: string,
  options?: { extractSocial?: boolean },
): Promise<WebsiteAnalysis> {
  const extractSocial = options?.extractSocial === true;
  const empty: WebsiteAnalysis = {
    reachable: null,
    https: null,
    http_status: null,
    title: null,
    has_viewport: null,
    social: extractSocial ? extractSocialLinks("") : null,
  };

  if (!normalizeUrl(rawWebsite)) {
    return { ...empty, reachable: false, error_type: "invalid_url" };
  }

  try {
    const startUrl = await assertSafeUrl(rawWebsite);
    const { status, finalUrl, html } = await fetchHop(
      startUrl,
      WEBSITE_MAX_REDIRECTS,
    );
    const ok = status >= 200 && status < 400;
    return {
      reachable: ok,
      https: finalUrl.protocol === "https:",
      http_status: status,
      title: ok ? parseTitle(html) : null,
      has_viewport: ok ? hasViewportMeta(html) : null,
      social: extractSocial
        ? (ok ? extractSocialLinks(html) : extractSocialLinks(""))
        : null,
      error_type: ok ? undefined : "http_status",
    };
  } catch (e) {
    const msg = String(e);
    let errorType = "other";
    if (msg.includes("timeout") || msg.includes("AbortError")) {
      errorType = "timeout";
    } else if (msg.includes("private_ip")) errorType = "ssrf";
    else if (msg.includes("blocked_host")) errorType = "ssrf";
    else if (msg.includes("bad_scheme") || msg.includes("credentials")) {
      errorType = "ssrf";
    } else if (msg.includes("dns")) errorType = "dns";
    else if (msg.includes("invalid_url")) errorType = "invalid_url";

    return {
      reachable: false,
      https: null,
      http_status: null,
      title: null,
      has_viewport: null,
      social: extractSocial ? extractSocialLinks("") : null,
      error_type: errorType,
    };
  }
}

export { normalizeUrl };
