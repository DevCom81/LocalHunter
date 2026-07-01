import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../providers/prospect_providers.dart';

class ImportCsvScreen extends ConsumerStatefulWidget {
  const ImportCsvScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends ConsumerState<ImportCsvScreen> {
  String? _message;

  Future<void> _importContent(String content) async {
    try {
      final count = await ref.read(importCsvProvider.notifier).importFromContent(
            campaignId: widget.campaignId,
            content: content,
          );
      setState(() => _message = '$count prospects importés avec scores.');
    } catch (e) {
      setState(() => _message = 'Erreur : $e');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final content = file.bytes != null
        ? String.fromCharCodes(file.bytes!)
        : await file.xFile.readAsString();
    await _importContent(content);
  }

  Future<void> _importFixture() async {
    final content = await rootBundle.loadString(
      'assets/fixtures/albi_restaurants.csv',
    );
    await _importContent(content);
  }

  @override
  Widget build(BuildContext context) {
    final importing = ref.watch(importCsvProvider).isLoading;

    return AppScaffold(
      title: 'Import CSV',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Colonnes : nom, ville, adresse, responsable, email, telephone, '
            'site_web, facebook, instagram, note_google, nb_avis, categorie',
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: importing ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Sélectionner un fichier CSV'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: importing ? null : _importFixture,
            icon: const Icon(Icons.restaurant),
            label: const Text('Importer fixture Albi'),
          ),
          if (importing) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}
