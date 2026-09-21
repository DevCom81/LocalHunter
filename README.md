# LocalHunter

**Prospection B2B géolocalisée, qualification multi-source et scoring explicable.**

LocalHunter aide les indépendants, commerciaux et entreprises B2B à identifier les prospects qui correspondent réellement à leur offre.

L'application ne se contente pas de rechercher des entreprises. Elle croise plusieurs sources, rapproche les établissements, enrichit les données disponibles puis applique une grille de qualification configurable pour distinguer l'adéquation commerciale du prospect et l'opportunité détectée.

## Du prospect brut à la décision commerciale

```text
Google Places ─┐
               ├─> Discovery ─> Résolution / déduplication ─┐
SIRENE ────────┘                                            │
                                                            ▼
                                             Enrichissement adaptatif
                                                            │
                           ┌────────────┬────────────┬────────┼───────────┐
                           ▼            ▼            ▼        ▼           ▼
                        SIRENE       Company       BODACC   Website    PageSpeed
                                                            │
                                                            ▼
                                                   Signaux normalisés
                                                            │
                                                            ▼
                                                Scoring déterministe
                                                   FIT / OPPORTUNITY
                                                            │
                                                            ▼
                                             Score + confiance + explication
                                                            │
                                                            ▼
                                                           CRM
                                                            │
                                                            ▼
                                               Feedback utilisateur
```

## Fonctionnalités principales

### Discovery multi-source

Une campagne peut rechercher des entreprises à partir de plusieurs sources complémentaires.

Google Places fournit principalement les informations commerciales et locales.

SIRENE apporte l'identité légale des établissements et entreprises françaises.

LocalHunter rapproche ensuite les candidats issus des différentes sources à l'aide d'un resolver déterministe prenant notamment en compte SIREN/SIRET, nom, adresse, code postal et ville.

Les rapprochements incertains restent identifiables au lieu d'être silencieusement considérés comme fiables.

### Enrichissement adaptatif

Toutes les campagnes n'ont pas besoin des mêmes données.

LocalHunter détermine les enrichissements nécessaires à partir de la grille de scoring utilisée et peut solliciter :

- SIRENE
- Recherche d'entreprises
- BODACC
- site web
- réseaux sociaux
- PageSpeed Insights

Les providers fonctionnent en pipeline avec cache, limitation des appels et stratégie best-effort : l'échec d'une source ne bloque pas les autres.

### Scoring B2B configurable

Chaque campagne utilise une grille correspondant à l'offre commerciale recherchée.

Le moteur distingue deux dimensions :

**FIT**

Le prospect correspond-il structurellement à la cible recherchée ?

**OPPORTUNITY**

Les données disponibles indiquent-elles une opportunité commerciale particulière ?

Le score final reste déterministe et peut être recalculé à partir des mêmes données et de la même configuration.

### Score explicable

Un score seul est peu utile s'il est impossible de comprendre son origine.

LocalHunter conserve les contributions des différents critères et fournit :

- score global
- score FIT
- score OPPORTUNITY
- critères ayant contribué au résultat
- données manquantes
- avertissements
- niveau de confiance

Le niveau de confiance est volontairement distinct du score : un prospect peut obtenir un score élevé avec peu de données disponibles sans que cette incertitude soit masquée.

## L'IA propose, le moteur décide

L'IA n'attribue pas directement les scores aux prospects.

Elle peut aider l'utilisateur à transformer son activité, son offre et sa cible commerciale en profil de prospection puis proposer une grille de scoring.

Le processus reste contrôlé :

```text
Profil commercial
      ↓
Proposition IA
      ↓
Validation du profil
      ↓
Validation des critères mesurables
      ↓
Grille de scoring
      ↓
Scoring déterministe
```

Les critères générés sont validés avant utilisation et doivent correspondre à des données réellement mesurables par LocalHunter.

Cette séparation permet de profiter de l'IA pour la configuration sans rendre la décision finale opaque ou non reproductible.

## CRM et boucle de feedback

LocalHunter intègre un CRM léger permettant notamment de classer les prospects :

- à étudier
- à contacter
- contacté
- sans réponse
- intéressé
- rendez-vous
- proposition
- gagné
- perdu
- non pertinent
- déjà équipé
- trop petit
- chaîne / franchise
- hors cible

Les résultats commerciaux peuvent ensuite être analysés pour proposer des ajustements de pondération.

