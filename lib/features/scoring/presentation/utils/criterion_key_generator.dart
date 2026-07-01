import '../../domain/entities/scoring_grid.dart';

String generateCriterionKey(String label, List<ScoringCriterion> existing) {
  final base = label
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  var key = base.isEmpty ? 'criterion' : base;
  var n = 1;
  while (existing.any((c) => c.key == key)) {
    key = '${base.isEmpty ? 'criterion' : base}_$n';
    n++;
  }
  return key;
}

String kindLabel(CriterionKind kind) => switch (kind) {
      CriterionKind.component => 'Composant (points)',
      CriterionKind.subScore => 'Sous-score (étoiles)',
      CriterionKind.exclusion => 'Exclusion',
    };
