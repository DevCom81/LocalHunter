import 'score_confidence.dart';
import 'score_contribution.dart';
import 'score_explanation_labels.dart';

/// Agrégat expliquant un score : contributions, confiance, avertissements.
class ScoreExplanation {
  const ScoreExplanation({
    required this.globalScore,
    required this.confidence,
    required this.contributions,
  });

  /// Reconstruit depuis les champs persistés sur [ProspectScore] (B1).
  /// Retourne null si aucune confiance n'a été sauvegardée (scores pré-B1).
  static ScoreExplanation? fromPersisted({
    required int globalScore,
    required int? confidenceScore,
    required int? filledFields,
    required int? totalFields,
    required List<String> missingFields,
    required List<ScoreContribution> contributions,
    required List<ScoreWarning> warnings,
  }) {
    if (confidenceScore == null || filledFields == null || totalFields == null) {
      return null;
    }
    return ScoreExplanation(
      globalScore: globalScore,
      confidence: ScoreConfidence(
        score: confidenceScore,
        filledFields: filledFields,
        totalFields: totalFields,
        missingFields: missingFields,
        missingFieldLabels:
            missingFields.map(ScoreExplanationLabels.field).toList(),
        warnings: warnings,
      ),
      contributions: contributions,
    );
  }

  final int globalScore;
  final ScoreConfidence confidence;
  final List<ScoreContribution> contributions;

  List<ScoreWarning> get warnings => confidence.warnings;

  List<ScoreContribution> get positive =>
      contributions.where((c) => c.isPositive && c.contribution > 0).toList();

  List<ScoreContribution> get negative =>
      contributions.where((c) => !c.isPositive || c.value == 0).toList();
}
