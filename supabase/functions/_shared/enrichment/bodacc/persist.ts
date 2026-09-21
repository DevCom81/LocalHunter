// Persistance BODACC — schéma existant (Phase 2, pas de migration).

import type { ProviderEnrichmentResult } from "../types.ts";
import type { NormalizedBodaccEvent } from "./signals.ts";

// deno-lint-ignore no-explicit-any
type AdminClient = any;

/**
 * Écrit patch prospects + remplace bodacc_events.
 * Retourne le payload HTTP `enriched[id]` ou null si non persistant.
 */
export async function persistBodaccResult(
  admin: AdminClient,
  prospectId: string,
  result: ProviderEnrichmentResult,
): Promise<Record<string, unknown> | null> {
  if (result.status !== "success" && result.status !== "partial") {
    return null;
  }

  const siren = String(result.data.siren ?? "");
  const patch = result.data.patch as Record<string, unknown> | undefined;
  const events = (result.data.events ?? []) as NormalizedBodaccEvent[];
  if (!patch || !siren) return null;

  await admin.from("prospects").update(patch).eq("id", prospectId);

  await admin.from("bodacc_events").delete().eq("prospect_id", prospectId);
  if (events.length > 0) {
    const rows = events.map((e) => ({
      prospect_id: prospectId,
      siren,
      bodacc_id: e.bodacc_id,
      date_parution: e.date_parution,
      famille: e.famille,
      type_avis: e.type_avis,
      signal_key: e.signal_key,
      ville: e.ville,
      url: e.url,
    }));
    await admin.from("bodacc_events").insert(rows);
  }

  return {
    ...patch,
    from_cache: result.data.from_cache === true,
    events_count: typeof result.data.events_count === "number"
      ? result.data.events_count
      : events.length,
    events_in_lookback: typeof result.data.events_in_lookback === "number"
      ? result.data.events_in_lookback
      : 0,
  };
}
