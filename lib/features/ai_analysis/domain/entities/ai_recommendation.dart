import '../../../../core/constants/priority_level.dart';

class ObjectionResponse {
  const ObjectionResponse({required this.objection, required this.response});

  final String objection;
  final String response;
}

class AiRecommendation {
  const AiRecommendation({
    required this.id,
    required this.prospectId,
    this.priority,
    this.bestOffer,
    this.mainReason,
    this.salesAngle,
    this.facebookMessage,
    this.shortEmail,
    this.callOpener,
    this.objections = const [],
    this.llmProvider,
    this.generatedAt,
  });

  final String id;
  final String prospectId;
  final PriorityLevel? priority;

  /// Offre à mettre en avant (libellé libre issu de la grille de scoring).
  final String? bestOffer;
  final String? mainReason;
  final String? salesAngle;
  final String? facebookMessage;
  final String? shortEmail;
  final String? callOpener;
  final List<ObjectionResponse> objections;
  final String? llmProvider;
  final DateTime? generatedAt;

  bool get isEmpty =>
      mainReason == null && salesAngle == null && shortEmail == null;
}
