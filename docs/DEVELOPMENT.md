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

L'app démarre avec 15 prospects restaurants Albi pré-chargés et le scoring actif.

### Mode Supabase

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Appliquer les migrations (001 → 011) :

```bash
supabase db push
# ou exécuter supabase/migrations/*.sql dans le SQL Editor
```

La migration **003** ajoute les tables `scoring_grids` / `scoring_criteria` et la colonne `campaigns.scoring_grid_id`. Un nouvel utilisateur démarre sans grille : il en crée via l'éditeur, le catalogue métiers ou la génération IA (aucun provisionnement automatique).

La migration **004** ajoute les colonnes JSONB du scoring dynamique (`prospects.custom_fields`, configs d'exclusion/recommandation des grilles, sous-scores détaillés).

La migration **005** crée `grid_generation_cache` : cache **partagé entre utilisateurs** des grilles générées par IA (clé = métier normalisé). Accès uniquement via l'Edge Function (service role) — aucune policy RLS côté client.

La migration **006** ajoute les abonnements : colonne `profiles.subscription_tier` (`freemium` par défaut). Les quotas sont appliqués par **triggers PostgreSQL** — non contournables côté client. Le tier n'est **pas modifiable par l'utilisateur** (privilège de colonne révoqué) : changement manuel uniquement, en attendant Google Play Billing :

```sql
-- Passer un compte en premium (SQL Editor du Dashboard)
UPDATE profiles SET subscription_tier = 'premium'
WHERE email = 'utilisateur@exemple.fr';
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
logiciel métier, EasyRest, CRM) par un **libellé d'offre libre porté par la
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
```

La function vérifie le cache PostgreSQL (`places_search_cache`, TTL 30 jours) avant chaque appel Google. Elle pagine l'API Places (New) jusqu'à **60 résultats** max (plafond Google) ; `maxResults` fait partie de la clé de cache.

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

Flux app : achat ou restauration → `verify-play-purchase` (API Google + mise à jour tier) → quotas SQL appliqués.

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
│   ├── prospects/
│   ├── scoring/
│   ├── ai_analysis/
│   └── export/
supabase/
├── migrations/     # schéma PostgreSQL + RLS
assets/fixtures/    # CSV test Albi
```

Chaque feature : `domain/` · `data/` · `presentation/`

**Règle stricte** : aucun fichier > 200 lignes.

## Fonctionnalités MVP

| Module | Statut |
|---|---|
| Navigation + écrans | ✅ |
| Scoring local /100 | ✅ |
| CRUD campagnes (démo + Supabase) | ✅ Phase 2 |
| Import CSV + scoring + persistance scores | ✅ Phase 2 |
| Export CSV/XLSX | ✅ Phase 2 |
| Données démo Albi | ✅ |
| Filtres CRM | ✅ |
| Analyse IA (templates locaux) | ✅ |
| Supabase schema + RLS | ✅ |
| Auth Supabase (inscription + connexion) | ✅ Phase 3 |
| Google Places via Edge Function | ✅ Phase 3 |
| Cache recherches Places (30 j) | ✅ Phase 3 |
| Enrichissement SIRENE + PageSpeed | ✅ |
| Edge Function IA | 🔲 Phase 7 |

## Scoring LocalHunter

| Composante | Poids |
|---|---|
| Décisionnaire accessible | /30 |
| Opportunité site web | /30 |
| Opportunité logiciel métier | /25 |
| Santé commerciale | /15 |

Sous-scores 0–5★ : SiteScore, SoftwareScore, EasyRestScore, AccessibilityScore, DigitalMaturityScore, FalsePositiveRisk.

## EasyRest

Offre ERP restauration propriétaire — scoring dédié pour bars, restaurants, snacks indépendants.

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
