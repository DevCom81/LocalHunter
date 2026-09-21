import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../prospects/data/demo/demo_data.dart';
import '../../domain/entities/commercial_profile.dart';

final commercialProfileProvider =
    FutureProvider<CommercialProfile>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id ?? DemoData.userId;
  final existing =
      await ref.watch(commercialProfileRepositoryProvider).getByUserId(userId);
  return existing ?? CommercialProfile(userId: userId);
});

Future<CommercialProfile> saveCommercialProfile(
  WidgetRef ref,
  CommercialProfile profile, {
  required bool markValidated,
}) async {
  final saved = await ref.read(commercialProfileRepositoryProvider).save(
        profile,
        markValidated: markValidated,
      );
  ref.invalidate(commercialProfileProvider);
  return saved;
}
