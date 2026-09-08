import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Avatar reutilizable del usuario.
///
/// Soporta tres orígenes de imagen de forma transparente (web y móvil):
///  - `data:` (base64) → se decodifica y muestra con [MemoryImage].
///  - URL `http(s)` → [NetworkImage].
///  - `null` / vacío → muestra las iniciales derivadas de [nameSource].
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String nameSource;
  final double radius;
  final double? fontSize;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.nameSource,
    this.radius = 28,
    this.fontSize,
  });

  static ImageProvider? providerFor(String? photoUrl) {
    if (photoUrl == null || photoUrl.trim().isEmpty) return null;
    if (photoUrl.startsWith('data:')) {
      try {
        final base64Part = photoUrl.contains(',')
            ? photoUrl.split(',').last
            : photoUrl;
        final Uint8List bytes = base64Decode(base64Part);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }
    return null;
  }

  String get _initials {
    final source = nameSource.trim();
    if (source.isEmpty) return 'U';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final provider = providerFor(photoUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.amber.shade100,
      backgroundImage: provider,
      child: provider == null
          ? Text(
              _initials,
              style: GoogleFonts.poppins(
                fontSize: fontSize ?? radius * 0.7,
                fontWeight: FontWeight.w700,
                color: Colors.amber.shade800,
              ),
            )
          : null,
    );
  }
}
