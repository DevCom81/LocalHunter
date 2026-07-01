import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/service_providers.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/offer_badge.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../../prospects/presentation/providers/prospect_providers.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../../core/constants/offer_types.dart';

class AiAnalysisScreen extends ConsumerWidget {
  const AiAnalysisScreen({super.key, required this.prospectId});

  final String prospectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(prospectByIdProvider(prospectId));
    final llm = ref.watch(llmProviderProvider);

    return AppScaffold(
      title: 'Analyse IA',
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (item) {
          if (item == null) return const Text('Prospect introuvable');

          return FutureBuilder(
            future: ref.read(campaignByIdProvider(item.prospect.campaignId).future).then(
                  (campaign) => llm.analyzeProspect(
                    prospect: item.prospect,
                    score: item.score,
                    campaignOffer: campaign?.offerType ?? OfferType.easyRest,
                  ),
                ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rec = snapshot.data!;
              if (rec.isEmpty) {
                return const Center(child: Text('IA désactivée'));
              }
              return ListView(
                children: [
                  if (rec.priority != null) PriorityBadge(priority: rec.priority!),
                  if (rec.bestOffer != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OfferBadge(offer: rec.bestOffer!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _Section('Raison principale', rec.mainReason),
                  _Section('Angle commercial', rec.salesAngle),
                  _Section('Message Facebook', rec.facebookMessage),
                  _Section('Email court', rec.shortEmail),
                  _Section('Phrase d\'appel', rec.callOpener),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.content);

  final String title;
  final String? content;

  @override
  Widget build(BuildContext context) {
    if (content == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(content!),
        ],
      ),
    );
  }
}
