// Erreurs contrôlées du pipeline d'enrichissement (Phase 1).

import type { ProviderError } from "./types.ts";

export class EnrichmentError extends Error {
  readonly type: string;
  readonly retryable: boolean;

  constructor(type: string, message: string, retryable = false) {
    super(message);
    this.name = "EnrichmentError";
    this.type = type;
    this.retryable = retryable;
  }

  toProviderError(): ProviderError {
    return {
      type: this.type,
      message: sanitizeErrorMessage(this.message),
      retryable: this.retryable,
    };
  }
}

/** Retire d'éventuels secrets / identifiants d'un message d'erreur. */
export function sanitizeErrorMessage(raw: string): string {
  return raw
    .replace(/\b\d{9}\b/g, "[redacted]") // SIREN
    .replace(/\b\d{14}\b/g, "[redacted]") // SIRET
    .replace(/https?:\/\/[^\s]+/gi, "[url]")
    .replace(
      /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/gi,
      "[email]",
    )
    .slice(0, 200);
}

/** Classifie une erreur inconnue en ProviderError (basse cardinalité). */
export function classifyThrown(err: unknown): ProviderError {
  if (err instanceof EnrichmentError) return err.toProviderError();

  const msg = sanitizeErrorMessage(String(err ?? "unknown"));
  const lower = msg.toLowerCase();

  if (lower.includes("timeout") || lower.includes("abort")) {
    return { type: "timeout", message: msg, retryable: true };
  }
  if (lower.includes("429")) {
    return { type: "http_429", message: msg, retryable: true };
  }
  if (lower.includes("401") || lower.includes("403")) {
    return { type: "http_4xx", message: msg, retryable: false };
  }
  if (lower.includes("404")) {
    return { type: "http_404", message: msg, retryable: false };
  }
  if (lower.includes("500") || lower.includes("502") || lower.includes("503")) {
    return { type: "http_5xx", message: msg, retryable: true };
  }
  if (lower.includes("ssrf") || lower.includes("private_ip")) {
    return { type: "ssrf", message: msg, retryable: false };
  }
  if (lower.includes("parse") || lower.includes("json")) {
    return { type: "parse", message: msg, retryable: false };
  }
  return { type: "other", message: msg, retryable: false };
}
