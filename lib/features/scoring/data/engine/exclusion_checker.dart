import '../../../prospects/domain/entities/prospect.dart';
import '../../domain/entities/exclusion_reason.dart';
import 'known_chains.dart';

class ExclusionResult {
  const ExclusionResult({required this.isExcluded, this.reason});

  final bool isExcluded;
  final ExclusionReason? reason;
}

class ExclusionChecker {
  ExclusionResult check(Prospect prospect) {
    final name = prospect.name.toLowerCase();
    final category = prospect.category?.toLowerCase() ?? '';
    final website = prospect.website?.toLowerCase() ?? '';

    if (knownChains.any(name.contains)) {
      return const ExclusionResult(
        isExcluded: true,
        reason: ExclusionReason.knownChain,
      );
    }

    if (category.contains('hôtel') || category.contains('hotel')) {
      if (name.contains('mercure') ||
          name.contains('ibis') ||
          name.contains('novotel')) {
        return const ExclusionResult(
          isExcluded: true,
          reason: ExclusionReason.hotelGroup,
        );
      }
    }

    if (website.contains('.fr/fr/') || website.contains('/france/')) {
      return const ExclusionResult(
        isExcluded: true,
        reason: ExclusionReason.centralizedNationalSite,
      );
    }

    final email = prospect.email?.toLowerCase() ?? '';
    if (email.contains('@corp.') ||
        email.contains('@group.') ||
        email.contains('@global.')) {
      return const ExclusionResult(
        isExcluded: true,
        reason: ExclusionReason.nonLocalItDecision,
      );
    }

    return const ExclusionResult(isExcluded: false);
  }
}
