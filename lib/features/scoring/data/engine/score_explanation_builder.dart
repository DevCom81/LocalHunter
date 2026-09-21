import '../../../prospects/domain/entities/prospect.dart';
import '../../domain/entities/criterion_rule.dart';
import '../../domain/entities/prospect_score.dart';
import '../../domain/entities/score_confidence.dart';
import '../../domain/entities/score_contribution.dart';
import '../../domain/entities/score_explanation.dart';
import '../../domain/entities/score_explanation_labels.dart';
import '../../domain/entities/scoring_grid.dart';

/// Construit une [ScoreExplanation] à la volée (pas de persistance).
///
/// Formule de confiance (validée A1) :
/// - complétude des 8 champs clés → jusqu'à 50 pts
/// - match SIRENE (siren/siret) → +30
/// - finances présentes si SIREN connu → +20
/// - pénalité contradiction « fermé SIRENE mais listé » → −25
/// - résultat clampé 0–100
class ScoreExplanationBuilder {
  static const keyFields = <String>[
    'address',
    'phone',
    'website',
    'siret',
    'manager_name',
    'annual_revenue',
    'pagespeed_score',
    'creation_date',
  ];

  ScoreExplanation build({
    required Prospect prospect,
    required ProspectScore score,
    required ScoringGrid grid,
  }) {
    return ScoreExplanation(
      globalScore: score.globalScore,
      confidence: _confidence(prospect),
      contributions: _contributions(score, grid),
    );
  }

  ScoreConfidence _confidence(Prospect prospect) {
    final missing = keyFields.where((f) => !_hasKeyField(prospect, f)).toList();
    final filled = keyFields.length - missing.length;
    final hasSirene = _nonEmpty(prospect.siren) || _nonEmpty(prospect.siret);
    final hasFinances = prospect.annualRevenue != null;
    final closedListed = _isSireneClosedListed(prospect);
    final googleClosed = prospect.isGoogleClosed;
    // Contradiction : Google dit fermé, SIRENE ne l'a pas exclu → avertissement
    // (SIRENE prime : on n'exclut pas sur Google seul).
    final googleClosedSireneOpen =
        googleClosed && !closedListed && !prospect.isExcluded;

    var points = ((filled / keyFields.length) * 50).round();
    if (hasSirene) points += 30;
    if (hasSirene && hasFinances) points += 20;
    if (closedListed) points -= 25;
    if (prospect.sireneMatchAmbiguous) points -= 10;
    final matchScore = prospect.sireneMatchScore;
    if (hasSirene && matchScore != null && matchScore < 70) points -= 5;
    if (googleClosedSireneOpen) points -= 5;

    return ScoreConfidence(
      score: points.clamp(0, 100),
      filledFields: filled,
      totalFields: keyFields.length,
      missingFields: missing,
      missingFieldLabels:
          missing.map(ScoreExplanationLabels.field).toList(growable: false),
      warnings: [
        if (closedListed)
          const ScoreWarning(
            type: 'sirene_closed_listed',
            message:
                'SIRENE indique un établissement fermé alors que le prospect '
                'reste listé (Google / campagne). SIRENE prime.',
            severity: ScoreWarningSeverity.critical,
          ),
        if (googleClosedSireneOpen)
          ScoreWarning(
            type: 'google_closed_sirene_open',
            message:
                'Google indique « ${_googleStatusFr(prospect.googleBusinessStatus!)} » '
                'mais SIRENE ne confirme pas la fermeture. SIRENE prime : '
                'vérification manuelle conseillée.',
            severity: ScoreWarningSeverity.warning,
          ),
        if (prospect.sireneMatchAmbiguous)
          const ScoreWarning(
            type: 'sirene_ambiguous',
            message:
                'Rapprochement SIRENE ambigu : plusieurs établissements '
                'proches. Vérifiez le SIRET manuellement.',
            severity: ScoreWarningSeverity.warning,
          ),
        if (hasSirene && matchScore != null && matchScore < 70)
          ScoreWarning(
            type: 'sirene_low_match',
            message:
                'Qualité de rapprochement SIRENE modérée ($matchScore/100).',
            severity: ScoreWarningSeverity.info,
          ),
        if (hasSirene && !hasFinances)
          const ScoreWarning(
            type: 'finances_missing',
            message:
                'SIREN connu mais chiffre d\'affaires indisponible '
                '(bilan INPI non publié ou non trouvé).',
            severity: ScoreWarningSeverity.info,
          ),
        if (!hasSirene)
          const ScoreWarning(
            type: 'sirene_unmatched',
            message: 'Aucun rapprochement SIRENE (SIREN/SIRET absents).',
            severity: ScoreWarningSeverity.warning,
          ),
        if (prospect.hasWebsite && prospect.websiteReachable == false)
          const ScoreWarning(
            type: 'website_unreachable',
            message:
                'URL de site présente mais injoignable (timeout, erreur HTTP '
                'ou refus SSRF). Opportunité web à confirmer manuellement.',
            severity: ScoreWarningSeverity.warning,
          ),
        if (prospect.hasWebsite &&
            prospect.websiteReachable == true &&
            prospect.websiteHasViewport == false)
          const ScoreWarning(
            type: 'website_no_viewport',
            message:
                'Site joignable sans meta viewport : expérience mobile '
                'probablement faible.',
            severity: ScoreWarningSeverity.info,
          ),
        if (prospect.bodaccHasCollectiveProceeding == true)
          const ScoreWarning(
            type: 'bodacc_collective_proceeding',
            message:
                'BODACC signale une procédure collective récente. '
                'Prudence commerciale — aucune exclusion automatique.',
            severity: ScoreWarningSeverity.critical,
          ),
        if (prospect.bodaccRadiationStatus == 'review')
          const ScoreWarning(
            type: 'bodacc_radiation_review',
            message:
                'Radiation BODACC détectée sans concordance SIRENE claire. '
                'Vérification manuelle conseillée.',
            severity: ScoreWarningSeverity.warning,
          ),
        if (prospect.bodaccRadiationStatus == 'excluded')
          const ScoreWarning(
            type: 'bodacc_radiation_excluded',
            message:
                'Radiation BODACC concordante avec SIRENE : prospect exclu.',
            severity: ScoreWarningSeverity.critical,
          ),
        if (prospect.bodaccHasLiquidation == true)
          const ScoreWarning(
            type: 'bodacc_liquidation',
            message: 'BODACC signale une liquidation récente.',
            severity: ScoreWarningSeverity.critical,
          ),
      ],
    );
  }

