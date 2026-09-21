# Pipeline d’enrichissement générique

**Statut :** Option B + **CompanyProvider** livrés.

## Vision

```
enrich-prospects / enrich-bodacc / search-places  (HTTP inchangés)
        │
        ▼
ProspectEnrichmentPipeline (`_shared/enrichment/pipeline.ts`)
        ├── PlacesProvider      (niveau 1 ✅)
        ├── SireneProvider      (niveau 2 ✅)
        ├── CompanyProvider     (niveau 3 ✅ — finances / dirigeant)
        ├── BodaccProvider      (niveau 3 ✅)
        ├── WebsiteProvider     (niveau 3 ✅)
        └── PageSpeedProvider   (niveau 3 ✅)
```

Barrel : `supabase/functions/_shared/enrichment/mod.ts`

## Phases livrées

| Phase | Contenu |
|---|---|
| 1–7 | Contrats + providers Places/SIRENE/Website/PageSpeed/BODACC + dédup |
| company | `CompanyProvider` depuis `recherche-entreprises.api.gouv.fr` |

### Company — détails

- `_shared/enrichment/company/` — client + provider + mod
- Cache `company:{siren}`, TTL 30j / miss 7j
- Champs : `manager_name`, `annual_revenue`, `annual_revenue_year`, `net_income`
- Distinct SIRENE (identité) et BODACC (annonces)
- `enrich-prospects/finances.ts` **supprimé** (logique migrée)
- Exécution après SIRENE, par SIREN dédupliqué, concurrence 3

**Contrats HTTP inchangés.** Aucune migration SQL.

## Ops

Redéployer **`enrich-prospects`**.

## Phase 3 — Enrichissement adaptatif (client + Edge)

Body optionnel : `enabledProviders: ["sirene","company","website","pagespeed"]`.

- Absent / vide → tous les providers (rétrocompat).
- Flutter : `EnrichmentNeeds.fromGrid` dérive la liste ; BODACC reste sur `enrich-bodacc` (skip client si grille sans critères BODACC pondérés).

## Règles

- Best-effort : un provider ne bloque pas les autres.
- Absence de donnée ≠ signal positif.
- Pas de PII dans les labels métriques.
- Pas de nouvelle queue ; pas de fusion/suppression des routes HTTP sans arbitrage.
