import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Decor d'aventure en couches (ciel, pyramides, fleuve, dunes, rochers,
/// palmiers), dessine en code. Les nuages derivent et les palmes ondulent.
class AdventureBackdrop extends StatefulWidget {
  const AdventureBackdrop({super.key, this.animated = true});

  /// Faux dans les captures et pour economiser la batterie.
  final bool animated;

  @override
  State<AdventureBackdrop> createState() => _AdventureBackdropState();
}

class _AdventureBackdropState extends State<AdventureBackdrop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6);
    if (widget.animated) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(painter: _BackdropPainter(_time), size: Size.infinite),
      );
}

const _outline = Color(0xFF4A3322);

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.time) : super(repaint: time);

  final ValueNotifier<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = time.value;
    final horizon = h * 0.46;

    // Ciel.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6EBBE0), Color(0xFFBFE3EE), Color(0xFFFBE1B0), Color(0xFFF6B77A)],
          stops: [0, 0.3, 0.6, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon + 40)),
    );

    // Soleil et halo.
    final sun = Offset(w * 0.78, h * 0.2);
    canvas.drawCircle(
      sun,
      w * 0.34,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x99FFF2B8), Color(0x00FFF2B8)])
            .createShader(Rect.fromCircle(center: sun, radius: w * 0.34)),
    );
    canvas.drawCircle(sun, w * 0.075, Paint()..color = const Color(0xFFFFF0A8));

    // Nuages qui derivent.
    for (var i = 0; i < 5; i++) {
      final speed = 6.0 + i * 2.5;
      final x = ((i * 0.27 * w) + t * speed) % (w + 220) - 110;
      _cloud(canvas, Offset(x, h * (0.08 + (i % 3) * 0.07)), 0.7 + (i % 2) * 0.35);
    }

    // Pyramides lointaines et collines.
    _pyramid(canvas, Offset(w * 0.2, horizon + 6), w * 0.22, const Color(0xFFD9A37E));
    _pyramid(canvas, Offset(w * 0.4, horizon + 8), w * 0.14, const Color(0xFFCB9570));
    _pyramid(canvas, Offset(w * 0.07, horizon + 10), w * 0.12, const Color(0xFFCB9570));
    canvas.drawPath(
      _hills(w, horizon, h * 0.035, 2.3, 0.4),
      Paint()..color = const Color(0xFFE2B98B),
    );

    // Fleuve (le Nil) qui serpente vers l'avant.
    final river = Path()
      ..moveTo(w * 0.46, horizon + 10)
      ..cubicTo(w * 0.62, h * 0.55, w * 0.28, h * 0.63, w * 0.52, h * 0.74)
      ..cubicTo(w * 0.7, h * 0.82, w * 0.4, h * 0.9, w * 0.5, h)
      ..lineTo(w * 0.9, h)
      ..cubicTo(w * 0.9, h * 0.9, w * 0.96, h * 0.8, w * 0.74, h * 0.72)
      ..cubicTo(w * 0.54, h * 0.62, w * 0.78, h * 0.55, w * 0.54, horizon + 10)
      ..close();

    // Dunes du milieu, puis fleuve par-dessus pour qu'il serpente entre elles.
    canvas.drawPath(_hills(w, h * 0.55, h * 0.04, 1.7, 1.6, bottom: h), Paint()..color = const Color(0xFFEBC48A));
    canvas.drawPath(
      river,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9ADAE6), Color(0xFF5DB6D2)],
        ).createShader(Rect.fromLTWH(0, horizon, w, h - horizon)),
    );
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x66FFFFFF),
    );
    canvas.drawPath(_hills(w, h * 0.7, h * 0.03, 1.3, 3.1, bottom: h), Paint()..color = const Color(0xFFDDA766));

    // Rochers empiles aux deux bords, comme des murs de pierre moussus.
    _stoneStack(canvas, Offset(-4, h), w * 0.34, h * 0.34, left: true);
    _stoneStack(canvas, Offset(w + 4, h), w * 0.3, h * 0.3, left: false);

    // Palmiers en premier plan.
    _palm(canvas, Offset(w * 0.1, h * 0.7), h * 0.26, t, 1);
    _palm(canvas, Offset(w * 0.93, h * 0.68), h * 0.22, t, -1);
  }

  void _cloud(Canvas canvas, Offset c, double s) {
    final p = Paint()..color = const Color(0xE6FFFFFF);
    for (final (dx, dy, r) in [(-26.0, 4.0, 16.0), (-6.0, -6.0, 22.0), (20.0, 2.0, 18.0), (38.0, 8.0, 12.0)]) {
      canvas.drawCircle(c + Offset(dx * s, dy * s), r * s, p);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(6 * s, 12 * s), width: 100 * s, height: 16 * s), Radius.circular(8 * s)),
      p,
    );
  }

  void _pyramid(Canvas canvas, Offset base, double width, Color color) {
    final h = width * 0.62;
    final body = Path()
      ..moveTo(base.dx - width / 2, base.dy)
      ..lineTo(base.dx, base.dy - h)
      ..lineTo(base.dx + width / 2, base.dy)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    // Face dans l'ombre.
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy - h)
        ..lineTo(base.dx + width / 2, base.dy)
        ..lineTo(base.dx + width * 0.05, base.dy)
        ..close(),
      Paint()..color = const Color(0x22502A10),
    );
  }

  Path _hills(double w, double y, double amp, double freq, double phase, {double? bottom}) {
    final p = Path()..moveTo(0, bottom ?? y + 40);
    p.lineTo(0, y);
    for (var x = 0.0; x <= w; x += 8) {
      p.lineTo(x, y + math.sin(x / w * math.pi * freq + phase) * amp);
    }
    p.lineTo(w, bottom ?? y + 40);
    p.close();
    return p;
  }

  void _stoneStack(Canvas canvas, Offset anchor, double width, double height, {required bool left}) {
    final rng = math.Random(left ? 3 : 8);
    final dir = left ? 1.0 : -1.0;
    var y = anchor.dy;
    var row = 0;
    while (y > anchor.dy - height) {
      final bh = height / 5;
      final rowWidth = width * (1 - row * 0.17);
      var x = anchor.dx;
      final rowEnd = anchor.dx + dir * rowWidth;
      while ((rowEnd - x) * dir > 4) {
        final bw = math.min((rowEnd - x).abs(), 36 + rng.nextDouble() * 34);
        final rect = left
            ? Rect.fromLTWH(x, y - bh, bw, bh)
            : Rect.fromLTWH(x - bw, y - bh, bw, bh);
        final tone = [const Color(0xFFD9B98A), const Color(0xFFC9A574), const Color(0xFFE2C79B)][rng.nextInt(3)];
        final rr = RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(7));
        canvas.drawRRect(rr, Paint()..color = tone);
        canvas.drawRRect(rr, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = _outline.withValues(alpha: 0.55));
        // Mousse sur le dessus.
        if (rng.nextDouble() < 0.5) {
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(rr.left + 3, rr.top - 1, rr.width - 6, 8),
              topLeft: const Radius.circular(6),
              topRight: const Radius.circular(6),
              bottomLeft: const Radius.circular(3),
              bottomRight: const Radius.circular(3),
            ),
            Paint()..color = const Color(0xFF8FA23A),
          );
        }
        x += dir * bw;
      }
      y -= bh;
      row++;
    }
  }

  void _palm(Canvas canvas, Offset base, double height, double t, double side) {
    final sway = math.sin(t * 1.3 + side) * 0.05;
    final top = base + Offset(side * height * 0.12 + sway * height * 0.4, -height);
    final trunk = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + side * height * 0.18, base.dy - height * 0.5, top.dx, top.dy);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(trunk, p..strokeWidth = 16..color = _outline);
    canvas.drawPath(trunk, p..strokeWidth = 11..color = const Color(0xFF9B6B3F));
    // Palmes.
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (i - 3) * 0.55 + sway + math.sin(t * 1.8 + i) * 0.04;
      final len = height * 0.42;
      final tip = top + Offset(math.cos(a) * len, math.sin(a) * len + len * 0.35);
      final ctrl = top + Offset(math.cos(a) * len * 0.5, math.sin(a) * len * 0.5 - len * 0.2);
      final leaf = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy - 6, tip.dx, tip.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy + 8, top.dx, top.dy);
      canvas.drawPath(leaf, Paint()..color = i.isEven ? const Color(0xFF4C9A3E) : const Color(0xFF3B7F34));
      canvas.drawPath(leaf, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = _outline.withValues(alpha: 0.7));
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => false;
}
