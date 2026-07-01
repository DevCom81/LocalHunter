import '../entities/prospect.dart';
import '../../../scoring/domain/entities/prospect_score.dart';

abstract class ProspectRepository {
  Future<List<Prospect>> getByCampaign(String campaignId);
  Future<Prospect?> getById(String id);
  Future<List<Prospect>> importProspects(
    String campaignId,
    List<Prospect> prospects,
  );
  Future<void> saveScores(List<ProspectScore> scores);
  Future<Map<String, ProspectScore>> getScoresByCampaign(String campaignId);
}
