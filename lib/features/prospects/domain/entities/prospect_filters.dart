class ProspectFilters {
  const ProspectFilters({
    this.highPriorityOnly = false,
    this.minScore = 0,
    this.minSiteStars = 0,
    this.minSoftwareStars = 0,
    this.excludeFranchises = false,
    this.noWebsiteOnly = false,
    this.weakWebsiteOnly = false,
    this.emailAvailable = false,
    this.phoneAvailable = false,
  });

  final bool highPriorityOnly;
  final int minScore;
  final double minSiteStars;
  final double minSoftwareStars;
  final bool excludeFranchises;
  final bool noWebsiteOnly;
  final bool weakWebsiteOnly;
  final bool emailAvailable;
  final bool phoneAvailable;

  ProspectFilters copyWith({
    bool? highPriorityOnly,
    int? minScore,
    double? minSiteStars,
    double? minSoftwareStars,
    bool? excludeFranchises,
    bool? noWebsiteOnly,
    bool? weakWebsiteOnly,
    bool? emailAvailable,
    bool? phoneAvailable,
  }) {
    return ProspectFilters(
      highPriorityOnly: highPriorityOnly ?? this.highPriorityOnly,
      minScore: minScore ?? this.minScore,
      minSiteStars: minSiteStars ?? this.minSiteStars,
      minSoftwareStars: minSoftwareStars ?? this.minSoftwareStars,
      excludeFranchises: excludeFranchises ?? this.excludeFranchises,
      noWebsiteOnly: noWebsiteOnly ?? this.noWebsiteOnly,
      weakWebsiteOnly: weakWebsiteOnly ?? this.weakWebsiteOnly,
      emailAvailable: emailAvailable ?? this.emailAvailable,
      phoneAvailable: phoneAvailable ?? this.phoneAvailable,
    );
  }
}
