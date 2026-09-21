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
    this.linkedinUrl,
    this.tiktokUrl,
    this.youtubeUrl,
    this.xUrl,
    this.socialCheckedAt,
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
    this.websiteReachable,
    this.websiteHttps,
    this.websiteHttpStatus,
    this.websiteTitle,
    this.websiteHasViewport,
    this.annualRevenue,
    this.annualRevenueYear,
    this.netIncome,
    this.employeeCount,
    this.establishmentCount,
    this.sireneMatchScore,
    this.sireneMatchAmbiguous = false,
    this.googlePlaceId,
    this.googleBusinessStatus,
    this.bodaccFetchedAt,
    this.bodaccLastEventAt,
    this.bodaccNoResults,
    this.bodaccHasCreation,
    this.bodaccHasAccountsFiling,
    this.bodaccHasModification,
    this.bodaccHasSale,
    this.bodaccHasRadiation,
    this.bodaccHasLiquidation,
    this.bodaccHasCollectiveProceeding,
    this.bodaccHasManagerChange,
    this.bodaccHasAddressChange,
    this.bodaccSignalConfidence,
    this.bodaccRadiationStatus,
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
  final String? linkedinUrl;
  final String? tiktokUrl;
  final String? youtubeUrl;
  final String? xUrl;

  /// Null = analyse sociale non exécutée. Non-null = scan site fait
  /// (même si aucun lien trouvé — ≠ « n'a aucun réseau »).
  final DateTime? socialCheckedAt;

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

  /// Analyse légère C3 — null = non analysé.
  final bool? websiteReachable;
  final bool? websiteHttps;
  final int? websiteHttpStatus;
  final String? websiteTitle;
  final bool? websiteHasViewport;

  /// Chiffre d'affaires du dernier bilan publié (INPI), en euros.
  final int? annualRevenue;
  final int? annualRevenueYear;
  final int? netIncome;

  /// Effectif (borne basse tranche INSEE). Null = inconnu (≠ 0).
  final int? employeeCount;

  /// Nombre d'établissements (ouverts si dispo). Null = inconnu.
  final int? establishmentCount;

  /// Qualité du rapprochement SIRENE (0–100), null si non enrichi.
  final int? sireneMatchScore;

  /// Plusieurs candidats SIRENE proches : à vérifier manuellement.
  final bool sireneMatchAmbiguous;

  final String? googlePlaceId;

  /// Statut Google Places : OPERATIONAL, CLOSED_TEMPORARILY, CLOSED_PERMANENTLY.
  final String? googleBusinessStatus;

  /// Signaux BODACC (C4) — null = non enrichi.
  final DateTime? bodaccFetchedAt;
  final DateTime? bodaccLastEventAt;
  final bool? bodaccNoResults;
  final bool? bodaccHasCreation;
  final bool? bodaccHasAccountsFiling;
  final bool? bodaccHasModification;
  final bool? bodaccHasSale;
  final bool? bodaccHasRadiation;
  final bool? bodaccHasLiquidation;
  final bool? bodaccHasCollectiveProceeding;
  final bool? bodaccHasManagerChange;
  final bool? bodaccHasAddressChange;
  final String? bodaccSignalConfidence;
  final String? bodaccRadiationStatus;

  final DateTime? enrichedAt;
  final String? enrichmentSource;
  final DateTime? createdAt;
  final Map<String, String> customFields;

  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;

  bool get isGoogleClosed =>
      googleBusinessStatus == 'CLOSED_PERMANENTLY' ||
      googleBusinessStatus == 'CLOSED_TEMPORARILY';

  bool get hasBodaccEnrichment => bodaccFetchedAt != null;

  bool get hasSocialCheck => socialCheckedAt != null;

  /// Nombre de réseaux détectés sur le site — null si non analysé.
  int? get socialNetworkCount {
    if (!hasSocialCheck) return null;
    return [
      facebookUrl,
      instagramUrl,
      linkedinUrl,
      tiktokUrl,
      youtubeUrl,
      xUrl,
    ].where((u) => u != null && u!.trim().isNotEmpty).length;
  }

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
    String? facebookUrl,
    String? instagramUrl,
    String? linkedinUrl,
    String? tiktokUrl,
    String? youtubeUrl,
    String? xUrl,
    DateTime? socialCheckedAt,
    String? managerName,
    String? siren,
    String? siret,
    String? nafCode,
    String? legalForm,
    DateTime? creationDate,
    int? pagespeedScore,
    bool? websiteReachable,
    bool? websiteHttps,
    int? websiteHttpStatus,
    String? websiteTitle,
    bool? websiteHasViewport,
    int? annualRevenue,
    int? annualRevenueYear,
    int? netIncome,
    int? employeeCount,
    int? establishmentCount,
    int? sireneMatchScore,
    bool? sireneMatchAmbiguous,
    String? googleBusinessStatus,
    DateTime? bodaccFetchedAt,
    DateTime? bodaccLastEventAt,
    bool? bodaccNoResults,
    bool? bodaccHasCreation,
    bool? bodaccHasAccountsFiling,
    bool? bodaccHasModification,
    bool? bodaccHasSale,
    bool? bodaccHasRadiation,
    bool? bodaccHasLiquidation,
    bool? bodaccHasCollectiveProceeding,
    bool? bodaccHasManagerChange,
    bool? bodaccHasAddressChange,
    String? bodaccSignalConfidence,
    String? bodaccRadiationStatus,
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
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      xUrl: xUrl ?? this.xUrl,
      socialCheckedAt: socialCheckedAt ?? this.socialCheckedAt,
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
      websiteReachable: websiteReachable ?? this.websiteReachable,
      websiteHttps: websiteHttps ?? this.websiteHttps,
      websiteHttpStatus: websiteHttpStatus ?? this.websiteHttpStatus,
      websiteTitle: websiteTitle ?? this.websiteTitle,
      websiteHasViewport: websiteHasViewport ?? this.websiteHasViewport,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      annualRevenueYear: annualRevenueYear ?? this.annualRevenueYear,
      netIncome: netIncome ?? this.netIncome,
      employeeCount: employeeCount ?? this.employeeCount,
      establishmentCount: establishmentCount ?? this.establishmentCount,
      sireneMatchScore: sireneMatchScore ?? this.sireneMatchScore,
      sireneMatchAmbiguous:
          sireneMatchAmbiguous ?? this.sireneMatchAmbiguous,
      googlePlaceId: googlePlaceId,
      googleBusinessStatus:
          googleBusinessStatus ?? this.googleBusinessStatus,
      bodaccFetchedAt: bodaccFetchedAt ?? this.bodaccFetchedAt,
      bodaccLastEventAt: bodaccLastEventAt ?? this.bodaccLastEventAt,
      bodaccNoResults: bodaccNoResults ?? this.bodaccNoResults,
      bodaccHasCreation: bodaccHasCreation ?? this.bodaccHasCreation,
      bodaccHasAccountsFiling:
          bodaccHasAccountsFiling ?? this.bodaccHasAccountsFiling,
      bodaccHasModification:
          bodaccHasModification ?? this.bodaccHasModification,
      bodaccHasSale: bodaccHasSale ?? this.bodaccHasSale,
      bodaccHasRadiation: bodaccHasRadiation ?? this.bodaccHasRadiation,
      bodaccHasLiquidation: bodaccHasLiquidation ?? this.bodaccHasLiquidation,
      bodaccHasCollectiveProceeding: bodaccHasCollectiveProceeding ??
          this.bodaccHasCollectiveProceeding,
      bodaccHasManagerChange:
          bodaccHasManagerChange ?? this.bodaccHasManagerChange,
      bodaccHasAddressChange:
          bodaccHasAddressChange ?? this.bodaccHasAddressChange,
      bodaccSignalConfidence:
          bodaccSignalConfidence ?? this.bodaccSignalConfidence,
      bodaccRadiationStatus:
          bodaccRadiationStatus ?? this.bodaccRadiationStatus,
      enrichedAt: enrichedAt ?? this.enrichedAt,
      enrichmentSource: enrichmentSource,
      createdAt: createdAt,
      customFields: customFields ?? this.customFields,
    );
  }
}
