ÉVOLUTION DU SCORING ET ENRICHISSEMENT DE LOCALHUNTER

Tu interviens sur le projet LocalHunter, une application de prospection B2B géolocalisée.

L’application utilise notamment :

une application cliente Flutter ;
un backend existant ;
Supabase/PostgreSQL ;
Google Places API ;
l’API SIRENE ;
un moteur de scoring assisté par IA ;
Google Play Billing ;
Google Cloud Pub/Sub ;
des outils de monitoring.

L’objectif est d’améliorer :

la pertinence du scoring en fonction de l’activité réelle de l’utilisateur ;
la quantité et la qualité des informations récupérées sur les prospects ;
l’explicabilité des scores ;
la confiance accordée aux données ;
l’apprentissage progressif à partir des actions de l’utilisateur.
RÈGLE ABSOLUE

Tu ne dois jamais commencer à coder directement.

Tu dois obligatoirement respecter le processus suivant :

Analyse
→ Questions
→ Hypothèses explicites
→ Options
→ Recommandation
→ Plan détaillé
→ Validation humaine
→ Implémentation progressive
→ Tests
→ Compte rendu

Aucune étape ne peut être sautée.

1. RÈGLES NON NÉGOCIABLES
1.1 Ne jamais modifier l’architecture existante sans autorisation

Tu dois préserver intégralement :

l’architecture globale du projet ;
la structure des dossiers ;
les frontières entre les couches ;
les conventions existantes ;
le système de dépendances ;
le système de navigation ;
les contrats entre le frontend et le backend ;
la stratégie d’authentification ;
la gestion actuelle de l’état ;
le système de persistence ;
le système de monitoring.

Tu n’as pas le droit de décider seul :

de migrer l’architecture ;
de créer une nouvelle couche ;
de déplacer des fichiers ;
de renommer des modules ;
de changer de gestionnaire d’état ;
de remplacer une librairie ;
de changer d’ORM ;
de réorganiser les domaines métier ;
d’introduire des microservices ;
de créer un nouveau backend parallèle.

Une modification architecturale ne peut être proposée que sous forme d’option documentée.

Elle ne peut être implémentée qu’après validation explicite.

1.2 Ne jamais modifier les routes existantes

Tu ne dois jamais :

renommer une route ;
supprimer une route ;
modifier son chemin ;
changer les paramètres obligatoires ;
modifier silencieusement les structures de réponse ;
modifier les codes HTTP existants ;
casser la compatibilité avec l’application Flutter ;
changer le format des DTO existants sans stratégie de compatibilité.

Les routes existantes doivent continuer à fonctionner exactement comme avant.

Si de nouvelles fonctionnalités nécessitent une évolution, proposer plusieurs possibilités :

Option A — Enrichir la réponse existante

Uniquement avec des champs optionnels et rétrocompatibles.

Option B — Ajouter une nouvelle route

Sans toucher à l’ancienne.

Option C — Ajouter une version d’API

Uniquement si cela est réellement nécessaire.

Tu dois demander validation avant de choisir.

1.3 Ne jamais supposer

Tu ne dois jamais supposer :

le framework backend utilisé ;
l’emplacement des services ;
le format actuel du scoring ;
la structure des tables Supabase ;
les noms des colonnes ;
les relations entre les entités ;
les quotas Google Places ;
les champs déjà récupérés ;
les droits disponibles sur les API ;
la présence d’une API BODACC ;
la présence d’un système de cache ;
l’existence d’un système de tâches asynchrones ;
la stratégie de retry ;
la logique de monitoring ;
le nombre de prospects traité par campagne ;
le modèle IA utilisé ;
les prompts actuels ;
la façon dont les erreurs sont remontées ;
les limites du plan Supabase ;
les contraintes RGPD déjà gérées.

Lorsqu’une information manque, tu dois poser une question.

Tu ne dois pas compléter les trous par une hypothèse silencieuse.

1.4 Toujours distinguer les faits des propositions

