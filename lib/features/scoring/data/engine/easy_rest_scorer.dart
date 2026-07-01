import '../../../prospects/domain/entities/prospect.dart';
import 'known_chains.dart';

class EasyRestScorer {
  double scoreStars(Prospect prospect) {
    if (!isRestaurantCategory(prospect.category)) return 0;

    var stars = 2.0;
    if (!prospect.hasWebsite) stars += 1.5;
    if (prospect.website != null &&
        !prospect.website!.toLowerCase().startsWith('https')) {
      stars += 0.5;
    }
    if (prospect.googleRating != null && prospect.googleRating! >= 3.5) {
      stars += 0.5;
    }
    if (prospect.googleReviews >= 20) stars += 0.5;

    final site = prospect.website?.toLowerCase() ?? '';
    if (knownPosCompetitors.any(site.contains)) stars -= 2;

    return stars.clamp(0, 5).toDouble();
  }
}

class CommercialHealthScorer {
  int scorePoints(Prospect prospect) {
    var points = 5;
    final rating = prospect.googleRating;
    if (rating != null) {
      if (rating >= 4.0) {
        points += 5;
      } else if (rating >= 3.5)
        points += 3;
      else if (rating >= 3.0)
        points += 1;
    }
    if (prospect.googleReviews >= 50) {
      points += 3;
    } else if (prospect.googleReviews >= 10)
      points += 2;
    if (prospect.facebookUrl != null || prospect.instagramUrl != null) {
      points += 2;
    }
    return points.clamp(0, 15);
  }
}
