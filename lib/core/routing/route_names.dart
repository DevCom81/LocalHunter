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
  static const prospectScore = '/prospects/:id/score';
  static const scoring = '/scoring';
  static const scoringCreate = '/scoring/create';
  static const subscription = '/subscription';
  static const commercialProfile = '/settings/profile';

  static String scoringGridEdit(String gridId) => '$scoring/$gridId';
  static String scoringGridSuggestions(String gridId) =>
      '$scoring/$gridId/suggestions';

  /// Legacy path — redirects to [scoring].
  static const scoringSettings = '/settings/scoring';
}
