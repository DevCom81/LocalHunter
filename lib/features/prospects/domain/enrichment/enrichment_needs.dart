import '../../../scoring/domain/entities/criterion_rule.dart';
import '../../../scoring/domain/entities/scoring_grid.dart';

/// Providers d'enrichissement requis par une grille de scoring.
///
/// Phase 3 + 11 : dérivation conservative.
/// - SIRENE + company toujours.
/// - website / pagespeed / social seulement si la grille les exploite.
/// - bodacc seulement si un critère BODACC a un poids > 0.
class EnrichmentNeeds {
  const EnrichmentNeeds({
    required this.sirene,
    required this.company,
    required this.website,
    required this.pagespeed,
    required this.social,
    required this.bodacc,
  });

  final bool sirene;
  final bool company;
  final bool website;
  final bool pagespeed;

  /// Analyse des liens sociaux sur le HTML du site (pas d'IA).
  final bool social;
  final bool bodacc;

  /// Payload pour `enrich-prospects` (sans bodacc — route séparée).
  List<String> get enrichProspectsProviders => [
        if (sirene) 'sirene',
        if (company) 'company',
        if (website || social) 'website',
        if (pagespeed) 'pagespeed',
        if (social) 'social',
      ];

  /// Défaut historique = tout activer.
  static const all = EnrichmentNeeds(
    sirene: true,
    company: true,
    website: true,
    pagespeed: true,
    social: true,
    bodacc: true,
  );

  static const _socialFields = {
    'facebook_url',
    'instagram_url',
    'linkedin_url',
    'tiktok_url',
    'youtube_url',
    'x_url',
    'facebook_detected',
    'instagram_detected',
    'linkedin_detected',
    'tiktok_detected',
    'youtube_detected',
    'x_detected',
    'social_presence_detected',
    'social_network_count',
  };

  static EnrichmentNeeds fromGrid(ScoringGrid grid) {
    var needsWebPresence = false;
    var needsPagespeed = false;
    var needsBodacc = false;
    var needsSocial = false;

    for (final c in grid.criteria) {
      if (!c.isActive || c.maxPoints <= 0) continue;

      final field = c.rule.field;
      if (field == 'pagespeed_score') needsPagespeed = true;
      if (field != null && field.startsWith('bodacc_')) needsBodacc = true;
      if (c.key.startsWith('bodacc_')) needsBodacc = true;
      if (field != null && _socialFields.contains(field)) needsSocial = true;
      if (c.key.startsWith('social_') ||
          c.key.contains('facebook') ||
          c.key.contains('instagram') ||
          c.key.contains('linkedin')) {
        needsSocial = true;
      }

      if (c.key == 'website_opportunity' || c.key == 'site_score') {
        needsPagespeed = true;
        needsWebPresence = true;
      }
      if (c.key == 'digital_maturity') {
        needsWebPresence = true;
        needsSocial = true;
      }

      if (c.rule.type == CriterionRuleType.legacy) {
        final sk = c.rule.scorerKey ?? c.key;
        if (sk == 'website_opportunity') {
          needsPagespeed = true;
          needsWebPresence = true;
        }
        if (sk == 'digital_maturity') {
          needsWebPresence = true;
          needsSocial = true;
        }
      }
    }

    for (final r in grid.exclusionConfig.rules) {
      if (r.type == 'website_pattern') needsWebPresence = true;
    }
    for (final r in grid.recommendationConfig.rules) {
      if (r.criterionKey != 'site_score') continue;
      final scoresSite = grid.criteria.any(
        (c) =>
            c.isActive &&
            c.maxPoints > 0 &&
            (c.key == 'site_score' ||
                c.key == 'website_opportunity' ||
                c.rule.scorerKey == 'website_opportunity'),
      );
      if (scoresSite) {
        needsPagespeed = true;
        needsWebPresence = true;
      }
    }

    final website = needsWebPresence || needsPagespeed || needsSocial;
    final pagespeed = needsPagespeed;

    return EnrichmentNeeds(
      sirene: true,
      company: true,
      website: website,
      pagespeed: pagespeed,
      social: needsSocial,
      bodacc: needsBodacc,
    );
  }
}
