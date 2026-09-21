import 'package:flutter/material.dart';

import '../../../scoring/domain/entities/prospect_score.dart';
import 'prospect_info_section.dart';

/// Lignes composants / sous-scores sur la fiche prospect.
List<Widget> prospectComponentRows(ProspectScore s) {
  if (s.componentScores.isNotEmpty) {
    return s.componentScores.entries
        .map<Widget>((e) => InfoRow(e.key, '${e.value} pts'))
        .toList();
  }
  return [
    InfoRow('Accessibilité', '${s.accessibilityScore} pts'),
    InfoRow('Site web', '${s.websiteOpportunity} pts'),
    InfoRow('Logiciel', '${s.softwareOpportunity} pts'),
    InfoRow('Santé commerciale', '${s.commercialHealth} pts'),
  ];
}

List<Widget> prospectSubScoreRows(ProspectScore s) {
  if (s.subScores.isNotEmpty) {
    return s.subScores.entries
        .map<Widget>(
          (e) => InfoRow(e.key, '${e.value.toStringAsFixed(1)} ★'),
        )
        .toList();
  }
  return [
    InfoRow('SiteScore', '${s.siteScore.toStringAsFixed(1)} ★'),
    InfoRow('Score restauration', '${s.easyRestScore.toStringAsFixed(1)} ★'),
    InfoRow(
      'Risque faux positif',
      '${s.falsePositiveRisk.toStringAsFixed(1)} ★',
    ),
  ];
}
