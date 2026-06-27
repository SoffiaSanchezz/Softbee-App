import 'package:Softbee/feature/monitoring/presentation/pages/questions_management_page.dart';
import 'package:Softbee/feature/beehive/presentation/pages/beehive_management_page.dart';
import 'package:Softbee/core/widgets/menu_info_apiario.dart';
import 'package:Softbee/feature/monitoring/presentation/pages/monitoring_overview_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../feature/auth/presentation/providers/auth_providers.dart';
import '../../feature/auth/presentation/controllers/auth_controller.dart';
import '../pages/not_found_page.dart';
import '../pages/landing_page.dart';
import '../../feature/auth/presentation/pages/user_management_page.dart';

import '../../feature/inventory/presentation/pages/inventory_management_page.dart'; // NEW INVENTORY PAGE
import '../../feature/apiaries/presentation/pages/reports_page.dart';
import '../../feature/apiaries/presentation/pages/history_page.dart';
import '../../feature/apiaries/presentation/pages/apiary_settings_page.dart';
import '../widgets/dashboard_menu.dart';

import 'app_routes.dart';
import '../../feature/auth/presentation/router/auth_routes.dart';

// Notifier to trigger router refresh on auth state change
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: kIsWeb
        ? AppRoutes.landingRoute
        : AppRoutes.loginRoute, // Lógica de detección de plataforma
    routes: [
      GoRoute(
        path: AppRoutes.landingRoute, // Ruta para Landing Page
        builder: (context, state) => const LandingPage(),
      ),
      ...authRoutes,
      GoRoute(
        path: AppRoutes
            .dashboardRoute, // La ruta principal del dashboard ahora muestra la lista de apiarios
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.userProfileRoute, // Ruta de perfil de usuario
        builder: (context, state) => const UserManagementPage(),
      ),
      // Rutas específicas del apiario
      GoRoute(
        name: AppRoutes.apiaryDashboardRoute,
        path: AppRoutes.apiaryDashboardRoute,
        builder: (context, state) {
          final apiaryId = state.pathParameters['apiaryId'] as String;
          final apiaryName = state.uri.queryParameters['apiaryName'];
          final apiaryLocation = state.uri.queryParameters['apiaryLocation'];

          return ApiaryDashboardMenu(
            apiaryId: apiaryId,
            apiaryName: apiaryName ?? 'Apiario Desconocido',
            apiaryLocation: apiaryLocation,
          );
        },
        routes: [
          GoRoute(
            path: 'monitoring', // This path now leads to the overview page
            name: AppRoutes.monitoringOverviewRoute, // Renamed
            builder: (context, state) {
              final apiaryId = state.pathParameters['apiaryId'] as String;
              final apiaryName = state.uri.queryParameters['apiaryName'];
              final apiaryLocation =
                  state.uri.queryParameters['apiaryLocation'];
              return MonitoringOverviewPage(
                apiaryId: apiaryId,
                apiaryName: apiaryName,
                apiaryLocation: apiaryLocation,
              );
            },
            routes: [
              GoRoute(
                path: 'beehives', // Nested route for beehive management
                name: AppRoutes.beehiveManagementRoute, // New route name
                builder: (context, state) {
                  final apiaryId = state.pathParameters['apiaryId'] as String;
                  final apiaryName =
                      state.uri.queryParameters['apiaryName'] ??
                      'Apiario'; // Get apiaryName
                  return ColmenasManagementScreen(
                    apiaryId: apiaryId,
                    apiaryName: apiaryName,
                  ); // Pass apiaryName
                },
              ),
              GoRoute(
                path: 'questions',
                name: AppRoutes.questionsManagementRoute,
                builder: (context, state) {
                  final apiaryId = state.pathParameters['apiaryId']!;
                  return QuestionsManagementScreen(apiaryId: apiaryId);
                },
              ),

              // Other monitoring sub-options (e.g., 'questions', 'maya') can be added here
            ],
          ),
          GoRoute(
            path: 'inventory',
            name: AppRoutes.inventoryRoute,
            builder: (context, state) {
              final apiaryId =
                  state.pathParameters['apiaryId']
                      as String; // Changed back to String
              return InventoryManagementPage(
                apiaryId: apiaryId,
              ); // Use new page
            },
          ),
          GoRoute(
            path: 'reports',
            name: AppRoutes.reportsRoute,
            builder: (context, state) {
              final apiaryId = state.pathParameters['apiaryId'] as String;
              return ReportsPage(apiaryId: apiaryId);
            },
          ),
          GoRoute(
            path: 'history',
            name: AppRoutes.historyRoute,
            builder: (context, state) {
              final apiaryId = state.pathParameters['apiaryId'] as String;
              return HistoryPage(apiaryId: apiaryId);
            },
          ),
          GoRoute(
            path: 'settings',
            name: AppRoutes.apiarySettingsRoute,
            builder: (context, state) {
              final apiaryId = state.pathParameters['apiaryId'] as String;
              return ApiarySettingsPage(apiaryId: apiaryId);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.loginRoute ||
          state.matchedLocation == AppRoutes.registerRoute ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation.startsWith(
            AppRoutes.resetPasswordRoute.split(':')[0],
          );
      final isLandingRoute = state.matchedLocation == AppRoutes.landingRoute;

      // If we are still checking the authentication status, don't redirect yet
      if (authState.isAuthenticating) {
        return null; // Or a loading screen route
      }

      // Si no está logueado y no está en una ruta de autenticación o landing, redirigir al login
      if (!isLoggedIn && !isAuthRoute && !isLandingRoute) {
        return AppRoutes.loginRoute;
      }

      // Si está logueado y en una ruta de autenticación o landing, redirigir al dashboard
      if (isLoggedIn && (isAuthRoute || isLandingRoute)) {
        return AppRoutes.dashboardRoute;
      }

      return null;
    },
    errorBuilder: (context, state) =>
        const NotFoundPage(), // Añadir errorBuilder
  );
});
