import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ApiaryCard extends StatelessWidget {
  final Apiary apiary;
  final VoidCallback onTap;
  final Function(Apiary) onEdit;
  final Function(Apiary) onDelete;

  const ApiaryCard({
    super.key,
    required this.apiary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 6.0 : 10.0,
        horizontal: isSmallScreen ? 12.0 : 16.0,
      ),
      elevation: isSmallScreen ? 2 : 4,
      shadowColor: const Color(0xFFFFC107).withAlpha(76),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, const Color(0xFFFFF8E1).withAlpha(128)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // Evita scroll innecesario pero previene overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: Icono + Nombre + Menú
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIconContainer(
                        size: isSmallScreen ? 48 : 56,
                        iconSize: isSmallScreen ? 26 : 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apiary.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Color(0xFF9E9E9E),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    apiary.location ??
                                        'Ubicación no especificada',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF757575),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildPopupMenu(),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Divider sutil
                  Container(
                    height: 1,
                    color: const Color(0xFFE0E0E0).withAlpha(128),
                  ),

                  const SizedBox(height: 6), 
                  // Stats en una fila limpia
                  Row(
                    children: [
                      // Colmenas
                      Expanded(
                        child: _buildStatChip(
                          icon: Icons.grid_view_rounded,
                          value: '${apiary.beehivesCount ?? 0}',
                          label: 'Colmenas',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Fecha de creación
                      Expanded(
                        child: _buildStatChip(
                          icon: Icons.calendar_today_rounded,
                          value: _formatDate(apiary.createdAt),
                          label: 'Creado',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Botón de acción
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ver detalles',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFF57C00),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Color(0xFFF57C00),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          onEdit(apiary);
        } else if (value == 'delete') {
          onDelete(apiary);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.blue),
              SizedBox(width: 10),
              Text('Editar'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 10),
              Text('Eliminar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildIconContainer({required double size, required double iconSize}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFC107).withAlpha(64),
            const Color(0xFFFFB300).withAlpha(38),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: const Color(0xFFFFC107).withAlpha(76),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.hive_rounded,
        color: const Color(0xFFF57C00),
        size: iconSize,
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFF57C00)),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
