abstract class AppRoutes {
  static const String landingRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String dashboardRoute =
      '/dashboard'; // This is the main dashboard, not apiary specific
  static const String userProfileRoute = '/profile';
  static const String resetPasswordRoute = '/reset-password/:token';

  // Apiary-specific routes
  static const String apiaryDashboardRoute = '/apiary-dashboard/:apiaryId';
  static const String monitoringOverviewRoute = // Renamed
      '/apiary-dashboard/:apiaryId/monitoring';
  static const String questionsManagementRoute =
      '/apiary-dashboard/:apiaryId/monitoring/questions';
  static const String beehiveManagementRoute = // New route for beehives
      '/apiary-dashboard/:apiaryId/hives';
  static const String inventoryRoute = '/apiary-dashboard/:apiaryId/inventory';
  static const String reportsRoute = '/apiary-dashboard/:apiaryId/reports';
  static const String historyRoute = '/apiary-dashboard/:apiaryId/history';
  static const String hivesRoute =
      '/apiary-dashboard/:apiaryId/hives'; // Keep for now, might be referenced elsewhere
  static const String apiarySettingsRoute =
      '/apiary-dashboard/:apiaryId/settings';
}
