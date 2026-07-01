import 'dart:io';

Future<void> writeExportFile(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes);
}
