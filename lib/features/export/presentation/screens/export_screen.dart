import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../export/data/export_service.dart';
import '../../../prospects/presentation/providers/prospect_providers.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String? _message;
  final _exportService = ExportService();

  Future<void> _export(Future<String?> Function() action) async {
    final path = await action();
    setState(() {
      _message = path != null
          ? 'Export enregistré : $path'
          : 'Export annulé ou non supporté sur cette plateforme.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final prospectsAsync = ref.watch(filteredProspectsProvider(widget.campaignId));

    return AppScaffold(
      title: 'Export',
      body: prospectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${items.length} prospects à exporter'),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _export(() => _exportService.exportCsv(items)),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Exporter CSV'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _export(() => _exportService.exportXlsx(items)),
              icon: const Icon(Icons.grid_on),
              label: const Text('Exporter XLSX'),
            ),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_message!),
            ],
          ],
        ),
      ),
    );
  }
}
