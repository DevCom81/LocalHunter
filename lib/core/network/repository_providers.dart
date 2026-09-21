import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import '../../features/campaigns/data/repositories/demo_campaign_repository.dart';
import '../../features/campaigns/data/repositories/supabase_campaign_repository.dart';
import '../../features/campaigns/domain/repositories/campaign_repository.dart';
import '../../features/prospects/data/repositories/demo_prospect_repository.dart';
import '../../features/prospects/data/repositories/supabase_prospect_repository.dart';
import '../../features/prospects/domain/repositories/prospect_repository.dart';
import '../../features/scoring/data/repositories/demo_scoring_grid_repository.dart';
import '../../features/scoring/data/repositories/demo_weight_suggestion_repository.dart';
import '../../features/scoring/data/repositories/supabase_scoring_grid_repository.dart';
import '../../features/scoring/data/repositories/supabase_weight_suggestion_repository.dart';
import '../../features/scoring/domain/repositories/scoring_grid_repository.dart';
import '../../features/scoring/domain/repositories/weight_suggestion_repository.dart';
import '../../features/commercial_profile/data/repositories/demo_commercial_profile_repository.dart';
import '../../features/commercial_profile/data/repositories/supabase_commercial_profile_repository.dart';
import '../../features/commercial_profile/domain/repositories/commercial_profile_repository.dart';
import 'supabase_client_provider.dart';

final _demoCampaignRepo = DemoCampaignRepository();
final _demoProspectRepo = DemoProspectRepository();
final _demoScoringGridRepo = DemoScoringGridRepository();
final _demoCommercialProfileRepo = DemoCommercialProfileRepository();
final _demoWeightSuggestionRepo = DemoWeightSuggestionRepository();

bool useSupabase(Ref ref) {
  if (!SupabaseConfig.isConfigured) return false;
  return ref.watch(currentUserProvider) != null;
}

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  if (useSupabase(ref)) {
    return SupabaseCampaignRepository(ref.watch(supabaseClientProvider)!);
  }
  return _demoCampaignRepo;
});

final prospectRepositoryProvider = Provider<ProspectRepository>((ref) {
  if (useSupabase(ref)) {
    return SupabaseProspectRepository(ref.watch(supabaseClientProvider)!);
  }
  return _demoProspectRepo;
});

final demoProspectRepositoryProvider = Provider<DemoProspectRepository>(
  (_) => _demoProspectRepo,
);

final scoringGridRepositoryProvider = Provider<ScoringGridRepository>((ref) {
  if (useSupabase(ref)) {
    return SupabaseScoringGridRepository(ref.watch(supabaseClientProvider)!);
  }
  return _demoScoringGridRepo;
});

final commercialProfileRepositoryProvider =
    Provider<CommercialProfileRepository>((ref) {
  if (useSupabase(ref)) {
    return SupabaseCommercialProfileRepository(
      ref.watch(supabaseClientProvider)!,
    );
  }
  return _demoCommercialProfileRepo;
});

final weightSuggestionRepositoryProvider =
    Provider<WeightSuggestionRepository>((ref) {
  if (useSupabase(ref)) {
    return SupabaseWeightSuggestionRepository(
      ref.watch(supabaseClientProvider)!,
    );
  }
  return _demoWeightSuggestionRepo;
});
