import '../../../../core/constants/prospect_status.dart';
import '../../domain/entities/prospect.dart';

class ProspectDto {
  ProspectDto({
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
    this.status = 'new',
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
    this.createdAt,
    this.customFields = const {},
  });

  factory ProspectDto.fromJson(Map<String, dynamic> json) {
    final rawCustom = json['custom_fields'] as Map<String, dynamic>? ?? {};
    return ProspectDto(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      name: json['name'] as String,
      city: json['city'] as String?,
      address: json['address'] as String?,
      managerName: json['manager_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      facebookUrl: json['facebook_url'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      tiktokUrl: json['tiktok_url'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      xUrl: json['x_url'] as String?,
      socialCheckedAt: json['social_checked_at'] != null
          ? DateTime.tryParse(json['social_checked_at'] as String)
          : null,
      googleRating: (json['google_rating'] as num?)?.toDouble(),
      googleReviews: json['google_reviews'] as int? ?? 0,
      category: json['category'] as String?,
      status: json['status'] as String? ?? 'new',
      isExcluded: json['is_excluded'] as bool? ?? false,
      exclusionReason: json['exclusion_reason'] as String?,
      siren: json['siren'] as String?,
      siret: json['siret'] as String?,
      nafCode: json['naf_code'] as String?,
      legalForm: json['legal_form'] as String?,
      creationDate: json['creation_date'] != null
          ? DateTime.tryParse(json['creation_date'] as String)
          : null,
      pagespeedScore: json['pagespeed_score'] as int?,
      websiteReachable: json['website_reachable'] as bool?,
      websiteHttps: json['website_https'] as bool?,
      websiteHttpStatus: json['website_http_status'] as int?,
      websiteTitle: json['website_title'] as String?,
      websiteHasViewport: json['website_has_viewport'] as bool?,
      annualRevenue: (json['annual_revenue'] as num?)?.toInt(),
      annualRevenueYear: json['annual_revenue_year'] as int?,
      netIncome: (json['net_income'] as num?)?.toInt(),
      employeeCount: (json['employee_count'] as num?)?.toInt(),
      establishmentCount: (json['establishment_count'] as num?)?.toInt(),
      sireneMatchScore: json['sirene_match_score'] as int?,
      sireneMatchAmbiguous: json['sirene_match_ambiguous'] as bool? ?? false,
      googleBusinessStatus: json['google_business_status'] as String?,
      bodaccFetchedAt: json['bodacc_fetched_at'] != null
          ? DateTime.tryParse(json['bodacc_fetched_at'] as String)
          : null,
      bodaccLastEventAt: json['bodacc_last_event_at'] != null
          ? DateTime.tryParse(json['bodacc_last_event_at'] as String)
          : null,
      bodaccNoResults: json['bodacc_no_results'] as bool?,
      bodaccHasCreation: json['bodacc_has_creation'] as bool?,
      bodaccHasAccountsFiling: json['bodacc_has_accounts_filing'] as bool?,
      bodaccHasModification: json['bodacc_has_modification'] as bool?,
      bodaccHasSale: json['bodacc_has_sale'] as bool?,
      bodaccHasRadiation: json['bodacc_has_radiation'] as bool?,
      bodaccHasLiquidation: json['bodacc_has_liquidation'] as bool?,
      bodaccHasCollectiveProceeding:
          json['bodacc_has_collective_proceeding'] as bool?,
      bodaccHasManagerChange: json['bodacc_has_manager_change'] as bool?,
      bodaccHasAddressChange: json['bodacc_has_address_change'] as bool?,
      bodaccSignalConfidence: json['bodacc_signal_confidence'] as String?,
      bodaccRadiationStatus: json['bodacc_radiation_status'] as String?,
      enrichedAt: json['enriched_at'] != null
          ? DateTime.tryParse(json['enriched_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      customFields: rawCustom.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      ),
    );
  }

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
  final DateTime? socialCheckedAt;
  final double? googleRating;
  final int googleReviews;
  final String? category;
  final String status;
  final bool isExcluded;
  final String? exclusionReason;
  final String? siren;
  final String? siret;
  final String? nafCode;
  final String? legalForm;
  final DateTime? creationDate;
  final int? pagespeedScore;
  final bool? websiteReachable;
  final bool? websiteHttps;
  final int? websiteHttpStatus;
  final String? websiteTitle;
  final bool? websiteHasViewport;
  final int? annualRevenue;
  final int? annualRevenueYear;
  final int? netIncome;
  final int? employeeCount;
  final int? establishmentCount;
  final int? sireneMatchScore;
  final bool sireneMatchAmbiguous;
  final String? googleBusinessStatus;
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
  final DateTime? createdAt;
  final Map<String, String> customFields;

  Map<String, dynamic> toInsertJson() {
    final payload = <String, dynamic>{
      'id': id,
      'campaign_id': campaignId,
      'name': name,
      'city': city,
      'address': address,
      'manager_name': managerName,
      'email': email,
      'phone': phone,
      'website': website,
      'facebook_url': facebookUrl,
      'instagram_url': instagramUrl,
      'linkedin_url': linkedinUrl,
      'tiktok_url': tiktokUrl,
      'youtube_url': youtubeUrl,
      'x_url': xUrl,
      'social_checked_at': socialCheckedAt?.toIso8601String(),
      'google_rating': googleRating,
      'google_reviews': googleReviews,
      'category': category,
      'status': status,
      'is_excluded': isExcluded,
      'exclusion_reason': exclusionReason,
      'siren': siren,
      'siret': siret,
      'naf_code': nafCode,
      'legal_form': legalForm,
      'creation_date': creationDate == null
          ? null
          : creationDate!.toIso8601String().substring(0, 10),
      'pagespeed_score': pagespeedScore,
      'website_reachable': websiteReachable,
      'website_https': websiteHttps,
      'website_http_status': websiteHttpStatus,
      'website_title': websiteTitle,
      'website_has_viewport': websiteHasViewport,
      'annual_revenue': annualRevenue,
      'annual_revenue_year': annualRevenueYear,
      'net_income': netIncome,
      'employee_count': employeeCount,
      'establishment_count': establishmentCount,
      'sirene_match_score': sireneMatchScore,
      'sirene_match_ambiguous': sireneMatchAmbiguous,
      'google_business_status': googleBusinessStatus,
      'bodacc_fetched_at': bodaccFetchedAt?.toIso8601String(),
      'bodacc_last_event_at': bodaccLastEventAt == null
          ? null
          : bodaccLastEventAt!.toIso8601String().substring(0, 10),
      'bodacc_no_results': bodaccNoResults,
      'bodacc_has_creation': bodaccHasCreation,
      'bodacc_has_accounts_filing': bodaccHasAccountsFiling,
      'bodacc_has_modification': bodaccHasModification,
      'bodacc_has_sale': bodaccHasSale,
      'bodacc_has_radiation': bodaccHasRadiation,
      'bodacc_has_liquidation': bodaccHasLiquidation,
      'bodacc_has_collective_proceeding': bodaccHasCollectiveProceeding,
      'bodacc_has_manager_change': bodaccHasManagerChange,
      'bodacc_has_address_change': bodaccHasAddressChange,
      'bodacc_signal_confidence': bodaccSignalConfidence,
      'bodacc_radiation_status': bodaccRadiationStatus,
      'enriched_at': enrichedAt?.toIso8601String(),
      'enrichment_source': enrichmentSourceHint,
      // JSONB NOT NULL : jamais omis, jamais null (même map vide).
      'custom_fields': Map<String, dynamic>.from(customFields),
    };
    payload.removeWhere((key, value) => value == null && key != 'custom_fields');
    return payload;
  }

  /// Places / SIRENE / CSV — évite le hardcode trompeur « csv ».
  String get enrichmentSourceHint {
    if (sireneMatchScore != null || (siret != null && siret!.isNotEmpty)) {
      if (googleRating != null || (category != null && category!.isNotEmpty)) {
        return 'places+sirene';
      }
      return 'sirene';
    }
    if (googleRating != null || (category != null && category!.isNotEmpty)) {
      return 'places';
    }
    return 'import';
  }
}

Prospect prospectFromDto(ProspectDto dto) {
  return Prospect(
    id: dto.id,
    campaignId: dto.campaignId,
    name: dto.name,
    city: dto.city,
    address: dto.address,
    managerName: dto.managerName,
    email: dto.email,
    phone: dto.phone,
    website: dto.website,
    facebookUrl: dto.facebookUrl,
    instagramUrl: dto.instagramUrl,
    linkedinUrl: dto.linkedinUrl,
    tiktokUrl: dto.tiktokUrl,
    youtubeUrl: dto.youtubeUrl,
    xUrl: dto.xUrl,
    socialCheckedAt: dto.socialCheckedAt,
    googleRating: dto.googleRating,
    googleReviews: dto.googleReviews,
    category: dto.category,
    status: ProspectStatus.fromDb(dto.status),
    isExcluded: dto.isExcluded,
    exclusionReason: dto.exclusionReason,
    siren: dto.siren,
    siret: dto.siret,
    nafCode: dto.nafCode,
    legalForm: dto.legalForm,
    creationDate: dto.creationDate,
    pagespeedScore: dto.pagespeedScore,
    websiteReachable: dto.websiteReachable,
    websiteHttps: dto.websiteHttps,
    websiteHttpStatus: dto.websiteHttpStatus,
    websiteTitle: dto.websiteTitle,
    websiteHasViewport: dto.websiteHasViewport,
    annualRevenue: dto.annualRevenue,
    annualRevenueYear: dto.annualRevenueYear,
    netIncome: dto.netIncome,
    employeeCount: dto.employeeCount,
    establishmentCount: dto.establishmentCount,
    sireneMatchScore: dto.sireneMatchScore,
    sireneMatchAmbiguous: dto.sireneMatchAmbiguous,
    googleBusinessStatus: dto.googleBusinessStatus,
    bodaccFetchedAt: dto.bodaccFetchedAt,
    bodaccLastEventAt: dto.bodaccLastEventAt,
    bodaccNoResults: dto.bodaccNoResults,
    bodaccHasCreation: dto.bodaccHasCreation,
    bodaccHasAccountsFiling: dto.bodaccHasAccountsFiling,
    bodaccHasModification: dto.bodaccHasModification,
    bodaccHasSale: dto.bodaccHasSale,
    bodaccHasRadiation: dto.bodaccHasRadiation,
    bodaccHasLiquidation: dto.bodaccHasLiquidation,
    bodaccHasCollectiveProceeding: dto.bodaccHasCollectiveProceeding,
    bodaccHasManagerChange: dto.bodaccHasManagerChange,
    bodaccHasAddressChange: dto.bodaccHasAddressChange,
    bodaccSignalConfidence: dto.bodaccSignalConfidence,
    bodaccRadiationStatus: dto.bodaccRadiationStatus,
    enrichedAt: dto.enrichedAt,
    createdAt: dto.createdAt,
    enrichmentSource: 'csv',
    customFields: dto.customFields,
  );
}
