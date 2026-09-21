import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/prospect_status.dart';
import '../../domain/entities/prospect.dart';
import '../providers/prospect_providers.dart';

/// Sélecteur de statut CRM (pipeline + motifs de sortie).
class ProspectStatusSelector extends ConsumerWidget {
  const ProspectStatusSelector({super.key, required this.prospect});

  final Prospect prospect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statut', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProspectStatus>(
              value: prospect.status,
              isExpanded: true,
              items: ProspectStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    ),
                  )
                  .toList(),
              onChanged: (status) {
                if (status == null || status == prospect.status) return;
                setProspectStatus(ref, prospect, status);
              },
            ),
          ),
        ),
      ],
    );
  }
}
