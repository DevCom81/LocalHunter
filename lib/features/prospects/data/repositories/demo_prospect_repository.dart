import 'package:uuid/uuid.dart';

import '../../../../core/constants/prospect_status.dart';
import '../../domain/entities/prospect.dart';
import '../../domain/repositories/prospect_repository.dart';
import '../../../scoring/domain/entities/prospect_score.dart';
import '../demo/demo_data.dart';

class DemoProspectRepository implements ProspectRepository {
  DemoProspectRepository() {
    _byCampaign = {
      DemoData.campaignId: DemoData.albiProspects(),
    };
    _scores = {};
  }

  late Map<String, List<Prospect>> _byCampaign;
  late Map<String, ProspectScore> _scores;
  final _uuid = const Uuid();

  @override
  Future<List<Prospect>> getByCampaign(String campaignId) async {
    return List.unmodifiable(_byCampaign[campaignId] ?? []);
  }

  @override
  Future<Prospect?> getById(String id) async {
    for (final list in _byCampaign.values) {
      for (final p in list) {
        if (p.id == id) return p;
      }
    }
    return null;
  }

  @override
  Future<void> updateStatus(String id, ProspectStatus status) async {
    _byCampaign = _byCampaign.map(
      (campaignId, list) => MapEntry(
        campaignId,
        list
            .map((p) => p.id == id ? p.copyWith(status: status) : p)
            .toList(),
      ),
    );
  }

  @override
  Future<List<Prospect>> importProspects(
    String campaignId,
    List<Prospect> prospects,
  ) async {
    final existing = _byCampaign[campaignId] ?? [];
    _byCampaign[campaignId] = [...existing, ...prospects];
    return prospects;
  }

  @override
  Future<void> saveScores(List<ProspectScore> scores) async {
    for (final s in scores) {
      _scores[s.prospectId] = s;
    }
  }

  @override
  Future<Map<String, ProspectScore>> getScoresByCampaign(
    String campaignId,
  ) async {
    final prospects = _byCampaign[campaignId] ?? [];
    final result = <String, ProspectScore>{};
    for (final p in prospects) {
      if (_scores.containsKey(p.id)) {
        result[p.id] = _scores[p.id]!;
      }
    }
    return result;
  }

  Prospect assignId(Prospect prospect, String campaignId) {
    return Prospect(
      id: _uuid.v4(),
      campaignId: campaignId,
      name: prospect.name,
      city: prospect.city,
      address: prospect.address,
      managerName: prospect.managerName,
      email: prospect.email,
      phone: prospect.phone,
      website: prospect.website,
      facebookUrl: prospect.facebookUrl,
      instagramUrl: prospect.instagramUrl,
      googleRating: prospect.googleRating,
      googleReviews: prospect.googleReviews,
      category: prospect.category,
      status: prospect.status,
      isExcluded: prospect.isExcluded,
      exclusionReason: prospect.exclusionReason,
      createdAt: DateTime.now(),
      enrichmentSource: 'csv',
    );
  }
}
