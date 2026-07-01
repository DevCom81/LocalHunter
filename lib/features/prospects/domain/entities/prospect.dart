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
    this.nafCode,
    this.legalForm,
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
  final String? nafCode;
  final String? legalForm;
  final String? googlePlaceId;
  final DateTime? enrichedAt;
  final String? enrichmentSource;
  final DateTime? createdAt;
  final Map<String, String> customFields;

  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;

  Prospect copyWith({
    bool? isExcluded,
    String? exclusionReason,
    ProspectStatus? status,
    Map<String, String>? customFields,
  }) {
    return Prospect(
      id: id,
      campaignId: campaignId,
      name: name,
      city: city,
      address: address,
      managerName: managerName,
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
      siren: siren,
      nafCode: nafCode,
      legalForm: legalForm,
      googlePlaceId: googlePlaceId,
      enrichedAt: enrichedAt,
      enrichmentSource: enrichmentSource,
      createdAt: createdAt,
      customFields: customFields ?? this.customFields,
    );
  }
}
