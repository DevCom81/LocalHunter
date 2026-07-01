import '../../../prospects/domain/entities/prospect.dart';

class ProspectFieldResolver {
  static const knownFields = {
    'name',
    'city',
    'address',
    'manager_name',
    'email',
    'phone',
    'website',
    'facebook_url',
    'instagram_url',
    'google_rating',
    'google_reviews',
    'category',
    'siren',
    'naf_code',
    'legal_form',
  };

  static String? getString(Prospect prospect, String field) {
    switch (field) {
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
      case 'facebook_url':
        return prospect.facebookUrl;
      case 'instagram_url':
        return prospect.instagramUrl;
      case 'category':
        return prospect.category;
      case 'siren':
        return prospect.siren;
      case 'naf_code':
        return prospect.nafCode;
      case 'legal_form':
        return prospect.legalForm;
      default:
        return prospect.customFields[field];
    }
  }

  static double? getNumeric(Prospect prospect, String field) {
    switch (field) {
      case 'google_rating':
        return prospect.googleRating;
      case 'google_reviews':
        return prospect.googleReviews.toDouble();
      default:
        final raw = prospect.customFields[field];
        if (raw == null || raw.isEmpty) return null;
        return double.tryParse(raw.replaceAll(',', '.'));
    }
  }

  static bool hasValue(Prospect prospect, String field) {
    final value = getString(prospect, field);
    return value != null && value.trim().isNotEmpty;
  }
}

const prospectFieldLabels = <String, String>{
  'name': 'Nom',
  'city': 'Ville',
  'address': 'Adresse',
  'manager_name': 'Responsable',
  'email': 'Email',
  'phone': 'Téléphone',
  'website': 'Site web',
  'facebook_url': 'Facebook',
  'instagram_url': 'Instagram',
  'google_rating': 'Note Google',
  'google_reviews': 'Nombre d\'avis',
  'category': 'Catégorie',
  'siren': 'SIREN',
  'naf_code': 'Code NAF',
  'legal_form': 'Forme juridique',
};

String labelForField(String field) =>
    prospectFieldLabels[field] ?? field;
