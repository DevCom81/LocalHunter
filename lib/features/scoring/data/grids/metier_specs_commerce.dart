import 'metier_grid_builder.dart';

/// Métiers de l'immobilier, de l'équipement et du commerce (10 specs).
const metierSpecsCommerce = <MetierGridSpec>[
  MetierGridSpec(
    id: 'metier-agent-immobilier',
    name: 'Agent immobilier — Commerces locaux',
    description:
        'Prospection de commerces pour locaux professionnels et murs commerciaux.',
    aliases: ['agent immobilier', 'agence immobiliere', 'mandataire immobilier'],
    targetKeyword: 'commerce',
    exclusionKeywords: ['orpi', 'century 21', 'laforet', 'guy hoquet', 'safti'],
  ),
  MetierGridSpec(
    id: 'metier-promoteur-immobilier',
    name: 'Promoteur immobilier — Acteurs fonciers',
    description:
        'Prospection d\'agences immobilières, architectes et notaires locaux.',
    aliases: ['promoteur immobilier', 'promotion immobiliere', 'promoteur'],
    targetKeyword: 'immobilier',
    exclusionKeywords: ['nexity', 'bouygues immobilier', 'vinci immobilier'],
  ),
  MetierGridSpec(
    id: 'metier-photographe',
    name: 'Photographe pro — CHR & immobilier',
    description:
        'Prospection de restaurants, hôtels et agences pour shootings pro.',
    aliases: ['photographe', 'photographe professionnel'],
    targetKeyword: 'restaurant',
    minRating: 3.5,
    minReviews: 10,
  ),
  MetierGridSpec(
    id: 'metier-architecte-interieur',
    name: 'Architecte d\'intérieur — CHR & boutiques',
    description:
        'Prospection d\'hôtels, restaurants et boutiques à réaménager.',
    aliases: ['architecte d\'interieur', 'decorateur d\'interieur'],
    targetKeyword: 'hotel',
    exclusionKeywords: ['ibis', 'mercure', 'novotel', 'campanile', 'kyriad'],
  ),
  MetierGridSpec(
    id: 'metier-cuisiniste',
    name: 'Cuisiniste pro — Restauration',
    description:
        'Prospection de restaurants pour équipement et agencement de cuisines.',
    aliases: ['cuisiniste', 'cuisiniste professionnel', 'agenceur de cuisine'],
    targetKeyword: 'restaurant',
    exclusionKeywords: ['mcdonald', 'burger king', 'kfc', 'subway'],
  ),
  MetierGridSpec(
    id: 'metier-paysagiste',
    name: 'Paysagiste — Hôtellerie & entreprises',
    description:
        'Prospection d\'hôtels, campings et sièges d\'entreprises avec espaces verts.',
    aliases: ['paysagiste', 'jardinier paysagiste', 'entretien espaces verts'],
    targetKeyword: 'hotel',
    minReviews: 5,
    exclusionKeywords: ['ibis', 'mercure', 'novotel', 'campanile'],
  ),
  MetierGridSpec(
    id: 'metier-photovoltaique',
    name: 'Photovoltaïque — Entreprises & agricole',
    description:
        'Prospection d\'entreprises et d\'exploitations avec toitures exploitables.',
    aliases: [
      'installateur photovoltaique',
      'photovoltaique',
      'panneaux solaires',
    ],
    targetKeyword: 'entreprise',
    targetPoints: 15,
    minReviews: 5,
  ),
  MetierGridSpec(
    id: 'metier-courtier-energie',
    name: 'Courtier en énergie — Gros consommateurs',
    description:
        'Prospection de restaurants et commerces à forte facture énergétique.',
    aliases: ['courtier en energie', 'courtier energie'],
    targetKeyword: 'restaurant',
    exclusionKeywords: ['mcdonald', 'burger king', 'carrefour', 'leclerc'],
  ),
  MetierGridSpec(
    id: 'metier-delegue-pharmaceutique',
    name: 'Délégué pharmaceutique — Officines',
    description:
        'Prospection de pharmacies indépendantes pour référencement produits.',
    aliases: [
      'delegue pharmaceutique',
      'commercial en pharmacie',
      'visiteur medical',
    ],
    targetKeyword: 'pharmacie',
    targetPoints: 30,
    minReviews: 5,
    exclusionKeywords: ['lafayette', 'aprium', 'giphar', 'giropharm'],
  ),
  MetierGridSpec(
    id: 'metier-equipementier-chr',
    name: 'Équipementier CHR — Restauration & hôtellerie',
    description:
        'Prospection de restaurants et hôtels indépendants pour matériel pro.',
    aliases: ['equipementier chr', 'fournisseur chr', 'materiel restauration'],
    targetKeyword: 'restaurant',
    exclusionKeywords: ['mcdonald', 'burger king', 'kfc', 'ibis', 'mercure'],
  ),
];
