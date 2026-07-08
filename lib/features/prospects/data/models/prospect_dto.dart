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
    this.annualRevenue,
    this.annualRevenueYear,
    this.netIncome,
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
      annualRevenue: (json['annual_revenue'] as num?)?.toInt(),
      annualRevenueYear: json['annual_revenue_year'] as int?,
      netIncome: (json['net_income'] as num?)?.toInt(),
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
  final int? annualRevenue;
  final int? annualRevenueYear;
  final int? netIncome;
  final DateTime? enrichedAt;
  final DateTime? createdAt;
  final Map<String, String> customFields;

  Map<String, dynamic> toInsertJson() {
    return {
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
      'creation_date': creationDate?.toIso8601String().substring(0, 10),
      'pagespeed_score': pagespeedScore,
      'annual_revenue': annualRevenue,
      'annual_revenue_year': annualRevenueYear,
      'net_income': netIncome,
      'enriched_at': enrichedAt?.toIso8601String(),
      'enrichment_source': 'csv',
      if (customFields.isNotEmpty) 'custom_fields': customFields,
    };
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
    annualRevenue: dto.annualRevenue,
    annualRevenueYear: dto.annualRevenueYear,
    netIncome: dto.netIncome,
    enrichedAt: dto.enrichedAt,
    createdAt: dto.createdAt,
    enrichmentSource: 'csv',
    customFields: dto.customFields,
  );
}
