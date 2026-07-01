import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] when auth (or other) streams emit so redirect re-runs
/// without recreating the router instance.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
