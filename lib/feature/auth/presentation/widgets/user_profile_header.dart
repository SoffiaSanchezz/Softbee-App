import 'package:Softbee/core/router/app_routes.dart';
import 'package:Softbee/feature/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileHeader extends ConsumerWidget {
  const UserProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    // Muestra un indicador de carga mientras se autentica
    if (authState.isAuthenticating ||
        (authState.isAuthenticated && authState.user == null)) {
      return const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Si el usuario está autenticado, muestra el perfil clickeable
    if (authState.isAuthenticated && authState.user != null) {
      final user = authState.user!;
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;
      final isMobile = screenWidth < 600;

      final userName = user.username;
      final userEmail = user.email;

      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: Color.fromRGBO(255, 193, 7, 0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF57C00),
                    ),
                  ),
                ),
                // Mostrar nombre solo en pantallas grandes
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF424242),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Color(0xFF9E9E9E),
                  ),
                ],
              ],
            ),
          ),
          itemBuilder: (context) => [
            // Header del menu con info del usuario
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Color.fromRGBO(255, 193, 7, 0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF57C00),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              userEmail,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF757575),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                ],
              ),
            ),
            // Opcion: Mi perfil
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: Color(0xFF616161),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mi perfil',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
            // Opcion: Configuracion
            PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Color(0xFF616161),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Configuracion',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // Opcion: Cerrar sesion
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cerrar sesion',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'profile':
                context.go(AppRoutes.userProfileRoute);
                break;
              case 'settings':
                context.go(AppRoutes.settingsRoute);
                break;
              case 'logout':
                ref.read(authControllerProvider.notifier).logout();
                break;
            }
          },
        ),
      );
    }
    // Si no está autenticado, no muestra nada
    return const SizedBox.shrink();
  }
}
