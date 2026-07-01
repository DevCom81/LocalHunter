import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../../core/constants/app_spacing.dart';

import '../../../../core/widgets/app_scaffold.dart';

import '../providers/prospect_providers.dart';

import '../widgets/prospect_crm_list.dart';

import '../widgets/prospect_filters_bar.dart';



class CrmScreen extends ConsumerWidget {

  const CrmScreen({super.key, required this.campaignId});



  final String campaignId;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final prospectsAsync = ref.watch(filteredProspectsProvider(campaignId));



    return AppScaffold(

      title: 'CRM Prospects',

      body: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          ProspectFiltersBar(campaignId: campaignId),

          const SizedBox(height: AppSpacing.md),

          Expanded(

            child: prospectsAsync.when(

              loading: () => const Center(child: CircularProgressIndicator()),

              error: (e, _) => Center(child: Text('Erreur : $e')),

              data: (prospects) {

                return Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text('${prospects.length} résultats'),

                    const SizedBox(height: AppSpacing.sm),

                    Expanded(child: ProspectCrmList(prospects: prospects)),

                  ],

                );

              },

            ),

          ),

        ],

      ),

    );

  }

}

