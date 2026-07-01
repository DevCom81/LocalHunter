import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/prospects/domain/entities/prospect_filters.dart';

final prospectFiltersProvider =
    StateProvider<ProspectFilters>((ref) => const ProspectFilters());
