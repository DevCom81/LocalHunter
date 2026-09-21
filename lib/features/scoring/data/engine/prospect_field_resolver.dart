import '../../../prospects/domain/entities/prospect.dart';
import '../../domain/measurable_criteria_catalog.dart';

export 'prospect_field_labels.dart';

/// Résolution générique des champs prospect pour le scoring.
///
/// Phase 6–11 : champs FR + sociaux. Whitelist = [MeasurableCriteriaCatalog].
class ProspectFieldResolver {
  static const knownFields = MeasurableCriteriaCatalog.measurableFields;

  static const _bodaccBoolFields = {
    'bodacc_has_creation',
    'bodacc_has_accounts_filing',
    'bodacc_has_modification',
    'bodacc_has_sale',
    'bodacc_has_radiation',
    'bodacc_has_liquidation',
    'bodacc_has_collective_proceeding',
    'bodacc_has_manager_change',
    'bodacc_has_address_change',
  };

  static const _socialDetectedFields = {
    'facebook_detected',
    'instagram_detected',
    'linkedin_detected',
    'tiktok_detected',
    'youtube_detected',
    'x_detected',
    'social_presence_detected',
  };

  /// Création < 24 mois → signal « entreprise récente ».
  static const recentCompanyMonths = 24;

  static String? getString(Prospect prospect, String field) {
    final key = _canonical(field);
    if (_bodaccBoolFields.contains(key)) {
      return _bodaccBoolAsString(prospect, key);
    }
    if (_socialDetectedFields.contains(key)) {
      return _socialDetectedAsString(prospect, key);
    }
    switch (key) {
      case 'name':
        return prospect.name;
      case 'city':
        return prospect.city;
      case 'address':
        return prospect.address;
      case 'manager_name':
        return prospect.managerName;
      case 'email':
        return prospect.email;
      case 'phone':
        return prospect.phone;
      case 'website':
        return prospect.website;
      case 'website_exists':
        return prospect.hasWebsite ? 'true' : 'false';
      case 'facebook_url':
        return prospect.facebookUrl;
      case 'instagram_url':
        return prospect.instagramUrl;
      case 'linkedin_url':
        return prospect.linkedinUrl;
      case 'tiktok_url':
        return prospect.tiktokUrl;
      case 'youtube_url':
        return prospect.youtubeUrl;
      case 'x_url':
        return prospect.xUrl;
      case 'google_business_status':
        return prospect.googleBusinessStatus;
      case 'category':
        return prospect.category;
      case 'siren':
        return prospect.siren;
      case 'siret':
        return prospect.siret;
      case 'naf_code':
      case 'activity_code':
        return prospect.nafCode;
      case 'legal_form':
        return prospect.legalForm;
      case 'company_created_recently':
        return _createdRecently(prospect);
      default:
        return prospect.customFields[field] ?? prospect.customFields[key];
    }
  }

  static double? getNumeric(Prospect prospect, String field) {
    final key = _canonical(field);
    switch (key) {
      case 'google_rating':
        return prospect.googleRating;
      case 'google_reviews':
        return prospect.googleReviews.toDouble();
      case 'pagespeed_score':
        return prospect.pagespeedScore?.toDouble();
      case 'company_age_years':
        final created = prospect.creationDate;
        if (created == null) return null;
        return DateTime.now().difference(created).inDays / 365.25;
      case 'annual_revenue':
      case 'revenue':
        return prospect.annualRevenue?.toDouble();
      case 'annual_revenue_year':
        return prospect.annualRevenueYear?.toDouble();
      case 'net_income':
        return prospect.netIncome?.toDouble();
      case 'employee_count':
        return prospect.employeeCount?.toDouble();
      case 'establishment_count':
        return prospect.establishmentCount?.toDouble();
      case 'social_network_count':
        return prospect.socialNetworkCount?.toDouble();
      default:
        final raw = prospect.customFields[field] ?? prospect.customFields[key];
        if (raw == null || raw.isEmpty) return null;
        return double.tryParse(raw.replaceAll(',', '.'));
    }
  }

  static bool hasValue(Prospect prospect, String field) {
    final key = _canonical(field);
    if (key == 'website_exists') return prospect.hasWebsite;
    if (key == 'company_created_recently') {
      return prospect.creationDate != null;
    }
    if (_bodaccBoolFields.contains(key)) {
      return getString(prospect, key) != null;
    }
    if (_socialDetectedFields.contains(key) || key == 'social_network_count') {
      return prospect.hasSocialCheck;
    }
    if (_isNumericKey(key)) {
      return getNumeric(prospect, key) != null;
    }
    final value = getString(prospect, field);
    return value != null && value.trim().isNotEmpty;
  }

  static String _canonical(String field) {
    return switch (field) {
      'revenue' => 'annual_revenue',
      'activity_code' => 'naf_code',
      _ => field,
    };
  }

  static bool _isNumericKey(String key) => const {
        'google_rating',
        'google_reviews',
        'pagespeed_score',
        'company_age_years',
        'annual_revenue',
        'revenue',
        'annual_revenue_year',
        'net_income',
        'employee_count',
        'establishment_count',
        'social_network_count',
      }.contains(key);

  static String? _createdRecently(Prospect prospect) {
    final created = prospect.creationDate;
    if (created == null) return null;
    final months =
        DateTime.now().difference(created).inDays / 30.4375;
    return months < recentCompanyMonths ? 'true' : 'false';
  }

  /// Null si analyse sociale non faite (absence ≠ « pas de réseau »).
  static String? _socialDetectedAsString(Prospect prospect, String field) {
    if (!prospect.hasSocialCheck) return null;
    if (field == 'social_presence_detected') {
      return (prospect.socialNetworkCount ?? 0) > 0 ? 'true' : 'false';
    }
    final url = switch (field) {
      'facebook_detected' => prospect.facebookUrl,
      'instagram_detected' => prospect.instagramUrl,
      'linkedin_detected' => prospect.linkedinUrl,
      'tiktok_detected' => prospect.tiktokUrl,
      'youtube_detected' => prospect.youtubeUrl,
      'x_detected' => prospect.xUrl,
      _ => null,
    };
    final found = url != null && url.trim().isNotEmpty;
    return found ? 'true' : 'false';
  }

  /// Null si BODACC non enrichi ou sans annonce (absence ≠ signal).
  static String? _bodaccBoolAsString(Prospect prospect, String field) {
    if (!prospect.hasBodaccEnrichment || prospect.bodaccNoResults == true) {
      return null;
    }
    final flag = switch (field) {
      'bodacc_has_creation' => prospect.bodaccHasCreation,
      'bodacc_has_accounts_filing' => prospect.bodaccHasAccountsFiling,
      'bodacc_has_modification' => prospect.bodaccHasModification,
      'bodacc_has_sale' => prospect.bodaccHasSale,
      'bodacc_has_radiation' => prospect.bodaccHasRadiation,
      'bodacc_has_liquidation' => prospect.bodaccHasLiquidation,
      'bodacc_has_collective_proceeding' =>
        prospect.bodaccHasCollectiveProceeding,
      'bodacc_has_manager_change' => prospect.bodaccHasManagerChange,
      'bodacc_has_address_change' => prospect.bodaccHasAddressChange,
      _ => null,
    };
    if (flag == null) return null;
    return flag ? 'true' : 'false';
  }
}
