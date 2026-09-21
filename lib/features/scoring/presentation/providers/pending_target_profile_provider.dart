import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaigns/domain/entities/campaign_target_profile.dart';

/// Dernier profil de prospection validé (Phase 10).
///
/// Préremplit la création de campagne — sans modifier les campagnes existantes.
final pendingCampaignTargetProfileProvider =
    StateProvider<CampaignTargetProfile?>((ref) => null);