  String _googleStatusFr(String status) {
    return switch (status) {
      'CLOSED_TEMPORARILY' => 'fermé temporairement',
      'CLOSED_PERMANENTLY' => 'fermé définitivement',
      _ => status,
    };
  }

  List<ScoreContribution> _contributions(
    ProspectScore score,
    ScoringGrid grid,
  ) {
    final totalMax = grid.totalMax;
    final out = <ScoreContribution>[];

    for (final c in grid.criteria) {
      if (!c.isActive || c.kind != CriterionKind.component) continue;
      // Critères à poids 0 (ex. BODACC optionnels) : invisibles jusqu'à activation.
      if (c.maxPoints <= 0) continue;
      final pts = score.componentScores[c.key] ?? 0;
      final contribution =
          totalMax > 0 ? ((pts / totalMax) * 100).round() : 0;
      final key = _explanationKey(c.key, pts, c.maxPoints);
      final source = _sourceFor(c);
      out.add(
        ScoreContribution(
          criterionKey: c.key,
          label: c.label,
          value: pts,
          maxPoints: c.maxPoints,
          contribution: contribution,
          source: source,
          sourceLabel: ScoreExplanationLabels.source(source),
          explanationKey: key,
          explanation: ScoreExplanationLabels.explanation(
            explanationKey: key,
            criterionLabel: c.label,
            value: pts,
            maxPoints: c.maxPoints,
          ),
          isPositive: pts > 0,
        ),
      );
    }
    return out;
  }

  String _sourceFor(ScoringCriterion c) {
    if (c.key == 'website_opportunity') return 'pagespeed';
    return switch (c.rule.type) {
      CriterionRuleType.legacy => 'legacy',
      CriterionRuleType.prospectField => 'prospect_field',
      CriterionRuleType.boolean => 'boolean',
      CriterionRuleType.threshold => 'threshold',
      CriterionRuleType.keywordMatch => 'keyword_match',
    };
  }

  String _explanationKey(String key, int pts, int max) {
    if (pts <= 0) return '${key}_zero';
    if (pts >= max && max > 0) return '${key}_max';
    return '${key}_partial';
  }

  bool _isSireneClosedListed(Prospect prospect) {
    final reason = prospect.exclusionReason?.toLowerCase() ?? '';
    return prospect.isExcluded && reason.contains('sirene');
  }

  bool _hasKeyField(Prospect prospect, String field) {
    return switch (field) {
      'address' => _nonEmpty(prospect.address),
      'phone' => prospect.hasPhone,
      'website' => prospect.hasWebsite,
      'siret' => _nonEmpty(prospect.siret),
      'manager_name' => _nonEmpty(prospect.managerName),
      'annual_revenue' => prospect.annualRevenue != null,
      'pagespeed_score' => prospect.pagespeedScore != null,
      'creation_date' => prospect.creationDate != null,
      _ => false,
    };
  }

  bool _nonEmpty(String? v) => v != null && v.trim().isNotEmpty;
}
