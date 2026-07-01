import '../../../prospects/domain/entities/prospect.dart';

class DigitalMaturityScorer {
  double scoreStars(Prospect prospect) {
    var stars = 0.0;
    if (prospect.hasWebsite) stars += 1.5;
    if (prospect.website?.toLowerCase().startsWith('https') ?? false) {
      stars += 1;
    }
    if (prospect.facebookUrl != null) stars += 0.8;
    if (prospect.instagramUrl != null) stars += 0.8;
    if (prospect.googleReviews >= 30) stars += 0.9;
    return stars.clamp(0, 5).toDouble();
  }
}

class FalsePositiveDetector {
  double riskStars(Prospect prospect, {required bool isExcluded}) {
    if (isExcluded) return 5;
    var risk = 0.0;
    final name = prospect.name.toLowerCase();
    if (name.contains('group') || name.contains('groupe')) risk += 2;
    if (prospect.googleReviews > 500) risk += 1.5;
    if (prospect.website != null &&
        !prospect.website!.toLowerCase().contains('albi')) {
      risk += 1;
    }
    return risk.clamp(0, 5).toDouble();
  }
}
