enum ExclusionReason {
  nationalFranchise('Franchise nationale'),
  hotelGroup('Groupe hôtelier'),
  knownChain('Chaîne connue'),
  centralizedNationalSite('Site national centralisé'),
  recentPerformantSite('Site récent et performant'),
  nonLocalItDecision('Décision informatique non locale');

  const ExclusionReason(this.label);
  final String label;
}
