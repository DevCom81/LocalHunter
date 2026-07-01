enum ProspectStatus {
  newProspect('new', 'Nouveau'),
  contacted('contacted', 'Contacté'),
  interested('interested', 'Intéressé'),
  proposal('proposal', 'Proposition'),
  won('won', 'Gagné'),
  lost('lost', 'Perdu'),
  excluded('excluded', 'Exclu');

  const ProspectStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static ProspectStatus fromDb(String value) {
    return ProspectStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ProspectStatus.newProspect,
    );
  }
}