Dans toutes tes réponses, utilise ces catégories :

FAIT OBSERVÉ DANS LE CODE
INFORMATION MANQUANTE
HYPOTHÈSE À VALIDER
RISQUE
OPTION POSSIBLE
RECOMMANDATION

Aucune hypothèse ne doit être présentée comme un fait.

1.5 Aucun changement massif

Interdiction de produire :

une réécriture complète ;
une migration globale ;
un refactor transversal non demandé ;
une modification de dizaines de fichiers en une seule étape ;
un changement mêlant plusieurs fonctionnalités indépendantes.

Chaque changement doit être :

limité ;
réversible ;
testable ;
documenté ;
validé ;
compatible avec l’existant.
2. PREMIÈRE MISSION : AUDITER L’EXISTANT

Avant toute proposition, inspecte le projet.

Tu dois identifier précisément :

Architecture
point d’entrée ;
couches existantes ;
modules métier ;
services ;
repositories ;
modèles ;
DTO ;
gestion d’état Flutter ;
système de dépendances ;
clients HTTP ;
système d’erreurs ;
système de logging ;
système de monitoring.
Scoring
où le score est calculé ;
si le calcul est frontend ou backend ;
si l’IA attribue directement la note ;
quelles données entrent dans le scoring ;
comment les critères sont pondérés ;
si les règles sont persistées ;
si les résultats sont explicables ;
si les scores sont recalculables ;
si la version du scoring est enregistrée ;
comment les valeurs manquantes sont traitées.
Sources de données
Google Places ;
SIRENE ;
PageSpeed Insights ;
scraping ou analyse de sites ;
données saisies manuellement ;
données IA ;
sources supplémentaires déjà présentes.
Base de données
tables liées aux utilisateurs ;
campagnes ;
prospects ;
entreprises ;
scores ;
critères ;
feedback ;
abonnements ;
événements ;
historique.
Traitements
synchrones ou asynchrones ;
gestion des timeouts ;
retries ;
quotas ;
cache ;
déduplication ;
pagination ;
parallélisme ;
limitation de débit ;
reprise après erreur.
Sécurité et conformité
clés API ;
secrets ;
données personnelles ;
coordonnées professionnelles ;
politiques RLS Supabase ;
logs ;
stockage des réponses Google Places ;
durée de conservation ;
exposition des données au frontend.
Tests
tests unitaires ;
tests d’intégration ;
tests de contrats ;
tests end-to-end ;
mocks des APIs externes ;
couverture du scoring.

Tu dois produire un rapport avant d’écrire du code.

3. FORMAT DU RAPPORT INITIAL

Le premier livrable doit avoir exactement cette structure :

3.1 Résumé de l’existant

Décrire uniquement ce qui a été réellement observé.

3.2 Schéma du flux actuel

Exemple de format :

Utilisateur
→ création campagne
→ définition grille
→ récupération entreprises
→ enrichissement
→ scoring
→ persistance
→ affichage

Le schéma doit correspondre au code réel.

3.3 Points forts

Identifier les éléments déjà bien conçus.

3.4 Limites actuelles

Classer les limites par catégorie :

pertinence métier ;
qualité des données ;
performance ;
coût ;
sécurité ;
maintenabilité ;
explicabilité ;
observabilité.
3.5 Informations manquantes

Créer une liste de questions précises.

3.6 Risques de régression

Lister les fonctionnalités qui pourraient être affectées.

3.7 Options d’évolution

Présenter plusieurs options, sans coder.

4. QUESTIONS OBLIGATOIRES AVANT TOUT CODE

Tu dois au minimum demander confirmation sur les points suivants.

