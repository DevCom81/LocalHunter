import 'package:csv/csv.dart';

import '../../prospects/domain/entities/prospect.dart';

class CsvExporter {
  String export(List<Prospect> prospects) {
    final rows = [
      ['nom', 'ville', 'email', 'telephone', 'site_web', 'categorie', 'statut'],
      ...prospects.map((p) => [
            p.name,
            p.city ?? '',
            p.email ?? '',
            p.phone ?? '',
            p.website ?? '',
            p.category ?? '',
            p.status.label,
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }
}
