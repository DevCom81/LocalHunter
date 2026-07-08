import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

/// Champs d'identité de la grille : nom, description, offre promue.
class GridHeaderFields extends StatelessWidget {
  const GridHeaderFields({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.offerController,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController offerController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nom de la grille'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optionnelle)',
            hintText: 'Ex. : acquisition pharmacies pour groupe immobilier',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: offerController,
          decoration: const InputDecoration(
            labelText: 'Offre promue',
            hintText: 'Ex. : pose et installation de parquet',
            helperText:
                'Recommandée aux prospects pertinents dans les campagnes '
                'utilisant cette grille',
          ),
        ),
      ],
    );
  }
}
