import 'prospect.dart';
import '../../../scoring/domain/entities/prospect_score.dart';

class ProspectWithScore {
  const ProspectWithScore({required this.prospect, required this.score});

  final Prospect prospect;
  final ProspectScore score;
}
