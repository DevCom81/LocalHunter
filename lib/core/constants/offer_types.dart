enum OfferType {
  website('website', 'Site web'),
  businessSoftware('business_software', 'Logiciel métier'),
  easyRest('easy_rest', 'EasyRest'),
  crm('crm', 'CRM');

  const OfferType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static OfferType fromDb(String value) {
    return OfferType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => OfferType.website,
    );
  }
}
