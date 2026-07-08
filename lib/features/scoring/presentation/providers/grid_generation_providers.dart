import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../data/services/default_scoring_grid_generator.dart';
import '../../data/services/supabase_grid_generation_service.dart';
import '../../domain/services/scoring_grid_generator.dart';

final scoringGridGeneratorProvider = Provider<ScoringGridGenerator>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DefaultScoringGridGenerator(
    remote: client == null ? null : SupabaseGridGenerationService(client),
  );
});

class GridGenerationNotifier extends AsyncNotifier<GeneratedGridResult?> {
  @override
  Future<GeneratedGridResult?> build() async => null;

  Future<GeneratedGridResult> generate({
    required String business,
    String productsServices = '',
  }) async {
    state = const AsyncLoading();
    final userId = ref.read(currentUserProvider)?.id ?? DemoData.userId;
    try {
      final result = await ref.read(scoringGridGeneratorProvider).generate(
            business: business,
            userId: userId,
            productsServices: productsServices,
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
