class ScoringRule {
  const ScoringRule({
    required this.id,
    required this.userId,
    required this.ruleKey,
    required this.weight,
    this.threshold,
    this.isActive = true,
  });

  final String id;
  final String userId;
  final String ruleKey;
  final double weight;
  final double? threshold;
  final bool isActive;
}
