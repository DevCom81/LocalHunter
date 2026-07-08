import 'package:flutter/material.dart';

import '../../domain/entities/campaign.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({super.key, required this.campaign, required this.onTap});

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(campaign.name),
        subtitle: Text(
          '${campaign.sector} · ${campaign.city} · ${campaign.radiusKm} km · '
          '${campaign.targetCount} prospects',
        ),
      ),
    );
  }
}
