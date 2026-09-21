// Helpers TTL cache partagés (Phase 7 — déduplication).

/** Date d'expiration ISO à +N jours (UTC). */
export function cacheExpiryIso(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString();
}
