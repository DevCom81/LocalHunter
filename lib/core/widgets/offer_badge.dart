import 'package:flutter/material.dart';
import '../constants/offer_types.dart';
import '../theme/badge_styles.dart';

class OfferBadge extends StatelessWidget {
  const OfferBadge({super.key, required this.offer});

  final OfferType offer;

  @override
  Widget build(BuildContext context) {
    final color = offerColor(offer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        offer.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
