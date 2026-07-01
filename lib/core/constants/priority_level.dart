enum PriorityLevel {
  high('high', 'Haute'),
  medium('medium', 'Moyen'),
  low('low', 'Faible'),
  excluded('excluded', 'Exclu');

  const PriorityLevel(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static PriorityLevel fromDb(String value) {
    return PriorityLevel.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => PriorityLevel.low,
    );
  }

  static PriorityLevel fromScore(int score, {required bool isExcluded}) {
    if (isExcluded) return PriorityLevel.excluded;
    if (score >= 70) return PriorityLevel.high;
    if (score >= 45) return PriorityLevel.medium;
    return PriorityLevel.low;
  }
}
