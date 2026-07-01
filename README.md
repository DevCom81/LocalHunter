# LocalHunter

Application Flutter (web, desktop, mobile) pour la prospection locale B2B — identifier les entreprises locales les plus susceptibles de devenir clientes.

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
2. Appliquer les migrations (001 → 003) :

```bash
supabase db push
# ou exécuter supabase/migrations/*.sql dans le SQL Editor
```

La migration **003** ajoute les tables `scoring_grids` / `scoring_criteria` et la colonne `campaigns.scoring_grid_id`. À la première connexion, l'app provisionne automatiquement les grilles modèles (LocalHunter Default, EasyRest Restauration) pour l'utilisateur.

3. Créer un compte via **Créer un compte** dans l'app, ou via Supabase Dashboard → Authentication

4. Déployer l'Edge Function Google Places :

```bash
supabase secrets set GOOGLE_PLACES_API_KEY=votre_cle
supabase functions deploy search-places
```

La function vérifie le cache PostgreSQL (`places_search_cache`, TTL 30 jours) avant chaque appel Google.

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
| SIRENE | 🔲 Phase 4+ |
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

## Enrichissement futur

- **SIRENE** (INSEE) — données légales
- **Google Places API** — notes, avis, coordonnées

Stubs présents dans `features/prospects/data/adapters/`.

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
