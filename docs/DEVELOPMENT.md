# LocalHunter — Documentation développeur

Contenu technique déplacé depuis le README (réservé aux utilisateurs).

## Stack

- **Flutter** + **Riverpod** + **go_router**
- **Clean Architecture légère** (domain / data / presentation)
- **Supabase** (PostgreSQL, Auth, Storage, Edge Functions)
- Scoring local autonome + couche **LLMProvider** remplaçable

## Prérequis

- Flutter 3.41+ (`flutter doctor`)
- Supabase CLI (optionnel pour backend local)
- Compte Supabase Cloud (production)

## Installation

```bash
git clone <repo>
cd LocalHunter
flutter pub get
```

### Mode démo (sans Supabase)

```bash
flutter run -d chrome
# ou
flutter run -d windows
```

L'app démarre en **mode démo** (données fictives Albi, grilles neutres — pas de marque produit perso).
Sans `SUPABASE_URL` / `SUPABASE_ANON_KEY` valides → démo uniquement ; recherche Prospects désactivée.

### Mode Supabase

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Appliquer les migrations (**001 → 024**) :

```bash
supabase db push
# ou exécuter supabase/migrations/*.sql dans le SQL Editor
# Puis obligatoirement : NOTIFY pgrst, 'reload schema';
```

**Prod récente (Phases 7–9) — colonnes critiques :**
`021` `campaigns.target_profile` · `022` `prospect_scores.fit_score` / `opportunity_score` · `023` `campaigns.discovery_source` · `024` libellés EasyRest neutralisés.
Sans ces colonnes → HTTP **400** PostgREST (`PGRST204`) à la création de campagne ou au scoring.

La migration **003** ajoute les tables `scoring_grids` / `scoring_criteria` et la colonne `campaigns.scoring_grid_id`. Un nouvel utilisateur démarre sans grille : il en crée via l'éditeur, le catalogue métiers ou la génération IA (aucun provisionnement automatique).

