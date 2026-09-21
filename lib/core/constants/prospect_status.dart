enum ProspectStatus {
  newProspect('new', 'Nouveau'),
  toStudy('to_study', 'À étudier'),
  toContact('to_contact', 'À contacter'),
  contacted('contacted', 'Contacté'),
  noReply('no_reply', 'Sans réponse'),
  interested('interested', 'Intéressé'),
  meeting('meeting', 'Rendez-vous obtenu'),
  proposal('proposal', 'Proposition'),
  won('won', 'Gagné'),
  lost('lost', 'Perdu'),
  notRelevant('not_relevant', 'Non pertinent'),
  alreadyEquipped('already_equipped', 'Déjà équipé'),
  tooSmall('too_small', 'Trop petit'),
  franchise('franchise', 'Franchise'),
  outOfScope('out_of_scope', 'Hors cible'),
  excluded('excluded', 'Exclu');

  const ProspectStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  /// Grisé dans la liste CRM : déjà traité ou hors pipeline actif.
  bool get dimsInList =>
      this != newProspect && this != toStudy && this != toContact;

  /// Case à cocher « contacté » de la carte CRM.
  bool get marksContactedCheckbox => switch (this) {
        contacted ||
        noReply ||
        interested ||
        meeting ||
        proposal ||
        won =>
          true,
        _ => false,
      };

  static ProspectStatus fromDb(String value) {
    return ProspectStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ProspectStatus.newProspect,
    );
  }
}
