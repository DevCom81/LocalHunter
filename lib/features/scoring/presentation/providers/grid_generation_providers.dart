import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../data/services/default_scoring_grid_generator.dart';
import '../../data/services/supabase_grid_generation_service.dart';
import '../../domain/entities/prospecting_profile.dart';
import '../../domain/services/scoring_grid_generator.dart';

final scoringGridGeneratorProvider = Provider<ScoringGridGenerator>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DefaultScoringGridGenerator(
    remote: client == null ? null : SupabaseGridGenerationService(client),
  );
});

final gridGenerationRemoteProvider =
    Provider<SupabaseGridGenerationService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseGridGenerationService(client);
});

class GridGenerationNotifier extends AsyncNotifier<GeneratedGridResult?> {
  @override
  Future<GeneratedGridResult?> build() async => null;

  Future<ProspectingProfile> proposeProfile({
    required String business,
    String productsServices = '',
  }) async {
    final remote = ref.read(gridGenerationRemoteProvider);
    if (remote == null) {
      throw StateError(
        'Proposition de profil disponible uniquement avec Supabase.',
      );
    }
    return remote.proposeProfile(
      business: business,
      productsServices: productsServices,
    );
  }

  Future<GeneratedGridResult> generate({
    required String business,
    String productsServices = '',
    Map<String, dynamic>? commercialProfile,
    ProspectingProfile? prospectingProfile,
  }) async {
    state = const AsyncLoading();
    final userId = ref.read(currentUserProvider)?.id ?? DemoData.userId;
    try {
      final result = await ref.read(scoringGridGeneratorProvider).generate(
            business: business,
            userId: userId,
            productsServices: productsServices,
            commercialProfile: commercialProfile,
            prospectingProfile: prospectingProfile,
          );
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final gridGenerationProvider =
    AsyncNotifierProvider<GridGenerationNotifier, GeneratedGridResult?>(
  GridGenerationNotifier.new,
);
