import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/prospect.dart';

/// Fiche d'identité du prospect : contact, immatriculation (SIRET, TVA)
/// et données financières du dernier bilan publié.
class ProspectInfoSection extends StatelessWidget {
  const ProspectInfoSection({super.key, required this.prospect});

  final Prospect prospect;

  @override
  Widget build(BuildContext context) {
    final p = prospect;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoRow('Adresse', p.address),
        InfoRow('Téléphone', p.phone),
        InfoRow('Email', p.email),
        InfoRow('Site web', p.website),
        InfoRow('Responsable', p.managerName),
        if (p.siret != null)
          InfoRow('SIRET', p.siret)
        else if (p.siren != null)
          InfoRow('SIREN', p.siren),
        if (p.vatNumber != null) InfoRow('N° TVA', p.vatNumber),
        if (p.creationDate != null)
          InfoRow('Création', formatDate(p.creationDate!)),
        if (p.annualRevenue != null)
          InfoRow(
            p.annualRevenueYear != null
                ? "Chiffre d'affaires ${p.annualRevenueYear}"
                : "Chiffre d'affaires",
            formatEuros(p.annualRevenue!),
          ),
        if (p.netIncome != null)
          InfoRow('Résultat net', formatEuros(p.netIncome!)),
        InfoRow('Ville', p.city),
        InfoRow('Catégorie', p.category),
        InfoRow('Note Google', p.googleRating?.toString()),
        InfoRow('Avis', '${p.googleReviews}'),
        if (p.pagespeedScore != null)
          InfoRow('PageSpeed mobile', '${p.pagespeedScore}/100'),
        InfoRow('Statut', p.status.label),
        if (p.isExcluded) InfoRow('Exclusion', p.exclusionReason),
      ],
    );
  }
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Montant en euros lisible : 1 234 567 -> « 1,2 M€ », 45 600 -> « 46 k€ ».
String formatEuros(int amount) {
  final abs = amount.abs();
  if (abs >= 1000000) {
    final m = (amount / 1000000).toStringAsFixed(1).replaceAll('.', ',');
    return '$m M€';
  }
  if (abs >= 10000) return '${(amount / 1000).round()} k€';
  return '$amount €';
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child:
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}
