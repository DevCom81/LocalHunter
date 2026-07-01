import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/prospect_with_score.dart';
import 'prospect_card.dart';

class ProspectCrmList extends StatelessWidget {
  const ProspectCrmList({super.key, required this.prospects});

  final List<ProspectWithScore> prospects;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: prospects.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) => ProspectCard(
          item: prospects[i],
          onTap: () => context.go('/prospects/${prospects[i].prospect.id}'),
        ),
      ),
      desktop: Scrollbar(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nom')),
                DataColumn(label: Text('Ville')),
                DataColumn(label: Text('Tél')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Score')),
                DataColumn(label: Text('Priorité')),
                DataColumn(label: Text('Offre')),
                DataColumn(label: Text('Statut')),
              ],
              rows: prospects.map((item) {
                final p = item.prospect;
                final s = item.score;
                return DataRow(
                  onSelectChanged: (_) => context.go('/prospects/${p.id}'),
                  cells: [
                    DataCell(Text(p.name)),
                    DataCell(Text(p.city ?? '-')),
                    DataCell(Text(p.phone ?? '-')),
                    DataCell(Text(p.email ?? '-')),
                    DataCell(Text('${s.globalScore}')),
                    DataCell(Text(s.priority.label)),
                    DataCell(Text(s.recommendedOffer?.label ?? '-')),
                    DataCell(Text(p.status.label)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
