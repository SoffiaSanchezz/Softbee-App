import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Softbee/core/router/app_routes.dart';
import 'package:Softbee/feature/apiaries/presentation/providers/apiary_providers.dart';
import 'package:Softbee/feature/auth/presentation/providers/auth_providers.dart';
import 'package:Softbee/feature/auth/presentation/widgets/profile_avatar.dart';

/// Vista centralizada de configuración de toda la aplicación Softbee.
///
/// Reúne cuenta, seguridad, notificaciones, apariencia, idioma, preferencias
/// de Softbee, información y cierre de sesión. Reutiliza la lógica existente
/// (autenticación, sincronización) y deja preparada la estructura visual de
/// las opciones que aún no tienen soporte en el backend/app.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const Color _bg = Color(0xFFF6F7F9);
  static const String _appVersion = '1.0.0';

  // Preferencias locales de UI (no persistidas todavía). Estructura lista para
  // conectar con providers reales cuando existan.
  bool _pushNotifications = true;
  bool _hiveAlerts = true;
  bool _autoSync = true;
  String _themeMode = 'Sistema'; // Sistema | Claro | Oscuro
  String _language = 'Español';
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Configuración',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 720;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAccountCard(),
                    const SizedBox(height: 16),
                    if (isWide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSecurityCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNotificationsCard()),
                          ],
                        ),
                      )
                    else ...[
                      _buildSecurityCard(),
                      const SizedBox(height: 16),
                      _buildNotificationsCard(),
                    ],
                    const SizedBox(height: 16),
                    if (isWide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildAppearanceCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildLanguageCard()),
                          ],
                        ),
                      )
                    else ...[
                      _buildAppearanceCard(),
                      const SizedBox(height: 16),
                      _buildLanguageCard(),
                    ],
                    const SizedBox(height: 16),
                    _buildSoftbeePreferencesCard(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildLogoutButton(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 👤 Cuenta
  // ---------------------------------------------------------------------------

  Widget _buildAccountCard() {
    final user = ref.watch(authControllerProvider).user;
    final displayName = (user?.fullName != null && user!.fullName!.trim().isNotEmpty)
        ? user.fullName!
        : (user?.username ?? 'Usuario');
    final email = user?.email ?? '';

    return _sectionCard(
      icon: Icons.person_rounded,
      title: 'Cuenta',
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.userProfileRoute),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                ProfileAvatar(
                  photoUrl: user?.photoUrl,
                  nameSource: displayName,
                  radius: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (email.isNotEmpty)
                        Text(email,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        const Divider(height: 20),
        _navTile(
          icon: Icons.manage_accounts_rounded,
          title: 'Editar información personal',
          subtitle: 'Nombre, teléfono, ubicación y foto',
          onTap: () => context.go(AppRoutes.userProfileRoute),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🔐 Seguridad
  // ---------------------------------------------------------------------------

  Widget _buildSecurityCard() {
    return _sectionCard(
      icon: Icons.shield_rounded,
      title: 'Seguridad',
      children: [
        _navTile(
          icon: Icons.lock_reset_rounded,
          title: 'Cambiar contraseña',
          subtitle: 'Actualiza tu contraseña de acceso',
          onTap: () => _showComingSoon(
            'Cambiar contraseña',
            'Esta opción estará disponible cuando el backend exponga el endpoint correspondiente.',
          ),
        ),
        _navTile(
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
  // 🔔 Notificaciones
  // ---------------------------------------------------------------------------

  Widget _buildNotificationsCard() {
    return _sectionCard(
      icon: Icons.notifications_rounded,
      title: 'Notificaciones',
      children: [
        _switchTile(
          icon: Icons.notifications_active_rounded,
          title: 'Notificaciones push',
          subtitle: 'Recibe avisos de la aplicación',
          value: _pushNotifications,
          onChanged: (v) => setState(() => _pushNotifications = v),
        ),
        _switchTile(
          icon: Icons.hive_rounded,
          title: 'Alertas de la colmena',
          subtitle: 'Estado, tareas y recordatorios',
          value: _hiveAlerts,
          onChanged: (v) => setState(() => _hiveAlerts = v),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🌙 Apariencia
  // ---------------------------------------------------------------------------

  Widget _buildAppearanceCard() {
    return _sectionCard(
      icon: Icons.dark_mode_rounded,
      title: 'Apariencia',
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('Tema de la aplicación',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade600)),
        ),
        RadioGroup<String>(
          groupValue: _themeMode,
          onChanged: (v) {
            setState(() => _themeMode = v ?? 'Sistema');
            _showSnack('Se aplicará al habilitar el modo de tema.');
          },
          child: Column(
            children: ['Sistema', 'Claro', 'Oscuro']
                .map(
                  (mode) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: Colors.amber.shade700,
                    title: Text(mode,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey.shade800)),
                    value: mode,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🌎 Idioma
  // ---------------------------------------------------------------------------

  Widget _buildLanguageCard() {
    return _sectionCard(
      icon: Icons.language_rounded,
      title: 'Idioma',
      children: [
        _navTile(
          icon: Icons.translate_rounded,
          title: 'Idioma de la aplicación',
          subtitle: _language,
          onTap: _showLanguagePicker,
        ),
      ],
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        const langs = ['Español', 'English', 'Português'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Seleccionar idioma',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...langs.map((lang) {
                final available = lang == 'Español';
                return ListTile(
                  leading: Icon(
                    _language == lang
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: available ? Colors.amber.shade700 : Colors.grey.shade400,
                  ),
                  title: Text(lang, style: GoogleFonts.poppins()),
                  trailing: available
                      ? null
                      : Text('Próximamente',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade500)),
                  enabled: available,
                  onTap: available
                      ? () {
                          setState(() => _language = lang);
                          Navigator.pop(ctx);
                        }
                      : null,
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🐝 Preferencias de Softbee
  // ---------------------------------------------------------------------------

  Widget _buildSoftbeePreferencesCard() {
    return _sectionCard(
      icon: Icons.emoji_nature_rounded,
      title: 'Preferencias de Softbee',
      children: [
        _switchTile(
          icon: Icons.sync_rounded,
          title: 'Sincronización automática',
          subtitle: 'Sincroniza cambios al recuperar conexión',
          value: _autoSync,
          onChanged: (v) => setState(() => _autoSync = v),
        ),
        _navTile(
          icon: Icons.cloud_sync_rounded,
          title: 'Sincronizar datos ahora',
          subtitle: 'Envía las operaciones pendientes',
          trailing: _isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _isSyncing ? null : _syncNow,
        ),
        _navTile(
          icon: Icons.straighten_rounded,
          title: 'Unidades de medida',
          subtitle: 'Sistema métrico',
          onTap: () => _showComingSoon(
            'Unidades de medida',
            'La configuración de unidades estará disponible próximamente.',
          ),
        ),
      ],
    );
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(syncServiceProvider).syncPendingOperations();
      if (mounted) _showSnack('Sincronización completada.', success: true);
    } catch (_) {
      if (mounted) {
        _showSnack('No se pudo sincronizar. Revisa tu conexión.',
            success: false);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // ---------------------------------------------------------------------------
  // ℹ️ Información
  // ---------------------------------------------------------------------------

  Widget _buildInfoCard() {
    return _sectionCard(
      icon: Icons.info_rounded,
      title: 'Información',
      children: [
        _navTile(
          icon: Icons.verified_rounded,
          title: 'Versión de la aplicación',
          subtitle: _appVersion,
          onTap: _showAbout,
        ),
        _navTile(
          icon: Icons.description_rounded,
          title: 'Términos y condiciones',
          subtitle: 'Consulta los términos de uso',
          onTap: () => _showComingSoon(
            'Términos y condiciones',
            'El documento estará disponible próximamente.',
          ),
        ),
        _navTile(
          icon: Icons.privacy_tip_rounded,
          title: 'Política de privacidad',
          subtitle: 'Cómo tratamos tus datos',
          onTap: () => _showComingSoon(
            'Política de privacidad',
            'El documento estará disponible próximamente.',
          ),
        ),
        _navTile(
          icon: Icons.emoji_nature_rounded,
          title: 'Acerca de Softbee',
          subtitle: 'Detalles de la aplicación',
          onTap: _showAbout,
        ),
      ],
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Softbee',
      applicationVersion: _appVersion,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset('assets/images/Logo.png',
            width: 48, height: 48, errorBuilder: (_, _, _) {
          return Icon(Icons.emoji_nature_rounded,
              color: Colors.amber.shade700, size: 40);
        }),
      ),
      children: [
        Text(
          'Softbee es una plataforma para la gestión inteligente de apiarios y colmenas.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
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
            ],
          ),
          const Divider(height: 24),
          ...children,
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

  Widget _navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
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
            trailing ??
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: Colors.amber.shade700,
      secondary: _tileIcon(icon),
      title: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800)),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
      value: value,
      onChanged: onChanged,
    );
  }

  void _showSnack(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
      // El RouterNotifier redirige automáticamente a /login.
    }
  }
}
