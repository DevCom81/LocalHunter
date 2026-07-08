import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../../prospects/domain/entities/prospect_with_score.dart';

// ignore: avoid_web_libraries_in_flutter
import 'export_io_stub.dart' if (dart.library.io) 'export_io.dart' as export_io;

class ExportService {
  Future<String?> exportCsv(List<ProspectWithScore> items) async {
    final rows = [
      [
        'nom',
        'ville',
        'email',
        'telephone',
        'score',
        'priorite',
        'offre',
        'statut',
      ],
      ...items.map((item) {
        final p = item.prospect;
        final s = item.score;
        return [
          p.name,
          p.city ?? '',
          p.email ?? '',
          p.phone ?? '',
          '${s.globalScore}',
          s.priority.label,
          s.recommendedOffer ?? '',
          p.status.label,
        ];
      }),
    ];
    final csv = const ListToCsvConverter().convert(
      rows.map((r) => r.map((c) => c as dynamic).toList()).toList(),
    );
    return _saveFile('localhunter_export.csv', utf8.encode(csv));
  }

  Future<String?> exportXlsx(List<ProspectWithScore> items) async {
    final excel = Excel.createExcel();
    final sheet = excel['Prospects'];
    sheet.appendRow([
      TextCellValue('nom'),
      TextCellValue('ville'),
      TextCellValue('email'),
      TextCellValue('telephone'),
      TextCellValue('score'),
      TextCellValue('priorite'),
      TextCellValue('offre'),
      TextCellValue('statut'),
    ]);
    for (final item in items) {
      final p = item.prospect;
      final s = item.score;
      sheet.appendRow([
        TextCellValue(p.name),
        TextCellValue(p.city ?? ''),
        TextCellValue(p.email ?? ''),
        TextCellValue(p.phone ?? ''),
        IntCellValue(s.globalScore),
        TextCellValue(s.priority.label),
        TextCellValue(s.recommendedOffer ?? ''),
        TextCellValue(p.status.label),
      ]);
    }
    final bytes = excel.encode();
    if (bytes == null) return null;
    return _saveFile('localhunter_export.xlsx', bytes);
  }

  Future<String?> _saveFile(String name, List<int> bytes) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer l\'export',
      fileName: name,
      bytes: Uint8List.fromList(bytes),
    );
    if (path != null && path.isNotEmpty) {
      if (!kIsWeb) await export_io.writeExportFile(path, bytes);
      return path;
    }
    return null;
  }
}