Utilisateur et offre
Comment l’utilisateur décrit-il actuellement son activité ?
Décrit-il son offre ou seulement sa cible ?
Peut-il définir plusieurs offres ?
Une campagne correspond-elle à une offre précise ?
Les critères sont-ils réutilisables entre campagnes ?
L’utilisateur peut-il modifier les pondérations ?
Doit-il comprendre chaque critère ?
Scoring
Le score actuel est-il entièrement généré par l’IA ?
L’IA produit-elle les critères, les poids ou directement la note ?
Existe-t-il des règles éliminatoires ?
Le score doit-il rester sur 100 ?
Faut-il conserver l’ancien score ?
Faut-il versionner les moteurs de scoring ?
Le score doit-il être recalculé quand les données changent ?
Quelle donnée est considérée comme prioritaire en cas de contradiction ?
Sources
Quels champs Google Places sont actuellement demandés ?
Quels champs SIRENE sont actuellement stockés ?
PageSpeed Insights est-il déjà intégré ?
Existe-t-il déjà une analyse du site web ?
BODACC peut-il être ajouté ?
L’utilisateur accepte-t-il des temps de traitement plus longs ?
Quel est le budget maximal d’API par campagne ?
Combien de prospects sont enrichis par campagne ?
Les données doivent-elles être actualisées à chaque campagne ?
Données et conformité
Les données Google Places sont-elles stockées ?
Quelle est la politique de conservation ?
Les coordonnées personnelles sont-elles interdites ?
Seuls les emails professionnels doivent-ils être conservés ?
Quelle politique RGPD est déjà appliquée ?
Les sources doivent-elles être affichées à l’utilisateur ?
Feedback et apprentissage
Quelles actions utilisateur sont déjà enregistrées ?
Existe-t-il un statut prospect ?
Faut-il suivre les rendez-vous et conversions ?
L’ajustement des poids doit-il être automatique ou suggéré ?
L’utilisateur doit-il valider chaque modification du scoring ?
UX
Où afficher les sous-scores ?
Où afficher l’indice de confiance ?
Où afficher les raisons positives et négatives ?
Combien d’informations peut contenir la fiche prospect ?
Les données manquantes doivent-elles être visibles ?

Tu ne dois pas coder tant que les questions bloquantes n’ont pas reçu de réponse.

5. ÉVOLUTIONS FONCTIONNELLES À ÉTUDIER

Les fonctionnalités suivantes doivent être analysées, mais pas obligatoirement toutes implémentées.

5.1 Profil commercial de l’utilisateur

Étudier l’ajout d’un profil structuré :

offre
type de client cible
problème résolu
panier moyen
zone d’intervention
taille de client recherchée
signaux positifs
signaux négatifs
critères éliminatoires

L’IA peut convertir une description libre en structure, mais le résultat doit être :

visible ;
modifiable ;
validé par l’utilisateur ;
persisté ;
versionné si nécessaire.

Ne jamais utiliser directement une sortie IA non validée pour modifier les scores en production.

5.2 Décomposition du score

Étudier la séparation du score en sous-scores.

Exemple :

score_adéquation
score_besoin
score_accessibilité
score_stabilité
score_final
indice_confiance

Ne pas imposer ce modèle.

Comparer plusieurs possibilités.

Possibilité A

Trois sous-scores :

adéquation
besoin
opportunité
Possibilité B

Quatre sous-scores :

adéquation
besoin
accessibilité
stabilité
Possibilité C

Score par catégories configurables.

Pour chaque option, préciser :

avantages ;
inconvénients ;
impact base de données ;
impact API ;
impact UI ;
compatibilité avec l’existant ;
coût d’implémentation.
5.3 Règles de scoring

Le moteur doit pouvoir distinguer :

BOOST
PENALTY
EXCLUSION

Exemples :

+15 : site absent
+10 : plus de 100 avis
-20 : entreprise trop récente
EXCLUSION : établissement fermé

Ne pas coder un moteur générique avant d’avoir inspecté la structure actuelle.

Étudier si l’existant permet :

des règles configurables ;
des pondérations ;
des seuils ;
des opérateurs ;
des règles composées ;
des valeurs manquantes ;
des règles sectorielles.
5.4 Indice de confiance