La migration **004** ajoute les colonnes JSONB du scoring dynamique (`prospects.custom_fields`, configs d'exclusion/recommandation des grilles, sous-scores détaillés).

La migration **005** crée `grid_generation_cache` : cache **partagé entre utilisateurs** des grilles générées par IA (clé = métier normalisé). Accès uniquement via l'Edge Function (service role) — aucune policy RLS côté client.

La migration **006** ajoute les abonnements : colonne `profiles.subscription_tier` (`freemium` par défaut). Les quotas sont appliqués par **triggers PostgreSQL** — non contournables côté client. Le tier n'est **pas modifiable par l'utilisateur** (privilège de colonne révoqué). En prod le tier est poussé par Play Billing (voir 4ter) ; override manuel possible pour tests / Pro :

```sql
-- Passer un compte en premium (SQL Editor du Dashboard)
UPDATE profiles SET subscription_tier = 'premium'
WHERE email = 'utilisateur@exemple.fr';
-- Valeurs : freemium | premium | premium_plus | pro
```

La migration **010** étend les paliers : `freemium`, `premium`, `premium_plus`, `pro` avec quotas différenciés (campagnes, grilles, prospects/campagne) et table `ai_generation_usage` pour le quota mensuel de générations IA (comptabilisé par l'Edge Function `generate-scoring-grid`, hors cache partagé). **Redéployer `generate-scoring-grid` après cette migration.**

| Plan | Campagnes | Grilles | IA / mois | Prospects / campagne |
|---|---:|---:|---:|---:|
| Freemium | 1 | 1 | — | 5 |
| Premium | 5 | 2 | 2 | 20 |
| Premium Plus | 10 | 5 | 5 | 50 |
| Pro | ∞ | ∞ | ∞ | ∞ |

La migration **011** crée `play_subscriptions` (tokens Google Play, état, expiration). Le tier `profiles.subscription_tier` est mis à jour **uniquement** par les Edge Functions de facturation (service role), jamais par le client.

La migration **007** remplace les 4 types d'offre codés en dur (site web,
logiciel métier, restauration, CRM) par un **libellé d'offre libre porté par la
grille de scoring** (`scoring_grids.offer_label`). La campagne ne définit plus
que la cible de recherche ; l'offre recommandée aux prospects est celle de la
grille liée. Les colonnes enum (`campaigns.offer_type`,
`prospect_scores.recommended_offer`, `ai_recommendations.best_offer`) passent
en texte et le cache de génération IA est vidé (ancien format). **Redéployer
l'Edge Function `generate-scoring-grid` après cette migration.**

La migration **008** ajoute l'enrichissement des prospects : colonnes
`prospects.creation_date` (SIRENE) et `prospects.pagespeed_score`, plus la
table `enrichment_cache` (cache partagé, TTL 30 jours, accès service role
uniquement). **Déployer l'Edge Function `enrich-prospects` après cette
migration** (voir 4ter).

La migration **009** complète la fiche prospect : `siret`, `annual_revenue`,
`annual_revenue_year`, `net_income` (dirigeant et finances via l'**API
Recherche d'entreprises** — publique, sans clé) et vide `enrichment_cache`
(changement de format). **Redéployer `enrich-prospects` après cette
migration.** Le n° de TVA intracommunautaire est calculé côté client à
partir du SIREN.

3. Créer un compte via **Créer un compte** dans l'app, ou via Supabase Dashboard → Authentication

4. Déployer l'Edge Function Google Places :

```bash
supabase secrets set GOOGLE_PLACES_API_KEY=votre_cle
supabase functions deploy search-places
supabase functions deploy search-sirene
```

La function Places vérifie le cache PostgreSQL (`places_search_cache`, TTL 30 jours) avant chaque appel Google. Elle pagine l'API Places (New) jusqu'à **60 résultats** max (plafond Google) ; `maxResults` fait partie de la clé de cache.

`search-sirene` (Phase 9) : discovery registre via recherche-entreprises + geo.api (aucune clé). Campagne `discovery_source = sirene`.

4ter. Déployer l'Edge Function d'enrichissement (SIRENE + PageSpeed) :

```bash
# Clé du nouveau portail INSEE (https://portail-api.insee.fr, API Sirene, plan Public)
supabase secrets set INSEE_API_KEY=votre_cle_insee
supabase functions deploy enrich-prospects
```

Appelée automatiquement après chaque recherche de prospects :
- **SIRENE** : SIREN/SIRET, code NAF, date de création (ancienneté), état —
  un établissement fermé est marqué exclu. Quota INSEE 30 appels/min → max
  25 requêtes par recherche, le cache partagé absorbe le reste ;
- **Recherche d'entreprises** (recherche-entreprises.api.gouv.fr, sans clé) :
  dirigeant principal, chiffre d'affaires et résultat net du dernier bilan
  INPI — uniquement pour les prospects avec SIREN identifié ;
- **PageSpeed Insights** (même clé que Places) : score performance mobile,
  limité aux 20 premiers prospects avec site web (~15 s par site, en
  parallèle). Un site lent renforce l'opportunité « refonte de site » dans
  le scoring ;
- Les champs `pagespeed_score` et `company_age_years` (Ancienneté) sont
  utilisables comme critères de seuil dans les grilles de scoring.
- Best-effort : si une API échoue, la recherche aboutit sans enrichissement.

4quater. Déployer l'Edge Function BODACC (C4) :

```bash
# Aucun secret BODACC : API OpenDataSoft publique
supabase functions deploy enrich-bodacc
```

Appelée **après** le scoring initial (différé / manuel, C4.2+) :
- Recherche par SIREN (`where=registre='…'`, `limit=20`, `order_by=dateparution desc`) ;
- Cache `bodacc_v1:{siren}` TTL 30 jours ; max 20 prospects / invocation ;
- Signaux normalisés sur `prospects` + lignes `bodacc_events` (pas de JSON produit) ;
- Métriques `source=bodacc` via `edge_metrics_daily`.
**Appliquer la migration 020 avant le premier deploy.**

4bis. Déployer l'Edge Function de génération de grilles IA (OpenRouter) :

```bash
# Créer une clé sur https://openrouter.ai/keys
supabase secrets set OPENROUTER_API_KEY=sk-or-v1-xxxxx
# Optionnel : modèle (défaut : mistralai/mistral-nemo)
supabase secrets set OPENROUTER_MODEL=mistralai/mistral-nemo
supabase functions deploy generate-scoring-grid
```

Résolution en 3 niveaux lors de la génération (écran Scoring → Nouvelle grille → Générer par IA) :
1. **Catalogue local** : ~20 grilles métiers pré-remplies (assureur, cuisiniste, expert-comptable…) — zéro requête ;
2. **Cache partagé** (`grid_generation_cache`) : métier déjà généré par un autre utilisateur — zéro appel IA ;
3. **OpenRouter** : génération IA, validée côté serveur (composants = 100 pts), puis mise en cache.

La grille obtenue pré-remplit l'éditeur : rien n'est enregistré sans validation manuelle.

4ter. Google Play Billing (abonnements Android) :

**Play Console** — créer 3 abonnements dans le **même groupe d'abonnements** (changement de palier / remplacement géré par Google) :

| Product ID | Tier Supabase | Prix |
|---|---|---|
| `localhunter_premium_monthly` | `premium` | 19,99 € / mois |
| `localhunter_premium_plus_monthly` | `premium_plus` | 39,99 € / mois |
| `localhunter_pro_monthly` | `pro` | 69,99 € / mois |

Publier l'app sur une **piste de test interne** (AAB signé release) pour tester les achats.

**Google Cloud** — activer **Google Play Android Developer API**, créer un compte de service, télécharger le JSON, inviter ce compte dans Play Console (Autorisations → Gérer les commandes et abonnements).

**Supabase** :

```bash
# JSON complet du compte de service (une seule ligne ou multiligne)
supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT='{"type":"service_account",...}'

supabase db push   # migration 011
supabase functions deploy verify-play-purchase
```

**RTDN (renouvellements / annulations / expirations)** — optionnel mais recommandé en prod :

```bash
# Token secret dans l'URL du push Pub/Sub
supabase secrets set PLAY_RTDN_TOKEN=un-token-long-aleatoire
supabase functions deploy play-rtdn --no-verify-jwt
```

Configurer dans Play Console → Monétisation → Notifications en temps réel : endpoint Pub/Sub push vers  
`https://<project-ref>.supabase.co/functions/v1/play-rtdn?token=<PLAY_RTDN_TOKEN>`

Flux app Android : achat ou restauration → `verify-play-purchase` (API Google + mise à jour tier) → quotas SQL appliqués. RTDN tient à jour renouvellements / annulations.

**Web (Flutter Web) — pas de Play Billing in-browser** (Google Pay ≠ abonnements Play). Décision produit **option A** (v2.0) :

- Écran `SubscriptionScreen` : hors Android, chaque plan payé (sauf offre actuelle) a un CTA **« S’abonner à … sur Android »**.
- Ouvre le listing Play Store : `https://play.google.com/store/apps/details?id=com.localhunter.localhunter` (`url_launcher`).
- Même compte LocalHunter (Supabase) ; après achat sur le téléphone, recharger l’écran Abonnement (tier lu en lecture seule depuis `profiles`).
- Aucune modification du chemin `play_billing_*` / `verify-play-purchase` pour le web.
- **Hors scope / reprise ultérieure (option B)** : checkout web séparé (Stripe ± Google Pay comme moyen de paiement) → nouvelle Edge pour poser le tier — **sans** casser le billing Android. Non implémenté.

Package Android : `com.localhunter.localhunter`.

5. Configurer les clés (au choix) :

**Option A — fichier `.env` (recommandé en local)**

```bash
cp .env.example .env
# Éditer .env avec l’URL et la clé anon du projet Supabase
flutter run -d chrome
```

**Option B — `--dart-define` (prioritaire sur `.env`, utile en CI)**

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Priorité : `--dart-define` > `.env` > valeurs placeholder (mode démo).

Le fichier `.env` est ignoré par git ; ne jamais committer de secrets.

**Mobile (Android / iOS)**

- Le `.env` est lu depuis les **assets Flutter** (déclaré dans `pubspec.yaml`). Il doit exister **avant** `flutter run` ou `flutter build` : modifiez `.env`, puis relancez un build complet (un hot reload ne recharge pas les assets).
- Builds **release Android** : la permission `INTERNET` est déclarée dans `android/app/src/main/AndroidManifest.xml` (requise pour Supabase).
- Pour distribuer sans `.env` (CI, stores) :

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Structure projet

```
lib/
├── core/           # config, theme, routing, widgets partagés
├── features/
│   ├── auth/
│   ├── campaigns/
│   ├── prospects/      # + domain/discovery + data/discovery (Phase 2)
│   ├── scoring/
│   ├── subscription/  # tiers, quotas, Play Billing, CTA web → Play Store
│   ├── commercial_profile/
│   ├── ai_analysis/
│   └── export/
supabase/
├── migrations/     # schéma PostgreSQL + RLS (001 → 027)
├── functions/      # Edge Functions + `_shared/` (cors, enrichment, play_*, search-sirene)
assets/fixtures/    # CSV test Albi
```

Chaque feature : `domain/` · `data/` · `presentation/`

**Règle stricte** : aucun fichier > 200 lignes.

## Reprise / état courant (v2.0.0+7)

Snapshot pour reprendre sans rejouer l’historique oral.

### Repositionnement B2B générique

**Phase 1 (faite) — UX CRM neutre**
- Filtres option **B** : chips Site / Logiciel / Sans site / Site faible retirés.
- Conservés : Priorité haute, Score > 70, Exclure chaînes, Email/Tél.
- Template `LocalHunter Default` : `offerLabel` vide ; **neutralisé en Phase 10** (plus de poids site/logiciel).
- Grilles users en base non migrées automatiquement.

**Phase 2 (faite) — Discovery port**
- Port domain : `lib/features/prospects/domain/discovery/discovery_provider.dart`
- Adapter Places + `campaignDiscoveryProvider` ; comportement recherche inchangé.

**Phase 3 (faite) — Enrichissement adaptatif**
- `EnrichmentNeeds.fromGrid(grid)` → providers requis.
- Toujours : `sirene` + `company`.
- Conditionnel : `website` / `pagespeed` (critères site pondérés, `pagespeed_score`, legacy `website_opportunity` / `site_score` ; reco `site_score` **uniquement** si le critère site est actif et pondéré).
- Conditionnel : BODACC différé si critère `bodacc_*` avec `maxPoints > 0`.
- Client passe `enabledProviders` à `enrich-prospects` ; Edge : absent/vide = comportement historique (tout).
- **Ops :** `supabase functions deploy enrich-prospects` (sinon le client envoie la liste mais l’Edge ignore encore).
- Grille LocalHunter Default (Phase 10, sans critères site) → **pas de PageSpeed**.
- Grille métier catalogue (contact + Google, sans opportunité site) → **pas de PageSpeed**.
- Grille avec critère site / `website_opportunity` / `pagespeed_score` pondéré → PageSpeed.

**Phase 4 (faite) — Signal model minimal**
- Domain : `prospects/domain/signals/prospect_signal.dart` (`SignalKind` = fact / signal / inference).
- Builder : `prospect_signal_builder.dart` — mapping déterministe Prospect → signaux (SIRENE, COMPANY, PLACES, PAGESPEED, BODACC).
- UI : section « Faits & signaux » sur fiche prospect ; légende FACT≠hypothèse sur explication du score.
- **Pas de table SQL** ; pas d’inférences IA générées (kind `inference` prévu, liste vide pour l’instant).
- BODACC checklist conservée (détail événements) ; le builder expose les flags comme **signaux**.

**Phase 5 (faite) — IA profil → validation → grille**
- Edge `generate-scoring-grid` : `step: "profile" | "grid"` (défaut `grid` = rétrocompat).
- `profile_schema.ts` : proposition ICP (offre, cible, signaux, exclusions) sans critères techniques.
- Prompt grille : ne force plus SEO/PageSpeed sauf si l’offre le justifie.
- Cache : clé `sha256(offer|target|métier)` si profil ; sinon métier seul (historique).
- Flutter : « Comprendre ma cible » → `ProspectingProfileReviewDialog` → « Utiliser ce profil » → grille.
- Mode démo (pas de remote) : catalogue local inchangé.
- **Ops :** `supabase functions deploy generate-scoring-grid`
- Quota IA : consommé à l’étape grille uniquement (pas à la proposition de profil).

**Phase 6 (faite) — FieldResolver générique FR**
- Nouveaux champs scorables : `siret`, `annual_revenue` (+ alias `revenue`), `net_income`, `annual_revenue_year`, `website_exists`, `company_created_recently` (< 24 mois), alias `activity_code` → NAF.
- Labels : `prospect_field_labels.dart` ; seuils UI : CA / résultat net.
- Edge `KNOWN_FIELDS` aligné (redeploy `generate-scoring-grid` si pas déjà fait en Phase 5).
- **Non ajouté en Phase 6** : `employee_count` / `establishment_count` → **ajoutés en Phase 10**.

**Phase 7 (faite) — Target Profile campagne**
- Migration **021** : `campaigns.target_profile` JSONB nullable (rétrocompat).
- Domain : `CampaignTargetProfile` (offre, cible, signaux, exclusions, note géo).
- UI création : section optionnelle « Cible commerciale » ; ville/rayon = filtre Places ; secteur = mot-clé Places (plus de défaut « restauration »).
- Fiche campagne : résumé du profil si renseigné.
- **Ops :** appliquer `021_campaign_target_profile.sql` + `NOTIFY pgrst, 'reload schema'`.
- Hors scope Phase 7 : édition profil après création (propagation IA → campagne = **Phase 10**).

**Phase 8 (faite) — FIT / OPPORTUNITY**
- Splitter : critères OPP = `bodacc_*`, `website_opportunity`, `site_score`, `pagespeed` / `pagespeed_score`, `company_created_recently` ; reste = FIT.
- `ProspectScore.fitScore` / `opportunityScore` (nullable) ; `scoringVersion: 4`.
- Migration **022** : colonnes nullable `fit_score`, `opportunity_score` sur `prospect_scores`.
- UI : fiche prospect + en-tête explication du score (libellés « Correspondance » / « Opportunité »).
- Score global /100 inchangé (priorités, filtres, quotas).
- **Ops :** appliquer `022_fit_opportunity_scores.sql`.
- Scores pré-Phase 8 : FIT/OPP absents (null) jusqu’au recalcul.

**Phase 9 (faite) — Multi-discovery (SIRENE) + BODACC manuel**
- Migration **023** : `campaigns.discovery_source` (`places` défaut | `sirene`) — forme idempotente + `NOTIFY pgrst`.
- Edge `search-sirene` : Recherche d’entreprises + geo.api (CP commune) ; rayon Places ignoré.
- Adapters : `SireneDiscoveryProvider` ; `discoveryForSource` selon la campagne.
- UI création : sélecteur Places / SIRENE ; détail : source affichée.
- BODACC **pas** discovery : bouton campagne « Enrichir BODACC » + bouton fiche.
- Prospects SIRENE : `sireneMatchScore=100` → éligibles BODACC manuel.
- Correctif : `CampaignsNotifier.create` propage aussi `targetProfile`.
- **Ops :** migration 023 + `supabase functions deploy search-sirene`.

**Neutralisation marque / démo (faite)**
- Migration **024** : renomme grilles « EasyRest Restauration » → « Restauration locale », vide `offer_label = EasyRest`, libellé critère → « Score restauration ».
- Code : template EasyRest retiré ; démo « Campagne démo — Albi » ; clé DB `easy_rest_score` conservée (legacy).

**Phase 10 (faite) — Neutralité Default + effectif + profil → campagne**
- Template **LocalHunter Default** (code) : contact + identité + NAF + CA ; **aucun** site/SEO/PageSpeed/logiciel/EasyRest/maturité digitale pondéré ; reco vide ; exclusions sans `website_pattern`.
- **Grilles utilisateur déjà en base non modifiées** (pas de migration destructive des critères).
- `employee_count` / `establishment_count` : colonnes prospects (**025**), CompanyProvider (tranche INSEE → borne basse ; nb établissements), FieldResolver + labels FR + seuils UI + `KNOWN_FIELDS` IA.
- Null = inconnu (jamais inventé) ; `0` effectif possible si tranche `00`.
- Profil IA validé → `pendingCampaignTargetProfileProvider` → préremplit création campagne (`toCampaignTargetProfile`) ; clear après create.
- Prompt grille IA : sub_scores optionnels ; champs effectif/établissements privilégiés hors web.
- Tests : `test/scoring/phase10_offer_neutrality_test.dart`.
- **Ops :** migration **025** + redeploy `enrich-prospects` + `generate-scoring-grid`.

**Phase 11 (faite) — Critères mesurables uniquement + social conditionnel**
- Règle non négociable : l’IA ne propose que des champs que LocalHunter sait mesurer.
- Source de vérité : `MeasurableCriteriaCatalog` (Dart) + `KNOWN_FIELDS` Edge alignés.
- Validation post-génération : `GeneratedGridValidator` dans `parseGeneratedGrid` — critères hors whitelist **rejetés** (pas d’ajout silencieux) ; legacy IA interdit.
- Places : rating / userRatingCount / websiteUri / phones (national + international) / businessStatus ; FieldResolver `google_rating`, `google_reviews`, `google_business_status`.
- Social : extraction HTML déterministe (FB, IG, LinkedIn, TikTok, YouTube, X) si la grille le demande (`EnrichmentNeeds.social` → provider `social` + `website`).
- Signification : non détecté = « aucun lien trouvé sur le site analysé » (confiance 0.75), **pas** « n’a aucun réseau ».
- Colonnes **026** : `linkedin_url`, `tiktok_url`, `youtube_url`, `x_url`, `social_checked_at`.
- Tests : `test/scoring/phase11_measurable_criteria_test.dart`.
- **Ops :** migration **026** + redeploy `enrich-prospects` + `generate-scoring-grid` (+ `search-places` si field mask v3).

**Phase 12 (faite) — Discovery composite Places + SIRENE**
- `discovery_source = combined` (défaut nouvelles campagnes) ; `places` / `sirene` rétrocompat (**027**).
- `CombinedDiscoveryProvider` exécute les deux adapters en parallèle puis `BusinessCandidateResolver`.
- Seuils : ≥85 fusion auto ; 70–84 probable (pas d’auto) ; &lt;70 distincts.
- Scores : SIRET 100, SIREN 98, nom+adresse 95, adresse+CP+ville 85 (cas enseigne ≠ raison sociale), nom+ville 75, nom seul 50.
- Garde multi-occupants (coworking, centre commercial…) : adresse seule insuffisante sans 2ᵉ signal.
- Fusion : nom/tél/site/note Places ; SIREN/SIRET/NAF/effectif/ancienneté SIRENE ; `enrichmentSource: places+sirene`.
- UX création : plus de choix Places/SIRENE — texte « recherche unifiée ».
- Tests : `test/prospects/phase12_business_candidate_resolver_test.dart` (A–E).
- **Ops :** migration **027**.

**Backlog restant :** BODACC/CSV discovery ; édition `target_profile` post-création ; checkout web ; matching probable (70–84) assisté UI.

### Version

- `pubspec.yaml` : **`2.1.0+8`** (versionName + versionCode Play).

### Deploy Firebase Hosting (web)

Le `.env` local **ne suffit pas** en prod si le build n’embarque pas les clés. Toujours :

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://VOTRE_PROJET.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=VOTRE_ANON_KEY
firebase deploy --only hosting
```

Sans dart-define valides → mode démo + chip « Recherche Places : Supabase requis ».

### Correctifs récents (inclus ou à redéployer)

| Sujet | Détail | Action restante |
|---|---|---|
| Création campagne 400 | Colonnes `target_profile` / `discovery_source` absentes → PGRST204. Message d’erreur explicite + SQL idempotent 021/023. | **Appliquer 021+023** + `NOTIFY pgrst, 'reload schema'` |
| UX création campagne | Erreurs avalées ; validation rayon/cible ; grille obligatoire | Rebuild web si pas encore déployé |
| Neutralisation EasyRest | Plus de template / libellés produit perso | Migration **024** |
| Dropdown grilles (web **et** Android) | Assertion `threshold` champ hors liste numérique (`criterion_rule_editor.dart`) | Aucune si build 2.0 embarque le fix |
| CORS Flutter Web | Helper `_shared/cors.ts`. Branché sur `generate-scoring-grid` et `search-places`. | **Redéployer** si pas déjà fait ; aligner `enrich-prospects`, `enrich-bodacc`, … |
| Abonnement web | CTA → Play Store (option A) | Option B non démarrée |
| Auth | Remember-me + biométrie mobile | — |

### Edge Functions — CORS

```bash
# Déjà corrigés en code local — redeploy si prod pas à jour :
supabase functions deploy generate-scoring-grid
supabase functions deploy search-places
supabase functions deploy search-sirene

# À aligner sur `_shared/cors.ts` (phase séparée) :
# enrich-prospects, enrich-bodacc, verify-play-purchase, …
```

### Scoring — règles `threshold`

- UI : champs numériques proposés = `google_rating`, `google_reviews`, `pagespeed_score`, `company_age_years` ; tout autre `field` (ex. `website` généré par l’IA) → « Champ personnalisé ».
- **Reprise possible** : restreindre `threshold` aux champs numériques dans `generate-scoring-grid/grid_schema.ts` pour éviter de mauvaises grilles à la source (UI déjà défensive).

### Billing — décisions verrouillées

1. Achat réel = **Google Play in-app Android uniquement**.
2. Web = redirection listing Play + même compte Supabase (pas de `in_app_purchase` web).
3. Tier jamais écrit par le client ; uniquement Edge service role / SQL manuel.
4. Ne pas mélanger Google Pay web et SKU Play sans nouveau canal de paiement dédié.

### Migrations

Appliquer jusqu’à **024** si l’environnement n’est pas à jour :

| # | Fichier | Effet |
|---|---|---|
| 001–020 | … | socle, billing, BODACC, metrics, etc. |
| **021** | `021_campaign_target_profile.sql` | `campaigns.target_profile` |
| **022** | `022_fit_opportunity_scores.sql` | `prospect_scores.fit_score` / `opportunity_score` |
| **023** | `023_campaign_discovery_source.sql` | `campaigns.discovery_source` + reload schema |
| **024** | `024_neutralize_easyrest_labels.sql` | libellés EasyRest → neutres |
| **025** | `025_prospect_employee_establishment.sql` | `employee_count` / `establishment_count` |
| **026** | `026_prospect_social_links.sql` | URLs sociaux + `social_checked_at` |
| **027** | `027_discovery_source_combined.sql` | `combined` + défaut discovery |

```bash
supabase db push
# ou SQL Editor fichier par fichier, puis :
# NOTIFY pgrst, 'reload schema';
```

## Fonctionnalités MVP

| Module | Statut |
|---|---|
| Navigation + écrans | ✅ |
| Scoring local /100 + FIT/OPP | ✅ Phase 8 |
| CRUD campagnes (démo + Supabase) | ✅ |
| Discovery Places **ou** SIRENE | ✅ Phase 9 |
| Import CSV + scoring + persistance scores | ✅ |
| Export CSV/XLSX | ✅ |
| Données démo Albi (neutres) | ✅ |
| Filtres CRM (neutres B2B) | ✅ Phase 1 |
| Analyse IA (templates locaux) | ✅ |
| Supabase schema + RLS | ✅ |
| Auth Supabase (inscription + connexion) | ✅ |
| Remember-me + biométrie (mobile) | ✅ |
| Google Places via Edge Function | ✅ |
| Cache recherches Places (30 j) | ✅ |
| Enrichissement SIRENE + PageSpeed + BODACC | ✅ |
| BODACC manuel (campagne + fiche) | ✅ |
| Play Billing Android | ✅ |
| CTA abonnement web → Play Store | ✅ (option A) |
| Checkout web (Stripe / option B) | 🔲 |
| Edge Function IA | ✅ `generate-scoring-grid` |
| Edge `search-sirene` | ✅ Phase 9 |

## Scoring LocalHunter

| Composante | Poids |
|---|---|
| Décisionnaire accessible | /30 |
| Opportunité site web | /30 |
| Opportunité logiciel métier | /25 |
| Santé commerciale | /15 |

Sous-scores 0–5★ : SiteScore, SoftwareScore, Score restauration (`easy_rest_score` legacy), AccessibilityScore, DigitalMaturityScore, FalsePositiveRisk.

## IA

```dart
// lib/core/network/service_providers.dart
// Basculer NoopLLMProvider() pour désactiver
llmProviderProvider → LocalTemplateLLMProvider (défaut)
```

## Import CSV test

Fichier : `assets/fixtures/albi_restaurants.csv`

## Contraintes légales

- Pas de scraping non autorisé
- Import manuel, CSV, APIs publiques officielles uniquement

## License

Propriétaire — usage interne.
