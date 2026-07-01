import '../../../prospects/domain/entities/prospect.dart';
import '../../domain/entities/exclusion_reason.dart';
import '../../domain/entities/grid_config.dart';
import 'known_chains.dart';

class ExclusionResult {
  const ExclusionResult({required this.isExcluded, this.reason});

  final bool isExcluded;
  final ExclusionReason? reason;
}

class ConfigurableExclusionChecker {
  ConfigurableExclusionChecker({
    GridExclusionConfig? config,
    Map<String, double>? subScores,
  })  : _config = config ?? const GridExclusionConfig(),
        _subScores = subScores ?? {};

  final GridExclusionConfig _config;
  final Map<String, double> _subScores;

  ExclusionResult check(Prospect prospect) {
    for (final rule in _config.rules) {
      final result = _applyRule(prospect, rule);
      if (result.isExcluded) return result;
    }
    return const ExclusionResult(isExcluded: false);
  }

  ExclusionResult _applyRule(Prospect prospect, ExclusionRule rule) {
    switch (rule.type) {
      case 'known_chain':
        return _checkKeywords(prospect.name, rule.keywords, ExclusionReason.knownChain);
      case 'hotel_group':
        return _checkHotelGroup(prospect, rule);
      case 'website_pattern':
        return _checkWebsitePatterns(prospect, rule.patterns);
      case 'email_pattern':
        return _checkEmailPatterns(prospect, rule.patterns);
      case 'sub_score_threshold':
        return _checkSubScoreThreshold(rule);
      default:
        return const ExclusionResult(isExcluded: false);
    }
  }

  ExclusionResult _checkKeywords(
    String text,
    List<String> keywords,
    ExclusionReason reason,
  ) {
    final lower = text.toLowerCase();
    for (final kw in keywords) {
      if (lower.contains(kw.toLowerCase())) {
        return ExclusionResult(isExcluded: true, reason: reason);
      }
    }
    return const ExclusionResult(isExcluded: false);
  }

  ExclusionResult _checkHotelGroup(Prospect prospect, ExclusionRule rule) {
    final category = prospect.category?.toLowerCase() ?? '';
    final catKw = rule.categoryKeyword?.toLowerCase();
    if (catKw != null && !category.contains(catKw)) {
      return const ExclusionResult(isExcluded: false);
    }
    return _checkKeywords(prospect.name, rule.nameKeywords, ExclusionReason.hotelGroup);
  }

  ExclusionResult _checkWebsitePatterns(Prospect prospect, List<String> patterns) {
    final website = prospect.website?.toLowerCase() ?? '';
    for (final pattern in patterns) {
      if (website.contains(pattern.toLowerCase())) {
        return const ExclusionResult(
          isExcluded: true,
          reason: ExclusionReason.centralizedNationalSite,
        );
      }
    }
    return const ExclusionResult(isExcluded: false);
  }

  ExclusionResult _checkEmailPatterns(Prospect prospect, List<String> patterns) {
    final email = prospect.email?.toLowerCase() ?? '';
    for (final pattern in patterns) {
      if (email.contains(pattern.toLowerCase())) {
        return const ExclusionResult(
          isExcluded: true,
          reason: ExclusionReason.nonLocalItDecision,
        );
      }
    }
    return const ExclusionResult(isExcluded: false);
  }

  ExclusionResult _checkSubScoreThreshold(ExclusionRule rule) {
    if (rule.criterionKey == null || rule.minStars == null) {
      return const ExclusionResult(isExcluded: false);
    }
    final stars = _subScores[rule.criterionKey!] ?? 0;
    if (stars >= rule.minStars!) {
      return const ExclusionResult(
        isExcluded: true,
        reason: ExclusionReason.knownChain,
      );
    }
    return const ExclusionResult(isExcluded: false);
  }
}

GridExclusionConfig defaultExclusionConfig() {
  return GridExclusionConfig(
    rules: [
      ExclusionRule(type: 'known_chain', keywords: knownChains),
      ExclusionRule(
        type: 'hotel_group',
        categoryKeyword: 'hotel',
        nameKeywords: ['mercure', 'ibis', 'novotel'],
      ),
      ExclusionRule(
        type: 'website_pattern',
        patterns: ['.fr/fr/', '/france/'],
      ),
      ExclusionRule(
        type: 'email_pattern',
        patterns: ['@corp.', '@group.', '@global.'],
      ),
      ExclusionRule(
        type: 'sub_score_threshold',
        criterionKey: 'digital_maturity',
        minStars: 4,
      ),
    ],
  );
}
