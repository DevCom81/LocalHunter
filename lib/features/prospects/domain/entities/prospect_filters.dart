/// Filtres CRM génériques (indépendants d'une offre site web / SEO).
class ProspectFilters {
  const ProspectFilters({
    this.highPriorityOnly = false,
    this.minScore = 0,
    this.excludeFranchises = false,
    this.emailAvailable = false,
    this.phoneAvailable = false,
  });

  final bool highPriorityOnly;
  final int minScore;
  final bool excludeFranchises;
  final bool emailAvailable;
  final bool phoneAvailable;

  ProspectFilters copyWith({
    bool? highPriorityOnly,
    int? minScore,
    bool? excludeFranchises,
    bool? emailAvailable,
    bool? phoneAvailable,
  }) {
    return ProspectFilters(
      highPriorityOnly: highPriorityOnly ?? this.highPriorityOnly,
      minScore: minScore ?? this.minScore,
      excludeFranchises: excludeFranchises ?? this.excludeFranchises,
      emailAvailable: emailAvailable ?? this.emailAvailable,
      phoneAvailable: phoneAvailable ?? this.phoneAvailable,
    );
  }
}
