import 'package:Softbee/feature/beehive/presentation/controllers/beehive_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import 'package:Softbee/feature/beehive/presentation/providers/beehive_providers.dart';
import 'package:Softbee/feature/beehive/presentation/widgets/beehive_form_dialog.dart'; // Import the new dialog

class ColmenasManagementScreen extends ConsumerStatefulWidget {
  final String apiaryId;
  final String apiaryName;

  const ColmenasManagementScreen({
    super.key,
    required this.apiaryId,
    required this.apiaryName,
  });

  @override
  _ColmenasManagementScreenState createState() =>
      _ColmenasManagementScreenState();
}

class _ColmenasManagementScreenState
    extends ConsumerState<ColmenasManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  List<Beehive> filteredBeehives = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(beehiveControllerProvider.notifier)
          .fetchBeehivesByApiary(widget.apiaryId);
    });
    _searchController.addListener(_filterBeehives);
  }

  void _filterBeehives() {
    final beehiveState = ref.read(beehiveControllerProvider);
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredBeehives = beehiveState.beehives.where((beehive) {
        final hiveNum = beehive.beehiveNumber?.toString() ?? '';
        return hiveNum.contains(query) ||
            (beehive.observations?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beehiveState = ref.watch(beehiveControllerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    if (_searchController.text.isEmpty) {
      filteredBeehives = beehiveState.beehives;
    }

    // Listen for state changes to show SnackBar messages
    ref.listen<BeehiveState>(beehiveControllerProvider, (previous, next) {
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(beehiveControllerProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(beehiveControllerProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title:
            Text(
                  'Gestión de Colmenas',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideX(
                  begin: -0.2,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutQuad,
                ),
        backgroundColor: Colors.amber[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showColmenaDialog(),
              )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
        ],
      ),
      backgroundColor: const Color(0xFFF9F8F6),
      body: beehiveState.isLoading
          ? _buildLoadingWidget()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop
                        ? 1200
                        : (isTablet ? 900 : double.infinity),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeader(isDesktop, isTablet, beehiveState.beehives)
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(
                              begin: -0.2,
                              end: 0,
                              duration: 600.ms,
                              curve: Curves.easeOutQuad,
                            ),
                        SizedBox(height: isDesktop ? 32 : 20),
                        _buildSearchSection(isDesktop, isTablet)
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                        SizedBox(height: isDesktop ? 32 : 20),
                        _buildColmenasSection(isDesktop, isTablet)
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            "Cargando colmenas...",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.amber[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet, List<Beehive> colmenas) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 24 : 20)),
      decoration: BoxDecoration(
        color: Colors.amber[600],
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header principal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                ),
                child:
                    Icon(
                          Icons.hive,
                          size: isDesktop ? 40 : 32,
                          color: Colors.amber[700],
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .rotate(begin: -0.05, end: 0.05, duration: 2000.ms),
              ),
              SizedBox(width: isDesktop ? 24 : 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Apiario: ${widget.apiaryName}',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 28 : (isTablet ? 26 : 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Gestión de colmenas',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 16 : 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 32 : 20),
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeaderStat(
                  icon: Icons.hive_outlined,
                  label: 'Total Colmenas',
                  value: colmenas.length.toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.trending_up_outlined,
                  label: 'Alta Actividad',
                  value: colmenas
                      .where((c) => c.activityLevel == 'Alta')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.home_work_outlined,
                  label: 'Con Producción',
                  value: colmenas
                      .where((c) => c.hasProductionChamber == 'Si')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.favorite_outline,
                  label: 'Saludables',
                  value: colmenas
                      .where((c) => c.healthStatus == 'Ninguno')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
              ],
            )
          else
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildHeaderStat(
                  icon: Icons.hive_outlined,
                  label: 'Total Colmenas',
                  value: colmenas.length.toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.trending_up_outlined,
                  label: 'Alta Actividad',
                  value: colmenas
                      .where((c) => c.activityLevel == 'Alta')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.home_work_outlined,
                  label: 'Con Producción',
                  value: colmenas
                      .where((c) => c.hasProductionChamber == 'Si')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.favorite_outline,
                  label: 'Saludables',
                  value: colmenas
                      .where((c) => c.healthStatus == 'Ninguno')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String label,
    required String value,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDesktop ? 24 : 20, color: Colors.white),
          SizedBox(height: isDesktop ? 8 : 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 14 : 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        _buildSectionTitle(
          'Buscar en ${widget.apiaryName}',
          Icons.search_outlined,
          isDesktop,
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        _buildSearchCard(isDesktop, isTablet),
      ],
    );
  }

  Widget _buildSearchCard(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.amber[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 8),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
            ),
            child: Icon(
              Icons.search,
              color: Colors.amber[700],
              size: isDesktop ? 24 : 20,
            ),
          ),
          SizedBox(width: isDesktop ? 20 : 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por número, apiario u observaciones...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: isDesktop ? 16 : 14,
                  color: Colors.black54,
                ),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 16 : 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColmenasSection(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        if (isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(
                'Colmenas de ${widget.apiaryName}',
                Icons.hive_outlined,
                isDesktop,
              ),
              ElevatedButton.icon(
                onPressed: () => _showColmenaDialog(),
                icon: const Icon(Icons.add),
                label: Text(
                  'Nueva Colmena',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          )
        else // For mobile/tablet
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center the items in column
            children: [
              _buildSectionTitle(
                'Colmenas de ${widget.apiaryName}',
                Icons.hive_outlined,
                isDesktop,
              ),
              SizedBox(height: 16), // Add some space between title and button
              ElevatedButton.icon(
                onPressed: () => _showColmenaDialog(),
                icon: const Icon(Icons.add),
                label: Text(
                  'Nueva Colmena',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: isDesktop ? 16 : 12),
        _buildColmenasList(isDesktop, isTablet),
      ],
    );
  }

  Widget _buildColmenasList(bool isDesktop, bool isTablet) {
    if (filteredBeehives.isEmpty) {
      return _buildEmptyState(isDesktop);
    }

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: filteredBeehives.length,
        itemBuilder: (context, index) {
          return _buildColmenaCard(
            filteredBeehives[index],
            index,
            isDesktop,
            isTablet,
          );
        },
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredBeehives.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: isTablet ? 12 : 8),
        itemBuilder: (context, index) {
          return _buildColmenaCard(
            filteredBeehives[index],
            index,
            isDesktop,
            isTablet,
          );
        },
      );
    }
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 40 : 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.amber[200]!, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.hive, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron colmenas'
                : 'No hay colmenas configuradas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Agrega tu primera colmena para comenzar',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showColmenaDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Crear Colmena'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColmenaCard(
    Beehive beehive,
    int index,
    bool isDesktop,
    bool isTablet,
  ) {
    return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isDesktop ? 24 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.amber[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la colmena
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 12 : 8),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
                    ),
                    child: Icon(
                      Icons.hive,
                      color: Colors.amber[700],
                      size: isDesktop ? 24 : 20,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Colmena #${beehive.beehiveNumber ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: isDesktop ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showColmenaDialog(
                            beehiveToEdit: beehive,
                          ); // Pass the beehive for editing
                          break;
                        case 'delete':
                          _confirmDelete(beehive);
                          break;
                        case 'details':
                          _showColmenaDetails(beehive);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.amber[600],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text('Editar', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Colors.blue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text('Ver Detalles', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text('Eliminar', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Divider(height: isDesktop ? 32 : 24),

              // Información de la colmena
              _buildInfoRow(
                Icons.trending_up_outlined,
                'Nivel de Actividad:',
                beehive.activityLevel ?? 'N/A',
                iconColor: _getActivityColor(beehive.activityLevel ?? ''),
                isDesktop: isDesktop,
              ),

              Divider(height: isDesktop ? 24 : 16),

              _buildInfoRow(
                Icons.favorite_outline,
                'Estado de Salud:',
                beehive.healthStatus ?? 'N/A',
                iconColor: _getHealthColor(beehive.healthStatus ?? ''),
                isHighlight:
                    beehive.healthStatus != null &&
                    beehive.healthStatus != 'Ninguno',
                isDesktop: isDesktop,
              ),

              Divider(height: isDesktop ? 24 : 16),

              _buildInfoRow(
                Icons.home_work_outlined,
                'Cámara de Producción:',
                beehive.hasProductionChamber ?? 'N/A',
                iconColor: beehive.hasProductionChamber == 'Si'
                    ? Colors.green[700]!
                    : Colors.grey[600]!,
                isDesktop: isDesktop,
              ),

              if (beehive.observations != null &&
                  beehive.observations!.isNotEmpty) ...[
                Divider(height: isDesktop ? 24 : 16),
                _buildInfoRow(
                  Icons.notes_rounded,
                  'Observaciones:',
                  beehive.observations!,
                  iconColor: Colors.blueGrey[600]!,
                  isDesktop: isDesktop,
                ),
              ],

              if (isDesktop) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Cuadros de Alimento',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          CircularPercentIndicator(
                            radius: 30,
                            lineWidth: 6,
                            percent: ((beehive.foodFrames ?? 0) / 10).clamp(
                              0.0,
                              1.0,
                            ),
                            center: Text(
                              (beehive.foodFrames ?? 0).toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            progressColor: Colors.blue[600],
                            backgroundColor: Colors.grey[200]!,
                            animation: true,
                            animationDuration: 1000,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Cuadros de Cría',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          CircularPercentIndicator(
                            radius: 30,
                            lineWidth: 6,
                            percent: ((beehive.broodFrames ?? 0) / 10).clamp(
                              0.0,
                              1.0,
                            ),
                            center: Text(
                              (beehive.broodFrames ?? 0).toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                            progressColor: Colors.orange[600],
                            backgroundColor: Colors.grey[200]!,
                            animation: true,
                            animationDuration: 1000,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 * index),
          duration: 600.ms,
        )
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    required Color iconColor,
    bool isHighlight = false,
    required bool isDesktop,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isDesktop ? 12 : 8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
          ),
          child: Icon(icon, color: iconColor, size: isDesktop ? 24 : 20),
        ),
        SizedBox(width: isDesktop ? 20 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 16 : 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.red[700] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(String nivel) {
    switch (nivel) {
      case 'Alta':
        return Colors.green[700]!;
      case 'Media':
        return Colors.amber[700]!;
      case 'Baja':
        return Colors.red[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _getHealthColor(String estado) {
    return estado == 'Ninguno' ? Colors.green[700]! : Colors.red[700]!;
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: isDesktop ? 24 : 20, color: Colors.amber[800]),
        SizedBox(width: isDesktop ? 12 : 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.amber[800],
          ),
        ),
      ],
    );
  }

  void _showColmenaDialog({Beehive? beehiveToEdit}) {
    showDialog(
      context: context,
      builder: (context) => BeehiveFormDialog(
        apiaryId: widget.apiaryId,
        beehiveToEdit: beehiveToEdit,
      ),
    ).then((_) {
      // Refresh beehives after dialog is closed
      ref
          .read(beehiveControllerProvider.notifier)
          .fetchBeehivesByApiary(widget.apiaryId);
    });
  }

  void _confirmDelete(Beehive beehive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Colmena #${beehive.beehiveNumber}'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta colmena? Esta acción es irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(beehiveControllerProvider.notifier)
                  .deleteBeehive(beehive.id, widget.apiaryId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showColmenaDetails(Beehive beehive) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Detalles de la Colmena #${beehive.beehiveNumber ?? 'N/A'}',
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Actividad', beehive.activityLevel ?? 'N/A'),
                _buildDetailRow('Población', beehive.beePopulation ?? 'N/A'),
                _buildDetailRow(
                  'Cuadros de Alimento',
                  (beehive.foodFrames ?? 0).toString(),
                ),
                _buildDetailRow(
                  'Cuadros de Cría',
                  (beehive.broodFrames ?? 0).toString(),
                ),
                _buildDetailRow('Estado', beehive.hiveStatus ?? 'N/A'),
                _buildDetailRow('Salud', beehive.healthStatus ?? 'N/A'),
                _buildDetailRow(
                  'Cámara de Producción',
                  beehive.hasProductionChamber ?? 'N/A',
                ),
                if (beehive.observations != null &&
                    beehive.observations!.isNotEmpty)
                  _buildDetailRow('Observaciones', beehive.observations!),
                if (beehive.createdAt != null)
                  _buildDetailRow(
                    'Creada',
                    beehive.createdAt!.toLocal().toString().substring(0, 16),
                  ),
                if (beehive.updatedAt != null)
                  _buildDetailRow(
                    'Actualizada',
                    beehive.updatedAt!.toLocal().toString().substring(0, 16),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }
}
