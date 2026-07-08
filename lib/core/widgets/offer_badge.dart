import 'package:flutter/material.dart';

/// Badge affichant l'offre promue (libellé libre issu de la grille).
class OfferBadge extends StatelessWidget {
  const OfferBadge({super.key, required this.label});

  final String label;

  static const _color = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
