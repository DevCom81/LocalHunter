abstract final class RouteNames {
  static const login = '/login';
  static const signUp = '/signup';
  static const settings = '/settings';
  static const dashboard = '/dashboard';
  static const campaigns = '/campaigns';
  static const campaignDetail = '/campaigns/:id';
  static const campaignImport = '/campaigns/:id/import';
  static const campaignProspects = '/campaigns/:id/prospects';
  static const campaignExport = '/campaigns/:id/export';
  static const prospectDetail = '/prospects/:id';
  static const prospectAi = '/prospects/:id/ai';
  static const scoring = '/scoring';
  static const scoringCreate = '/scoring/create';

  static String scoringGridEdit(String gridId) => '$scoring/$gridId';

  /// Legacy path — redirects to [scoring].
  static const scoringSettings = '/settings/scoring';
}
