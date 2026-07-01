import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';

class ProspectsListScreen extends StatelessWidget {
  const ProspectsListScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Prospects',
      body: Center(child: Text('Liste prospects — campagne $campaignId')),
    );
  }
}
