// Dérivation des signaux métier BODACC (partagé, Phase 2).
// Pas de score : flags + radiation_status uniquement.

import {
  BODACC_LOOKBACK_YEARS,
  type BodaccRawRecord,
  normalizeSiren,
  recordMatchesSiren,
} from "./client.ts";

export type SignalKey =
  | "creation"
  | "accounts_filing"
  | "modification"
  | "sale"
  | "radiation"
  | "liquidation"
  | "collective_proceeding"
  | "manager_change"
  | "address_change"
  | "unclassified";

export type RadiationStatus = "none" | "excluded" | "review";
export type SignalConfidence = "low" | "medium" | "high";

export interface NormalizedBodaccEvent {
  bodacc_id: string;
  date_parution: string | null;
  famille: string | null;
  type_avis: string | null;
  signal_key: SignalKey;
  ville: string | null;
  url: string | null;
  is_rectificatif: boolean;
  within_lookback: boolean;
}

export interface BodaccSignals {
  no_results: boolean;
  has_creation: boolean;
  has_accounts_filing: boolean;
  has_modification: boolean;
  has_sale: boolean;
  has_radiation: boolean;
  has_liquidation: boolean;
  has_collective_proceeding: boolean;
  has_manager_change: boolean;
  has_address_change: boolean;
  last_event_at: string | null;
  signal_confidence: SignalConfidence;
  radiation_status: RadiationStatus;
  events: NormalizedBodaccEvent[];
  events_in_lookback: number;
}

