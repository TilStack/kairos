import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Matiere des boutons : pierre claire, mousse, argile ou ardoise.
enum StoneStyle {
  sand(Color(0xFFF0D497), Color(0xFFD9B26B), Color(0xFFA8743F), Color(0xFF5B3A1A)),
  moss(Color(0xFFC9DE62), Color(0xFF9DB83A), Color(0xFF627B17), Color(0xFF34430B)),
  clay(Color(0xFFD9694F), Color(0xFFB6452F), Color(0xFF762818), Color(0xFFFFEBCB)),
  slate(Color(0xFFDDE2E8), Color(0xFFB5BDC8), Color(0xFF6F7B89), Color(0xFF3C4654));

  const StoneStyle(this.top, this.bottom, this.edge, this.text);
  final Color top;
  final Color bottom;
  final Color edge;
  final Color text;
}

const _depth = 6.0;

/// Bouton en pierre taillee, en relief : il s'enfonce quand on appuie.
class StoneButton extends StatefulWidget {
  const StoneButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.style = StoneStyle.sand,
    this.height = 66,
    this.fontSize = 24,
    this.leading,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final StoneStyle style;
  final double height;
  final double fontSize;
  final Widget? leading;

  @override
  State<StoneButton> createState() => _StoneButtonState();
}

class _StoneButtonState extends State<StoneButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final enabled = widget.onPressed != null;
    final dy = _down && enabled ? _depth - 2 : 0.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.subtitle == null ? widget.label : '${widget.label}, ${widget.subtitle}',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: () => setState(() => _down = false),
          onTap: widget.onPressed,
          child: SizedBox(
            height: widget.height + _depth,
            child: Stack(
              children: [
                // Epaisseur de la pierre.
                Positioned.fill(
                  top: _depth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: s.edge,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 70),
                  left: 0,
                  right: 0,
                  top: dy,
                  height: widget.height,
                  child: Opacity(
                    opacity: enabled ? 1 : 0.55,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [s.top, s.bottom],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: s.edge, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CustomPaint(
                          painter: _SpecklePainter(s),
                          child: Center(child: _content(s)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(StoneStyle s) {
    final label = _outlined(widget.label, s, widget.fontSize);
    final children = <Widget>[
      if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 10)],
      Flexible(child: label),
    ];
    final row = Row(mainAxisSize: MainAxisSize.min, children: children);
    if (widget.subtitle == null) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        Text(
          widget.subtitle!,
          style: TextStyle(color: s.text.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// Texte avec contour clair, lisible sur la pierre (style « gravure »).
Widget _outlined(String text, StoneStyle s, double size) {
  final light = s == StoneStyle.clay;
  final base = TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 1.5);
  return Stack(
    alignment: Alignment.center,
    children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: base.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeJoin = StrokeJoin.round
            ..color = light ? s.edge : const Color(0x99FFFFFF),
        ),
      ),
      Text(text, textAlign: TextAlign.center, style: base.copyWith(color: s.text)),
    ],
  );
}

/// Petit bouton carre (musique, reglages...) : un bloc de pierre avec icone.
class StoneIconButton extends StatelessWidget {
  const StoneIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.style = StoneStyle.slate,
    this.size = 62,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final StoneStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: StoneButton(
        label: '',
        subtitle: null,
        height: size - _depth,
        onPressed: onPressed,
        style: style,
        leading: Icon(icon, size: size * 0.46, color: style.text, semanticLabel: semanticLabel),
      ),
    );
  }
}

/// Petits eclats pour donner du grain a la pierre (deterministes).
class _SpecklePainter extends CustomPainter {
  _SpecklePainter(this.style);

  final StoneStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(style.index + 11);
    final dot = Paint()..color = style.edge.withValues(alpha: 0.16);
    final light = Paint()..color = const Color(0x33FFFFFF);
    for (var i = 0; i < 26; i++) {
      final c = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      canvas.drawCircle(c, 1 + rng.nextDouble() * 2.2, i.isEven ? dot : light);
    }
    // Reflet sur le haut.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, 5, size.width - 16, size.height * 0.16), const Radius.circular(8)),
      Paint()..color = const Color(0x40FFFFFF),
    );
  }

  @override
  bool shouldRepaint(_SpecklePainter old) => old.style != style;
}
