const knownChains = [
  'mcdonald',
  'burger king',
  'kfc',
  'subway',
  'starbucks',
  'paul',
  'flunch',
  'courtepaille',
  'buffalo grill',
  'hippopotamus',
  'quick',
  'domino',
  'pizza hut',
];

const knownPosCompetitors = [
  'zelty',
  'toast',
  'lightspeed',
  'laddition',
  'tiller',
  'cashpad',
  'melba',
];

const restaurantCategories = [
  'restaurant',
  'restauration',
  'bar',
  'brasserie',
  'bistro',
  'snack',
  'pizzeria',
  'café',
  'cafe',
];

bool isRestaurantCategory(String? category) {
  if (category == null) return false;
  final lower = category.toLowerCase();
  return restaurantCategories.any(lower.contains);
}
