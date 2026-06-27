import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Softbee/core/router/app_routes.dart';

class MonitoringOverviewPage extends StatelessWidget {
  final String apiaryId;
  final String? apiaryName;
  final String? apiaryLocation;

  const MonitoringOverviewPage({
    super.key,
    required this.apiaryId,
    this.apiaryName,
    this.apiaryLocation,
  });

  // --- Paleta de colores ---
  static const Color _primaryColor = Color(0xFFF5A623);
  static const Color _primaryDark = Color(0xFFE8961A);
  static const Color _backgroundLight = Color(0xFFF8F5F0);
  static const Color _cardColmena = Color(0xFFFFF3E0);
  static const Color _cardPreguntas = Color(0xFFE8F5E9);
  static const Color _cardMaya = Color(0xFFE3F2FD);
  static const Color _iconColmena = Color(0xFFF5A623);
  static const Color _iconPreguntas = Color(0xFF66BB6A);
  static const Color _iconMaya = Color(0xFF42A5F5);
  static const Color _textPrimary = Color(0xFF2D2D2D);
  static const Color _textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 900;
    final horizontalPadding = isDesktop ? 64.0 : (isTablet ? 40.0 : 20.0);

    return Scaffold(
      backgroundColor: _backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- AppBar personalizado ---
            SliverToBoxAdapter(child: _buildHeader(context, horizontalPadding)),

            // --- Sección de bienvenida ---
            SliverToBoxAdapter(child: _buildWelcomeSection(horizontalPadding)),

            // --- Tarjetas de monitoreo ---
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              sliver: isDesktop
                  ? _buildGridCards(context)
                  : _buildListCards(context),
            ),

            // --- Espacio inferior ---
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // =============================================
  // HEADER
  // =============================================
  Widget _buildHeader(BuildContext context, double horizontalPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 0),
      child: Row(
        children: [
          // Botón de regreso
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            shadowColor: Colors.black12,
            child: InkWell(
              onTap: () => context.goNamed(
                AppRoutes.apiaryDashboardRoute,
                pathParameters: {'apiaryId': apiaryId},
                queryParameters: {
                  'apiaryName': apiaryName ?? '',
                  'apiaryLocation': apiaryLocation ?? '',
                },
              ),
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Título
          Expanded(
            child: Text(
              'Monitoreo',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Ícono decorativo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryColor, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // SECCIÓN DE BIENVENIDA
  // =============================================
  Widget _buildWelcomeSection(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        28,
        horizontalPadding,
        20,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF5A623), Color(0xFFFFCC02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withAlpha((255 * 0.3).round()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.25).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.hive_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, Apicultor!',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Selecciona una opción para continuar',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withAlpha((255 * 0.85).round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // GRID DE TARJETAS (para Desktop >= 900px)
  // =============================================
  SliverGrid _buildGridCards(BuildContext context) {
    final items = _getMonitoringItems(context);
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            _buildCard(context, item: items[index], isGridLayout: true),
        childCount: items.length,
      ),
    );
  }

  // =============================================
  // LISTA DE TARJETAS (para móvil y tablet)
  // =============================================
  SliverList _buildListCards(BuildContext context) {
    final items = _getMonitoringItems(context);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCard(context, item: items[index], isGridLayout: false),
        ),
        childCount: items.length,
      ),
    );
  }

  // =============================================
  // TARJETA INDIVIDUAL
  // =============================================
  Widget _buildCard(
    BuildContext context, {
    required _MonitoringItem item,
    required bool isGridLayout,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: item.accentColor.withAlpha((255 * 0.1).round()),
        highlightColor: item.accentColor.withAlpha((255 * 0.05).round()),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.withAlpha((255 * 0.08).round()),
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(isGridLayout ? 20 : 20),
          child: isGridLayout
              ? _buildGridContent(item)
              : _buildListContent(item),
        ),
      ),
    );
  }

  // --- Contenido en modo Grid ---
  Widget _buildGridContent(_MonitoringItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: item.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(item.icon, size: 28, color: item.accentColor),
        ),
        const SizedBox(height: 16),
        Text(
          item.title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: _textSecondary,
            height: 1.4,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              'Abrir',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: item.accentColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: item.accentColor,
            ),
          ],
        ),
      ],
    );
  }

  // --- Contenido en modo Lista ---
  Widget _buildListContent(_MonitoringItem item) {
    return Row(
      children: [
        // Ícono con fondo
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: item.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(item.icon, size: 28, color: item.accentColor),
        ),
        const SizedBox(width: 16),
        // Texto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Flecha
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: item.backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: item.accentColor,
          ),
        ),
      ],
    );
  }

  // =============================================
  // DATOS DE LAS OPCIONES
  // =============================================
  List<_MonitoringItem> _getMonitoringItems(BuildContext context) {
    return [
      _MonitoringItem(
        title: 'Colmena',
        description: 'Gestiona y visualiza la información de tus colmenas.',
        icon: Icons.hive_rounded,
        backgroundColor: _cardColmena,
        accentColor: _iconColmena,
        onTap: () {
          context.goNamed(
            AppRoutes.beehiveManagementRoute,
            pathParameters: {'apiaryId': apiaryId},
          );
        },
      ),
      _MonitoringItem(
        title: 'Preguntas',
        description: 'Realiza preguntas sobre el estado de tu apiario.',
        icon: Icons.question_answer_rounded,
        backgroundColor: _cardPreguntas,
        accentColor: _iconPreguntas,
        onTap: () {
          context.goNamed(
            AppRoutes.questionsManagementRoute,
            pathParameters: {'apiaryId': apiaryId},
          );
        },
      ),
      _MonitoringItem(
        title: 'Maya',
        description: 'Asistente de voz para ayudarte con tus apiarios.',
        icon: Icons.mic_rounded,
        backgroundColor: _cardMaya,
        accentColor: _iconMaya,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Navegar a Maya (TODO)',
                style: GoogleFonts.poppins(),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    ];
  }
}

// =============================================
// MODELO DE DATOS PARA CADA OPCIÓN
// =============================================
class _MonitoringItem {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _MonitoringItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
    required this.onTap,
  });
}