function lower(s: string | null | undefined): string {
  return (s ?? "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

function asText(value: unknown): string {
  if (value == null) return "";
  if (typeof value === "string") return value;
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

export function isRectificatif(record: BodaccRawRecord): boolean {
  const blob = `${lower(record.typeavis)} ${lower(record.typeavis_lib)}`;
  return blob.includes("rectif");
}

export function parseDate(iso: string | undefined): Date | null {
  if (!iso) return null;
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d;
}

export function withinLookback(date: Date | null, now = new Date()): boolean {
  if (!date) return false;
  const cutoff = new Date(now);
  cutoff.setFullYear(cutoff.getFullYear() - BODACC_LOOKBACK_YEARS);
  return date >= cutoff;
}

/** Mapping déterministe famille / structure → signal_key. */
export function mapSignalKey(record: BodaccRawRecord): SignalKey {
  const famille = lower(record.familleavis);
  const familleLib = lower(record.familleavis_lib);
  const typeLib = lower(record.typeavis_lib);
  const combo = `${famille} ${familleLib} ${typeLib}`;
  const mods = lower(asText(record.modificationsgenerales));
  const jugement = lower(asText(record.jugement));
  const radiation = record.radiationaurcs != null;
  const depot = record.depot != null;

  if (
    radiation ||
    combo.includes("radiation")
  ) {
    return "radiation";
  }
  if (
    combo.includes("liquid") ||
    jugement.includes("liquid")
  ) {
    return "liquidation";
  }
  if (
    combo.includes("collective") ||
    combo.includes("procedure collective") ||
    combo.includes("redressement") ||
    combo.includes("sauvegarde") ||
    jugement.includes("redressement") ||
    jugement.includes("sauvegarde") ||
    jugement.includes("liquidation judiciaire")
  ) {
    return "collective_proceeding";
  }
  if (
    combo.includes("vente") ||
    combo.includes("cession") ||
    combo.includes("transfert")
  ) {
    return "sale";
  }
  if (
    depot ||
    combo.includes("depot") ||
    combo.includes("comptes")
  ) {
    return "accounts_filing";
  }
  if (
    combo.includes("creation") ||
    combo.includes("immatriculation")
  ) {
    return "creation";
  }
  if (
    mods.includes("administration") ||
    mods.includes("dirigeant") ||
    mods.includes("gerant") ||
    mods.includes("president")
  ) {
    return "manager_change";
  }
  if (
    mods.includes("adresse") ||
    mods.includes("siege") ||
    combo.includes("transfert de siege")
  ) {
    return "address_change";
  }
  if (combo.includes("modification") || famille === "modification") {
    return "modification";
  }
  return "unclassified";
}

export function normalizeRecord(
  record: BodaccRawRecord,
  siren: string,
  now = new Date(),
): NormalizedBodaccEvent | null {
  if (!record.id) return null;
  if (!recordMatchesSiren(record, siren)) return null;
  const date = parseDate(record.dateparution);
  return {
    bodacc_id: record.id,
    date_parution: record.dateparution?.slice(0, 10) ?? null,
    famille: record.familleavis_lib ?? record.familleavis ?? null,
    type_avis: record.typeavis_lib ?? record.typeavis ?? null,
    signal_key: mapSignalKey(record),
    ville: record.ville ?? null,
    url: record.url_complete ?? null,
    is_rectificatif: isRectificatif(record),
    within_lookback: withinLookback(date, now),
  };
}

/**
 * Radiation → excluded seulement si :
 * - signal radiation lié au SIREN
 * - non rectificatif
 * - dans la fenêtre lookback
 * - SIRENE concorde (sireneActive === false)
 * Sinon review si radiation détectée sans concordance.
 */
export function decideRadiationStatus(
  events: NormalizedBodaccEvent[],
  sireneActive: boolean | null | undefined,
): RadiationStatus {
  const radiationEvents = events.filter(
    (e) =>
      e.signal_key === "radiation" &&
      e.within_lookback &&
      !e.is_rectificatif,
  );
  if (radiationEvents.length === 0) return "none";
  if (sireneActive === false) return "excluded";
  return "review";
}

function confidenceFor(events: NormalizedBodaccEvent[]): SignalConfidence {
  const classified = events.filter((e) => e.signal_key !== "unclassified");
  if (classified.length === 0) return "low";
  if (classified.length >= 3) return "high";
  return "medium";
}

export function deriveSignals(
  records: BodaccRawRecord[],
  siren: string,
  sireneActive: boolean | null | undefined,
  now = new Date(),
): BodaccSignals {
  const normalizedSiren = normalizeSiren(siren);
  if (!normalizedSiren) {
    return emptySignals(true);
  }

  const events = records
    .map((r) => normalizeRecord(r, normalizedSiren, now))
    .filter((e): e is NormalizedBodaccEvent => e != null);

  if (events.length === 0) {
    return emptySignals(true);
  }

  const inWindow = events.filter((e) => e.within_lookback);
  const keys = new Set(inWindow.map((e) => e.signal_key));

  const last = events
    .map((e) => e.date_parution)
    .filter((d): d is string => d != null)
    .sort()
    .at(-1) ?? null;

  return {
    no_results: false,
    has_creation: keys.has("creation"),
    has_accounts_filing: keys.has("accounts_filing"),
    has_modification: keys.has("modification"),
    has_sale: keys.has("sale"),
    has_radiation: keys.has("radiation"),
    has_liquidation: keys.has("liquidation"),
    has_collective_proceeding: keys.has("collective_proceeding"),
    has_manager_change: keys.has("manager_change"),
    has_address_change: keys.has("address_change"),
    last_event_at: last,
    signal_confidence: confidenceFor(inWindow),
    radiation_status: decideRadiationStatus(events, sireneActive),
    events,
    events_in_lookback: inWindow.length,
  };
}

function emptySignals(noResults: boolean): BodaccSignals {
  return {
    no_results: noResults,
    has_creation: false,
    has_accounts_filing: false,
    has_modification: false,
    has_sale: false,
    has_radiation: false,
    has_liquidation: false,
    has_collective_proceeding: false,
    has_manager_change: false,
    has_address_change: false,
    last_event_at: null,
    signal_confidence: "low",
    radiation_status: "none",
    events: [],
    events_in_lookback: 0,
  };
}

/** Payload colonnes prospects (sans events). */
export function signalsToProspectPatch(
  signals: BodaccSignals,
  fetchedAt: string,
): Record<string, unknown> {
  return {
    bodacc_fetched_at: fetchedAt,
    bodacc_last_event_at: signals.last_event_at,
    bodacc_no_results: signals.no_results,
    bodacc_has_creation: signals.has_creation,
    bodacc_has_accounts_filing: signals.has_accounts_filing,
    bodacc_has_modification: signals.has_modification,
    bodacc_has_sale: signals.has_sale,
    bodacc_has_radiation: signals.has_radiation,
    bodacc_has_liquidation: signals.has_liquidation,
    bodacc_has_collective_proceeding: signals.has_collective_proceeding,
    bodacc_has_manager_change: signals.has_manager_change,
    bodacc_has_address_change: signals.has_address_change,
    bodacc_signal_confidence: signals.signal_confidence,
    bodacc_radiation_status: signals.radiation_status,
  };
}