Étudier un indice indépendant du score métier.

Il pourrait prendre en compte :

nombre de sources ;
fraîcheur ;
concordance ;
qualité du rapprochement SIRENE/Google ;
disponibilité des champs importants ;
fiabilité de la source ;
ambiguïté des données.

Exemple :

score : 84/100
confiance : 72/100
données : 11/16

Le score ne doit pas être artificiellement augmenté parce que peu de données sont présentes.

5.5 Explication du score

Chaque score doit pouvoir fournir une liste de contributions :

{
  "criterion": "website_performance",
  "value": 42,
  "weight": 0.18,
  "contribution": 12,
  "source": "pagespeed",
  "explanation_key": "slow_mobile_website"
}

Les noms sont indicatifs.

Tu dois utiliser les conventions du projet.

L’explication affichée peut être générée à partir de règles déterministes.

L’IA peut uniquement produire une synthèse lisible à partir des preuves.

Elle ne doit pas inventer de justification.

6. ENRICHISSEMENT DES PROSPECTS
6.1 SIRENE

Étudier les données disponibles dans l’intégration actuelle :

SIREN ;
SIRET ;
activité NAF ;
date de création ;
état administratif ;
siège ou établissement secondaire ;
tranche d’effectifs ;
catégorie juridique ;
caractère employeur ;
enseigne ;
nom commercial ;
nombre d’établissements actifs.

Ne jamais supposer que tous les champs sont accessibles.

Vérifier :

réponse API réelle ;
contrat actuel ;
mapping existant ;
stockage ;
données facultatives.
6.2 Google Places

Auditer le field mask existant.

Classer les champs par niveau d’utilité et coût.

Niveau 1 — Recherche initiale
identifiant ;
nom ;
catégorie ;
localisation ;
statut.
Niveau 2 — Qualification
téléphone ;
site web ;
horaires ;
note ;
nombre d’avis.
Niveau 3 — Enrichissement ciblé
services ;
réservation ;
livraison ;
prix ;
accessibilité ;
photos ;
options de paiement ;
attributs sectoriels.

Proposer un pipeline économique.

Exemple :

100 entreprises détectées
→ 50 qualifiées avec données de base
→ 20 enrichies
→ 10 analysées profondément

Ne pas implémenter cette répartition sans validation.

6.3 BODACC

Étudier la possibilité d’ajouter :

créations ;
modifications ;
cessions ;
procédures collectives ;
radiations ;
dépôts de comptes publics ;
événements récents.

Avant toute implémentation :

vérifier l’accès ;
vérifier les conditions d’utilisation ;
vérifier la stabilité de l’API ;
définir les règles de rapprochement ;
définir la fréquence d’actualisation ;
définir les événements utiles au scoring.
6.4 Analyse du site web

Étudier une analyse progressive.

Analyse légère
statut HTTP ;
HTTPS ;
redirection ;
titre ;
meta description ;
H1 ;
mobile viewport ;
formulaire ;
téléphone cliquable ;
email public ;
liens sociaux ;
bouton de réservation ;
sitemap ;
robots.txt ;
données structurées.
Analyse approfondie
PageSpeed ;
accessibilité ;
performance ;
SEO ;
technologies détectées ;
conversion ;
cohérence des coordonnées ;
fraîcheur apparente du contenu.

Ne pas lancer une analyse lourde pour tous les prospects sans stratégie de coût et de file d’attente.

6.5 Cohérence entre sources

Étudier un moteur de détection d’incohérences.

Exemples :

adresse Google différente de SIRENE ;
établissement ouvert sur Google mais cessé dans SIRENE ;
téléphone différent ;
site absent dans Google mais trouvé ailleurs ;
raison sociale différente de l’enseigne ;
correspondance SIRET incertaine.

Chaque incohérence doit avoir :

un type ;
une gravité ;
des sources ;
une explication ;
un impact éventuel sur la confiance.
7. APPRENTISSAGE PAR FEEDBACK UTILISATEUR

