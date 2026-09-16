import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/entities/user.dart';
import '../providers/auth_providers.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/profile_avatar.dart';

/// Vista moderna y responsive del perfil de usuario de Softbee.
///
/// Reúne: encabezado del perfil, información personal (editable), seguridad,
/// configuración y cierre de sesión. Lee el usuario actual desde
/// `authControllerProvider` y refleja de inmediato los cambios guardados.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  static const double _kDesktopBreakpoint = 1024;
  static const Color _bg = Color(0xFFF6F7F9);

  // Preferencia local de UI (no persistida): estructura lista para conectar
  // con notificaciones reales cuando exista soporte.
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (authState.isAuthenticating ||
        (authState.isAuthenticated && authState.user == null)) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    if (user == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(),
        body: Center(
          child: Text('No hay una sesión activa.',
              style: GoogleFonts.poppins(color: Colors.grey.shade600)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;
          return isDesktop ? _buildDesktop(user) : _buildMobile(user);
        },
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: Text('Mi Perfil',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.amber.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Layouts
  // ---------------------------------------------------------------------------

  Widget _buildDesktop(User user) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(user, isDesktop: true),
              const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildPersonalInfoCard(user)),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildSecurityCard(),
                          const SizedBox(height: 20),
                          _buildSettingsCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildLogoutButton(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(user, isDesktop: false),
          const SizedBox(height: 16),
          _buildPersonalInfoCard(user),
          const SizedBox(height: 16),
          _buildSecurityCard(),
          const SizedBox(height: 16),
          _buildSettingsCard(),
          const SizedBox(height: 20),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Encabezado
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(User user, {required bool isDesktop}) {
    final displayName =
        (user.fullName != null && user.fullName!.trim().isNotEmpty)
            ? user.fullName!
            : user.username;
    final role = (user.role != null && user.role!.trim().isNotEmpty)
        ? user.role!
        : 'Apicultor';

    final avatar = Stack(
      children: [
        ProfileAvatar(
          photoUrl: user.photoUrl,
          nameSource: displayName,
          radius: isDesktop ? 48 : 44,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => _openEditDialog(user),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );

    final statusChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
      children: [
        _roleChip(role),
        _statusChip(
          user.isActive ? 'Cuenta activa' : 'Cuenta inactiva',
          user.isActive ? Colors.green.shade600 : Colors.grey.shade500,
          user.isActive ? Icons.check_circle_rounded : Icons.remove_circle_rounded,
        ),
        _statusChip(
          user.isVerified ? 'Verificada' : 'Sin verificar',
          user.isVerified ? Colors.blue.shade600 : Colors.orange.shade600,
          user.isVerified ? Icons.verified_rounded : Icons.info_rounded,
        ),
      ],
    );

    final editButton = ElevatedButton.icon(
      onPressed: () => _openEditDialog(user),
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: Text('Editar perfil',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber.shade800,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                avatar,
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('@${user.username}',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email_rounded,
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(user.email,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9)),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      statusChips,
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                editButton,
              ],
            )
          : Column(
              children: [
                avatar,
                const SizedBox(height: 14),
                Text(displayName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text('@${user.username}',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 4),
                Text(user.email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 14),
                statusChips,
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, child: editButton),
              ],
            ),
    );
  }

  Widget _roleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded,
              size: 15, color: Colors.amber.shade800),
          const SizedBox(width: 6),
          Text(role,
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade800)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Información personal
  // ---------------------------------------------------------------------------

  Widget _buildPersonalInfoCard(User user) {
    return _sectionCard(
      icon: Icons.person_rounded,
      title: 'Información personal',
      trailing: TextButton.icon(
        onPressed: () => _openEditDialog(user),
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text('Editar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(foregroundColor: Colors.amber.shade800),
      ),
      children: [
        _infoRow(Icons.badge_rounded, 'Nombre completo', user.fullName),
        _infoRow(Icons.alternate_email_rounded, 'Nombre de usuario', user.username),
        _infoRow(Icons.email_rounded, 'Correo electrónico', user.email),
        _infoRow(Icons.phone_rounded, 'Teléfono', user.phone),
        _infoRow(Icons.location_on_rounded, 'Ubicación', user.location),
        _infoRow(
          Icons.calendar_today_rounded,
          'Fecha de registro',
          user.createdAt != null
              ? DateFormat('dd/MM/yyyy').format(user.createdAt!)
              : null,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Seguridad
  // ---------------------------------------------------------------------------

  Widget _buildSecurityCard() {
    return _sectionCard(
      icon: Icons.shield_rounded,
      title: 'Seguridad',
      children: [
        _actionTile(
          icon: Icons.lock_reset_rounded,
          title: 'Cambiar contraseña',
          subtitle: 'Actualiza tu contraseña de acceso',
          onTap: () => _showComingSoon(
            'Cambiar contraseña',
            'Esta opción estará disponible cuando el backend exponga el endpoint correspondiente.',
          ),
        ),
        _actionTile(
          icon: Icons.verified_user_rounded,
          title: 'Verificación en dos pasos',
          subtitle: 'Añade una capa extra de seguridad',
          onTap: () => _showComingSoon(
            'Verificación en dos pasos',
            'Función preparada para futuras versiones.',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Configuración
  // ---------------------------------------------------------------------------

  Widget _buildSettingsCard() {
    return _sectionCard(
      icon: Icons.settings_rounded,
      title: 'Configuración',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.amber.shade700,
          secondary: _tileIcon(Icons.notifications_rounded),
          title: Text('Notificaciones',
              style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800)),
          subtitle: Text('Preferencia local del dispositivo',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
          value: _notificationsEnabled,
          onChanged: (v) => setState(() => _notificationsEnabled = v),
        ),
        _actionTile(
          icon: Icons.palette_rounded,
          title: 'Apariencia',
          subtitle: 'Tema claro',
          onTap: () => _showComingSoon(
            'Apariencia',
            'La personalización de tema estará disponible próximamente.',
          ),
        ),
        _actionTile(
          icon: Icons.language_rounded,
          title: 'Idioma',
          subtitle: 'Español',
          onTap: () => _showComingSoon(
            'Idioma',
            'La selección de idioma estará disponible próximamente.',
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _confirmLogout,
      icon: Icon(Icons.logout_rounded, color: Colors.red.shade600),
      label: Text('Cerrar sesión',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.red.shade600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.red.shade200),
        backgroundColor: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets reutilizables
  // ---------------------------------------------------------------------------

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.amber.shade800, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900)),
              ),
              ?trailing,
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    final bool empty = value == null || value.trim().isEmpty;
    final display = empty ? 'No disponible' : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              display,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                color: empty ? Colors.grey.shade400 : Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.amber.shade800, size: 20),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _tileIcon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  Future<void> _openEditDialog(User user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditProfileDialog(user: user),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil actualizado correctamente',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showComingSoon(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Entendido',
                style: GoogleFonts.poppins(
                    color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('¿Seguro que deseas cerrar tu sesión?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white),
            child: Text('Cerrar sesión',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      // El RouterNotifier redirige automáticamente a /login al cerrar sesión.
    }
  }
}
