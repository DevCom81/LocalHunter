/// Une campagne définit la cible de prospection (secteur recherché, ville,
/// rayon, volume) ; l'offre promue est portée par la grille de scoring liée.
class Campaign {
  const Campaign({
    required this.id,
    required this.userId,
    required this.name,
    required this.sector,
    required this.city,
    required this.radiusKm,
    required this.targetCount,
    required this.createdAt,
    this.scoringGridId,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String sector;
  final String city;
  final int radiusKm;
  final int targetCount;
  final String? scoringGridId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Campaign copyWith({
    String? name,
    int? radiusKm,
    int? targetCount,
    String? scoringGridId,
  }) {
    return Campaign(
      id: id,
      userId: userId,
      name: name ?? this.name,
      sector: sector,
      city: city,
      radiusKm: radiusKm ?? this.radiusKm,
      targetCount: targetCount ?? this.targetCount,
      scoringGridId: scoringGridId ?? this.scoringGridId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
