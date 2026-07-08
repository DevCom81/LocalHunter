import '../../../../core/constants/prospect_status.dart';

class Prospect {
  const Prospect({
    required this.id,
    required this.campaignId,
    required this.name,
    this.city,
    this.address,
    this.managerName,
    this.email,
    this.phone,
    this.website,
    this.facebookUrl,
    this.instagramUrl,
    this.googleRating,
    this.googleReviews = 0,
    this.category,
    this.status = ProspectStatus.newProspect,
    this.isExcluded = false,
    this.exclusionReason,
    this.siren,
    this.siret,
    this.nafCode,
    this.legalForm,
    this.creationDate,
    this.pagespeedScore,
    this.annualRevenue,
    this.annualRevenueYear,
    this.netIncome,
    this.googlePlaceId,
    this.enrichedAt,
    this.enrichmentSource,
    this.createdAt,
    this.customFields = const {},
  });

  final String id;
  final String campaignId;
  final String name;
  final String? city;
  final String? address;
  final String? managerName;
  final String? email;
  final String? phone;
  final String? website;
  final String? facebookUrl;
  final String? instagramUrl;
  final double? googleRating;
  final int googleReviews;
  final String? category;
  final ProspectStatus status;
  final bool isExcluded;
  final String? exclusionReason;
  final String? siren;
  final String? siret;
  final String? nafCode;
  final String? legalForm;

  /// Date de création de l'établissement (SIRENE) — mesure l'ancienneté.
  final DateTime? creationDate;

  /// Score de performance mobile PageSpeed Insights (0-100).
  final int? pagespeedScore;

  /// Chiffre d'affaires du dernier bilan publié (INPI), en euros.
  final int? annualRevenue;
  final int? annualRevenueYear;
  final int? netIncome;

  final String? googlePlaceId;
  final DateTime? enrichedAt;
  final String? enrichmentSource;
  final DateTime? createdAt;
  final Map<String, String> customFields;

  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;

  /// N° TVA intracommunautaire français, dérivé du SIREN
  /// (clé = (12 + 3 × (SIREN mod 97)) mod 97).
  String? get vatNumber {
    final s = siren?.replaceAll(RegExp(r'\D'), '');
    if (s == null || s.length != 9) return null;
    final key = (12 + 3 * (int.parse(s) % 97)) % 97;
    return 'FR${key.toString().padLeft(2, '0')}$s';
  }

  Prospect copyWith({
    bool? isExcluded,
    String? exclusionReason,
    ProspectStatus? status,
    Map<String, String>? customFields,
    String? managerName,
    String? siren,
    String? siret,
    String? nafCode,
    String? legalForm,
    DateTime? creationDate,
    int? pagespeedScore,
    int? annualRevenue,
    int? annualRevenueYear,
    int? netIncome,
    DateTime? enrichedAt,
  }) {
    return Prospect(
      id: id,
      campaignId: campaignId,
      name: name,
      city: city,
      address: address,
      managerName: managerName ?? this.managerName,
      email: email,
      phone: phone,
      website: website,
      facebookUrl: facebookUrl,
      instagramUrl: instagramUrl,
      googleRating: googleRating,
      googleReviews: googleReviews,
      category: category,
      status: status ?? this.status,
      isExcluded: isExcluded ?? this.isExcluded,
      exclusionReason: exclusionReason ?? this.exclusionReason,
      siren: siren ?? this.siren,
      siret: siret ?? this.siret,
      nafCode: nafCode ?? this.nafCode,
      legalForm: legalForm ?? this.legalForm,
      creationDate: creationDate ?? this.creationDate,
      pagespeedScore: pagespeedScore ?? this.pagespeedScore,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      annualRevenueYear: annualRevenueYear ?? this.annualRevenueYear,
      netIncome: netIncome ?? this.netIncome,
      googlePlaceId: googlePlaceId,
      enrichedAt: enrichedAt ?? this.enrichedAt,
      enrichmentSource: enrichmentSource,
      createdAt: createdAt,
      customFields: customFields ?? this.customFields,
    );
  }
}