Étudier les statuts suivants :

à étudier
à contacter
non pertinent
déjà équipé
trop petit
franchise
hors cible
contacté
sans réponse
rendez-vous obtenu
proposition envoyée
client gagné
client perdu

Ne pas imposer ces statuts.

Comparer avec les statuts existants.

Les données de feedback peuvent servir à calculer :

taux de sélection par critère ;
taux de contact ;
taux de réponse ;
taux de rendez-vous ;
taux de conversion ;
performance par modèle de scoring.

L’ajustement automatique ne doit pas modifier silencieusement les poids.

Le système doit proposer :

Les prospects retenus par l’utilisateur présentent souvent ces caractéristiques. Souhaitez-vous modifier la grille ?

L’utilisateur doit valider.

8. ARCHITECTURE LOGIQUE CIBLE À RESPECTER

Sans modifier l’architecture actuelle, rechercher l’équivalent fonctionnel de ce flux :

Sources externes
→ données brutes
→ normalisation
→ données calculées
→ moteur de règles
→ sous-scores
→ indice de confiance
→ explications
→ synthèse IA
→ persistance
→ présentation
→ feedback utilisateur

Cette représentation est conceptuelle.

Tu dois adapter la proposition à l’architecture existante.

Tu ne dois pas créer automatiquement un dossier ou un service pour chaque étape.

9. OPTIONS À PRÉSENTER AVANT IMPLÉMENTATION

Pour chaque évolution, présenter au moins trois niveaux.

Option minimale
faible risque ;
peu de fichiers modifiés ;
rétrocompatible ;
rapidement testable.
Option intermédiaire
plus structurante ;
meilleure évolutivité ;
impact modéré.
Option complète
architecture fonctionnelle complète ;
plus de données ;
plus de tests ;
coût et délai supérieurs.

Exemple de tableau attendu :

Option	Périmètre	Avantages	Risques	Impact API	Impact DB	Effort
A	Sous-scores calculés à la volée	Rapide	Historique limité	Faible	Aucun	Faible
B	Sous-scores persistés	Traçabilité	Migration DB	Moyen	Moyen	Moyen
C	Moteur versionné	Évolutif	Complexité	Moyen	Fort	Fort

Ne pas choisir seul.

10. PLAN D’IMPLÉMENTATION OBLIGATOIRE

Après validation d’une option, produire un plan comme celui-ci :

Phase 1 — Contrats et tests de caractérisation
documenter le comportement actuel ;
créer les tests protégeant l’existant ;
vérifier les routes ;
vérifier les formats de réponse ;
vérifier les calculs actuels.
Phase 2 — Modèle minimal
ajouter uniquement les champs validés ;
préserver les anciens champs ;
préparer la compatibilité.
Phase 3 — Logique métier
implémenter les calculs ;
gérer les valeurs manquantes ;
gérer les exclusions ;
rendre le calcul déterministe.
Phase 4 — Intégrations externes
ajout progressif ;
timeout ;
retry ;
rate limiting ;
cache ;
gestion des erreurs.
Phase 5 — UI
sous-scores ;
confiance ;
explications ;
données manquantes ;
sources.
Phase 6 — Monitoring
succès et erreurs par source ;
temps de traitement ;
coûts ou appels ;
données manquantes ;
taux de matching ;
files d’attente.
Phase 7 — Validation
tests unitaires ;
tests intégration ;
tests de contrat ;
tests de non-régression ;
test sur campagne réelle contrôlée.

Chaque phase doit nécessiter une validation avant la suivante si elle modifie un contrat ou des données persistées.

11. STRATÉGIE DE TESTS

Tu dois proposer des tests avant l’implémentation.

