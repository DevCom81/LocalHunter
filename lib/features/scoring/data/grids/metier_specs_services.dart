import 'metier_grid_builder.dart';

/// Métiers du conseil et des services aux entreprises (10 specs).
const metierSpecsServices = <MetierGridSpec>[
  MetierGridSpec(
    id: 'metier-assureur',
    name: 'Assureur — Commerces & artisans',
    description: 'Prospection de commerces et artisans locaux à assurer.',
    aliases: ['assureur', 'agent d\'assurance', 'courtier en assurance'],
    targetKeyword: 'commerce',
    exclusionKeywords: ['axa', 'allianz', 'groupama', 'maif', 'macif'],
  ),
  MetierGridSpec(
    id: 'metier-courtier-credit',
    name: 'Courtier en crédit — Immobilier local',
    description:
        'Prospection d\'agences immobilières et promoteurs partenaires.',
    aliases: ['courtier en credit', 'courtier credit', 'courtier en pret'],
    targetKeyword: 'immobilier',
    exclusionKeywords: ['orpi', 'century 21', 'laforet', 'guy hoquet'],
  ),
  MetierGridSpec(
    id: 'metier-expert-comptable',
    name: 'Expert-comptable — TPE locales',
    description: 'Prospection de commerces et TPE pour la tenue comptable.',
    aliases: ['expert-comptable', 'expert comptable', 'cabinet comptable'],
    targetKeyword: 'commerce',
    exclusionKeywords: ['fiducial', 'in extenso', 'cerfrance'],
  ),
  MetierGridSpec(
    id: 'metier-avocat',
    name: 'Avocat d\'affaires — Entreprises locales',
    description: 'Prospection de PME pour le conseil juridique récurrent.',
    aliases: ['avocat', 'avocat d\'affaires', 'cabinet d\'avocats'],
    targetKeyword: 'entreprise',
    targetPoints: 15,
  ),
  MetierGridSpec(
    id: 'metier-consultant-marketing',
    name: 'Consultant marketing — Commerces locaux',
    description:
        'Prospection de commerces à accompagner sur leur visibilité.',
    aliases: [
      'consultant marketing',
      'consultant marketing digital',
      'consultant seo',
    ],
    targetKeyword: 'commerce',
    minRating: 3.5,
  ),
  MetierGridSpec(
    id: 'metier-agence-communication',
    name: 'Agence de communication — PME locales',
    description:
        'Prospection de PME et commerces pour identité visuelle et campagnes.',
    aliases: ['agence de communication', 'agence de com', 'graphiste'],
    targetKeyword: 'commerce',
    minRating: 3.5,
  ),
  MetierGridSpec(
    id: 'metier-organisme-formation',
    name: 'Organisme de formation — Entreprises',
    description:
        'Prospection d\'entreprises locales pour la formation professionnelle.',
    aliases: [
      'organisme de formation',
      'formateur',
      'formateur professionnel',
      'centre de formation',
    ],
    targetKeyword: 'entreprise',
    targetPoints: 15,
  ),
  MetierGridSpec(
    id: 'metier-agence-interim',
    name: 'Agence d\'intérim — BTP & industrie',
    description:
        'Prospection d\'entreprises du BTP et de l\'industrie en besoin de main-d\'œuvre.',
    aliases: ['agence d\'interim', 'interim', 'agence de recrutement'],
    targetKeyword: 'construction',
    exclusionKeywords: ['vinci', 'bouygues', 'eiffage', 'spie'],
  ),
  MetierGridSpec(
    id: 'metier-integrateur-it',
    name: 'Intégrateur informatique — PME locales',
    description:
        'Prospection de PME et cabinets pour infogérance et équipement IT.',
    aliases: [
      'integrateur informatique',
      'prestataire informatique',
      'infogerance',
      'integrateur telecom',
    ],
    targetKeyword: 'entreprise',
    targetPoints: 15,
  ),
  MetierGridSpec(
    id: 'metier-nettoyage',
    name: 'Nettoyage B2B — Bureaux & commerces',
    description:
        'Prospection de bureaux et commerces pour l\'entretien régulier.',
    aliases: [
      'societe de nettoyage',
      'entreprise de nettoyage',
      'nettoyage professionnel',
    ],
    targetKeyword: 'bureau',
    minReviews: 5,
    exclusionKeywords: ['onet', 'samsic', 'atalian', 'gsf'],
  ),
];
