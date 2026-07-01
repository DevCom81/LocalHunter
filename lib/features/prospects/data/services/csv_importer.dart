import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/prospect_status.dart';
import '../../domain/entities/prospect.dart';
import '../../../scoring/data/engine/prospect_field_resolver.dart';

class CsvImporter {
  const CsvImporter();

  static const _knownHeaders = {
    'nom', 'name', 'ville', 'city', 'adresse', 'address',
    'responsable', 'manager', 'email', 'telephone', 'phone', 'tel',
    'site_web', 'website', 'facebook', 'instagram',
    'note_google', 'google_rating', 'nb_avis', 'google_reviews',
    'categorie', 'category',
  };

  List<Prospect> parse(String content, {required String campaignId}) {
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    if (rows.isEmpty) return [];

    final header = rows.first.map((c) => _norm(c.toString())).toList();
    final dataRows = rows.skip(1).where((r) => r.isNotEmpty && r.first != null);

    return dataRows.map((row) {
      final map = <String, String>{};
      for (var i = 0; i < header.length && i < row.length; i++) {
        map[header[i]] = row[i]?.toString().trim() ?? '';
      }
      return _prospectFromRow(map, campaignId);
    }).toList();
  }

  Prospect _prospectFromRow(Map<String, String> row, String campaignId) {
    final customFields = <String, String>{};
    for (final entry in row.entries) {
      if (!_knownHeaders.contains(entry.key) && entry.value.isNotEmpty) {
        final key = _customFieldKey(entry.key);
        customFields[key] = entry.value;
      }
    }

    return Prospect(
      id: const Uuid().v4(),
      campaignId: campaignId,
      name: row['nom'] ?? row['name'] ?? 'Sans nom',
      city: _emptyToNull(row['ville'] ?? row['city']),
      address: _emptyToNull(row['adresse'] ?? row['address']),
      managerName: _emptyToNull(row['responsable'] ?? row['manager']),
      email: _emptyToNull(row['email']),
      phone: _emptyToNull(row['telephone'] ?? row['phone'] ?? row['tel']),
      website: _emptyToNull(row['site_web'] ?? row['website']),
      facebookUrl: _emptyToNull(row['facebook']),
      instagramUrl: _emptyToNull(row['instagram']),
      googleRating: double.tryParse(row['note_google'] ?? row['google_rating'] ?? ''),
      googleReviews: int.tryParse(row['nb_avis'] ?? row['google_reviews'] ?? '') ?? 0,
      category: _emptyToNull(row['categorie'] ?? row['category']),
      status: ProspectStatus.newProspect,
      createdAt: DateTime.now(),
      enrichmentSource: 'csv',
      customFields: customFields,
    );
  }

  String _customFieldKey(String header) {
    final normalized = _norm(header).replaceAll(' ', '_');
    if (ProspectFieldResolver.knownFields.contains(normalized)) {
      return normalized;
    }
    return normalized;
  }

  String _norm(String value) =>
      value.toLowerCase().replaceAll('é', 'e').replaceAll('è', 'e').trim();

  String? _emptyToNull(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