Tests du scoring
critère positif ;
pénalité ;
exclusion ;
données manquantes ;
données contradictoires ;
poids à zéro ;
score minimum ;
score maximum ;
arrondi ;
ordre des règles ;
reproductibilité ;
ancien format de grille ;
nouvelle grille.
Tests des sources
réponse complète ;
réponse partielle ;
timeout ;
quota dépassé ;
erreur 401 ;
erreur 403 ;
erreur 429 ;
erreur 500 ;
schéma inattendu ;
établissement non trouvé ;
correspondance ambiguë.
Tests de routes
comportement actuel inchangé ;
champs existants inchangés ;
nouveaux champs optionnels ;
erreurs compatibles ;
authentification inchangée.
Tests frontend
chargement ;
erreur ;
données partielles ;
confiance faible ;
absence d’explication ;
exclusion ;
traduction ;
accessibilité ;
responsive.
12. OBSERVABILITÉ

Toute nouvelle source ou logique doit produire des métriques exploitables.

Étudier les métriques suivantes en respectant les conventions actuelles :

enrichment_requests_total
enrichment_failures_total
enrichment_duration_seconds
scoring_calculations_total
scoring_failures_total
scoring_confidence
source_data_completeness
sirene_match_success_total
google_places_match_success_total
bodacc_match_success_total
website_analysis_failures_total

Ne jamais utiliser comme labels :

email ;
nom d’entreprise ;
SIREN ;
SIRET ;
utilisateur ;
URL ;
token ;
identifiant unique.

Préférer des labels à faible cardinalité :

source
status
error_type
campaign_type
scoring_version
13. SÉCURITÉ ET DONNÉES

Tu dois vérifier avant chaque intégration :

secrets uniquement côté serveur ;
aucune clé dans Flutter ;
aucune donnée sensible dans les logs ;
aucune sortie IA non filtrée ;
validation des réponses externes ;
validation des entrées utilisateur ;
timeouts obligatoires ;
taille maximale des réponses ;
protection contre les redirections malveillantes ;
prévention SSRF pour l’analyse de sites ;
blocage des adresses locales et privées ;
conformité aux conditions des fournisseurs ;
politique de conservation.

Pour l’analyse de sites, interdire les requêtes vers :

localhost
127.0.0.0/8
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
169.254.0.0/16
::1
réseaux privés IPv6
métadonnées cloud

Ne pas implémenter un crawler avant validation des règles de sécurité.

14. FORMAT DE TES RÉPONSES

Chaque réponse doit respecter cette structure :

Ce que j’ai observé

Uniquement les faits du code.

Ce que je ne sais pas encore

Informations manquantes.

Questions bloquantes

Questions auxquelles il faut répondre avant de coder.

Options

Au moins deux options si une décision technique existe.

Recommandation

Une recommandation argumentée, sans la présenter comme obligatoire.

Impact attendu
fichiers ;
routes ;
base ;
UI ;
tests ;
sécurité ;
performance ;
coût.
Étape suivante proposée

Une seule étape, clairement délimitée.

15. INTERDICTION DE CODER SANS VALIDATION

Tu dois terminer la première analyse par cette phrase :

Je n’ai encore modifié aucun fichier. J’attends tes réponses et ton arbitrage sur les options proposées avant de commencer l’implémentation.

Tu ne dois produire aucun patch, aucun diff et aucun code d’implémentation avant cette validation.

16. PREMIÈRE TÂCHE À EXÉCUTER

Commence maintenant par :

analyser le dépôt complet ;
identifier l’architecture et les conventions ;
localiser le scoring actuel ;
localiser les intégrations Google Places et SIRENE ;
localiser les modèles et tables liés aux campagnes et prospects ;
identifier les routes concernées ;
identifier les tests existants ;
identifier les points de compatibilité à préserver ;
produire le rapport initial ;
poser les questions bloquantes ;
proposer trois scénarios d’évolution :
minimal ;
intermédiaire ;
complet.

Ne modifie aucun fichier.

Ne génère aucun code.

Ne crée aucune migration.

Ne crée aucune route.

Ne change aucun contrat.

Attends mon arbitrage.