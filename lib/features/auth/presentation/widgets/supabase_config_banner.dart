import 'package:flutter/material.dart';



import '../../../../core/config/supabase_config.dart';

import '../../../../core/constants/app_spacing.dart';



class SupabaseConfigBanner extends StatelessWidget {

  const SupabaseConfigBanner({super.key});



  @override

  Widget build(BuildContext context) {

    if (SupabaseConfig.isConfigured) return const SizedBox.shrink();



    return Container(

      padding: const EdgeInsets.all(AppSpacing.md),

      decoration: BoxDecoration(

        color: Theme.of(context).colorScheme.errorContainer,

        borderRadius: BorderRadius.circular(8),

      ),

      child: Text(

        'Supabase non configuré — connexion et inscription désactivées. '

        'Ajoutez un fichier .env à la racine du projet (voir .env.example) '

        'puis relancez l\'app, ou passez SUPABASE_URL et SUPABASE_ANON_KEY '

        'via --dart-define.',

        style: TextStyle(

          color: Theme.of(context).colorScheme.onErrorContainer,

        ),

      ),

    );

  }

}


