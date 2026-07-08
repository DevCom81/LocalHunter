import '../../../prospects/domain/entities/prospect.dart';
import 'known_chains.dart';

class AccessibilityScorer {
  int scorePoints(Prospect prospect) {
    var points = 0;
    if (prospect.hasPhone) points += 10;
    if (prospect.hasEmail) points += 12;
    if (prospect.managerName != null && prospect.managerName!.isNotEmpty) {
      points += 8;
    }
    return points.clamp(0, 30);
  }

  double scoreStars(Prospect prospect) {
    return (scorePoints(prospect) / 30 * 5).clamp(0, 5).toDouble();
  }
}

class SiteScorer {
  int scorePoints(Prospect prospect) {
    if (!prospect.hasWebsite) return 28;
    final site = prospect.website!.toLowerCase();
    // Site lent sur mobile (PageSpeed) : opportunité de refonte élevée.
    final speed = prospect.pagespeedScore;
    if (speed != null && speed < 50) return 26;
    if (site.contains('wix') || site.contains('wordpress')) return 22;
    if (!site.startsWith('https')) return 20;
    if (speed != null && speed < 80) return 16;
    return 8;
  }

  double scoreStars(Prospect prospect) {
    return (scorePoints(prospect) / 30 * 5).clamp(0, 5).toDouble();
  }
}

class SoftwareScorer {
  int scorePoints(Prospect prospect) {
    if (isRestaurantCategory(prospect.category)) return 18;
    if (prospect.category != null) return 12;
    return 8;
  }

  double scoreStars(Prospect prospect) {
    return (scorePoints(prospect) / 25 * 5).clamp(0, 5).toDouble();
  }
}
