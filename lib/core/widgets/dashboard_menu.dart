import 'package:Softbee/feature/apiaries/presentation/providers/apiary_providers.dart';
import 'package:Softbee/feature/apiaries/presentation/widgets/apiaries_menu.dart';
import 'package:Softbee/feature/apiaries/presentation/widgets/apiary_form_dialog.dart';
import 'package:Softbee/feature/auth/presentation/widgets/user_profile_header.dart';
import 'package:Softbee/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        automaticallyImplyLeading: false,
        titleSpacing: isSmallScreen ? 12 : 16,
        title: Row(
          children: [
            // Logo de Softbee
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 79, 70, 1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/Logo.png', // Reemplaza con tu asset
                width: isSmallScreen ? 32 : 34,
                height: isSmallScreen ? 28 : 32,
                // Si no tienes el asset, usa un icono:
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.hive_rounded,
                  color: const Color(0xFFF57C00),
                  size: isSmallScreen ? 24 : 28,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Titulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mis apiarios',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  if (!isMobile)
                    Text(
                      'Gestiona tus colmenas',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Widget de perfil de usuario
          const UserProfileHeader(),
          SizedBox(width: isSmallScreen ? 4 : 8),
          // Boton de configuracion
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.go(AppRoutes.settingsRoute),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
        ],
      ),
      body: const ApiariesMenu(),
      // FAB para crear nuevo apiario (responsive)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ApiaryFormDialog(),
          ).then((_) {
            // Refresh apiaries after dialog is closed
            ref.read(apiariesControllerProvider.notifier).fetchApiaries();
          });
        },
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          isMobile ? 'Nuevo' : 'Nuevo apiario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
