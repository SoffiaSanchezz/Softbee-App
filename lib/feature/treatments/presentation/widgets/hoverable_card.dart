import 'package:flutter/material.dart';

/// Tarjeta con borde ámbar y animación de "hover".
///
/// Al pasar el puntero (escritorio/web) la tarjeta se eleva ligeramente y
/// realza su borde y sombra en tono ámbar. Provee el contenedor visual
/// (color, borde, radio, sombra y recorte) para que el contenido hijo se
/// enfoque únicamente en su distribución interna.
class HoverableCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  /// Color de acento para el tinte de la sombra al hacer hover.
  final Color accentColor;

  const HoverableCard({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.margin,
    this.accentColor = const Color(0xFFF59E0B), // amber 500
  });

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _hovering = false;

  void _setHover(bool value) {
    if (_hovering != value) setState(() => _hovering = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: widget.margin,
        transform: _hovering
            ? (Matrix4.identity()..translateByDouble(0.0, -4.0, 0.0, 1.0))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(
            color: _hovering ? Colors.amber.shade600 : Colors.amber.shade200,
            width: _hovering ? 1.6 : 1.2,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    );
  }
}