Ces suggestions ne modifient jamais automatiquement la grille. L'utilisateur peut les accepter ou les ignorer.

## Provenance et qualité des données

Toutes les informations n'ont pas la même valeur.

LocalHunter distingue les données observées et les signaux calculés et conserve autant que possible leur provenance et leur niveau de confiance.

Le système gère également plusieurs situations ambiguës :

- correspondance incertaine entre établissement commercial et entreprise légale
- données absentes
- sources contradictoires
- établissement potentiellement fermé
- annonces BODACC nécessitant confirmation
- site inaccessible
- enrichissement externe temporairement indisponible

L'absence d'information n'est pas transformée artificiellement en signal positif.

## Sources utilisées

Selon la campagne et la grille configurée :

- Google Places
- SIRENE / INSEE
- Recherche d'entreprises
- BODACC
- PageSpeed Insights
- sites web publics des entreprises

Les appels externes sont mis en cache lorsque cela est pertinent afin de limiter les coûts, la latence et les requêtes inutiles.

## Architecture technique

LocalHunter est principalement construit avec :

### Application

- Flutter / Dart
- Riverpod
- navigation déclarative
- Android, Web et Desktop

### Backend

- Supabase
- PostgreSQL
- Supabase Auth
- Edge Functions TypeScript
- Row Level Security

### Intégrations

- Google Places API
- APIs publiques françaises
- PageSpeed Insights
- Google Play Billing
- Firebase Hosting

L'application est organisée par fonctionnalités avec séparation entre domaine, données et présentation lorsque la complexité métier le justifie.

Le pipeline d'enrichissement côté Edge repose sur des providers indépendants partageant des contrats communs.

## Exemple de qualification

Une entreprise peut présenter :

```text
Google Places
Nom commercial
Adresse
Téléphone
Note et avis
Site web
        │
        ▼
SIRENE
SIRET / SIREN
Activité NAF
État administratif
Date de création
        │
        ▼
Recherche d'entreprises
Effectif
Nombre d'établissements
Données financières disponibles
        │
        ▼
BODACC
Événements légaux récents
        │
        ▼
Website / PageSpeed
Présence web
Réseaux sociaux
Performance du site
        │
        ▼
Scoring
FIT
OPPORTUNITY
Confiance
Explication
```

La grille décide quelles données sont pertinentes pour la campagne.

## Tests

Le projet comporte notamment des tests autour de :

- scoring configurable
- neutralité des grilles B2B
- séparation FIT / OPPORTUNITY
- validation des critères générés
- feedback CRM
- rapprochement de candidats multi-source
- qualité du matching SIRENE
- analyse des sites web
- statuts Google Business
- sérialisation des prospects enrichis
- authentification et règles liées aux plateformes

L'objectif est de tester en priorité les décisions métier et les zones où une mauvaise correspondance pourrait produire une qualification commerciale incorrecte.

## Authentification

L'authentification repose sur Supabase Auth.

LocalHunter prend également en charge la mémorisation de connexion et, sur les plateformes compatibles, une authentification biométrique locale permettant de protéger l'accès aux identifiants enregistrés de manière sécurisée.

La biométrie constitue ici une protection locale des credentials et non un remplacement de l'authentification Supabase.

## Import et export

Les prospects peuvent également provenir d'un fichier CSV.

Ils rejoignent ensuite le même processus de qualification et de scoring que les prospects découverts automatiquement.

Les données CRM peuvent être exportées pour être exploitées dans d'autres outils commerciaux.

## Documentation technique

La documentation détaillée du pipeline d'enrichissement se trouve dans :

```text
docs/DEVELOPMENT.md
docs/ENRICHMENT_PIPELINE_FUTURE.md
```

Les règles utilisées pour encadrer le développement assisté par IA sont documentées dans :

```text
RULES.md
```

Le principe central est simple : l'agent peut analyser, challenger et proposer des solutions, mais les décisions architecturales restent sous validation humaine.

## État du projet

LocalHunter est un projet actif.

Le produit a évolué d'un outil de prospection locale spécialisé vers un moteur de qualification B2B configurable. Certaines parties historiques restent volontairement présentes pendant cette transition et font l'objet d'une migration progressive afin d'éviter une réécriture risquée du cœur fonctionnel.

---

**LocalHunter est développé par DevCom81.**
