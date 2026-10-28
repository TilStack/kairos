import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/palette.dart';
import 'backdrop.dart';

const _outline = Color(0xFF4A3322);

/// Decor d'une scene : le lieu vient du contenu de l'arc (`setting`).
/// Lieux inconnus : desert, pour ne jamais afficher un ecran vide.
class SceneBackdrop extends StatelessWidget {
  const SceneBackdrop({super.key, required this.setting, this.animated = true});

  final String setting;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return switch (setting) {
      'house' => const RepaintBoundary(child: CustomPaint(painter: _HousePainter(), size: Size.infinite)),
      'palace' => const RepaintBoundary(child: CustomPaint(painter: _PalacePainter(), size: Size.infinite)),
      'memory' => const RepaintBoundary(child: CustomPaint(painter: _MemoryPainter(), size: Size.infinite)),
      _ => AdventureBackdrop(animated: animated),
    };
  }
}

Paint _fill(Color c) => Paint()..color = c;
Paint _line(double w, Color c) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..color = c;

/// Interieur d'une maison : mur d'argile, sol de bois, fenetre ensoleillee,
/// lampe a huile et jarres.
class _HousePainter extends CustomPainter {
  const _HousePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floorY = h * 0.72;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, floorY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: houseWall,
        ).createShader(Rect.fromLTWH(0, 0, w, floorY)),
    );
    // Briques d'argile.
    final rng = math.Random(4);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * floorY),
        2 + rng.nextDouble() * 5,
        _fill(const Color(0x14704020)),
      );
    }

    // Fenetre et rayons de soleil.
    final win = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.26, h * 0.26), Radius.circular(w * 0.13));
    canvas.drawPath(
      Path()
        ..moveTo(win.left + 10, win.bottom - 10)
        ..lineTo(w * 0.62, floorY + 30)
        ..lineTo(w * 0.34, floorY + 30)
        ..lineTo(win.right - 10, win.bottom - 10)
        ..close(),
      _fill(const Color(0x33FFF4C2)),
    );
    canvas.drawRRect(win, _fill(const Color(0xFF9ED7EE)));
    canvas.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), _line(5, _outline));
    canvas.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), _line(5, _outline));
    canvas.drawRRect(win, _line(6, _outline));

    // Lampe a huile suspendue.
    final lampX = w * 0.72;
    canvas.drawLine(Offset(lampX, 0), Offset(lampX, h * 0.12), _line(3, _outline));
    final lamp = Path()
      ..moveTo(lampX - 18, h * 0.12)
      ..quadraticBezierTo(lampX, h * 0.17, lampX + 18, h * 0.12)
      ..close();
    canvas.drawPath(lamp, _fill(const Color(0xFFB87B3A)));
    canvas.drawPath(lamp, _line(3, _outline));
    canvas.drawCircle(Offset(lampX, h * 0.105), 8, _fill(const Color(0xFFFFC93C)));

    // Sol de bois.
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, w, h - floorY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB57C45), Color(0xFF8E5A2E)],
        ).createShader(Rect.fromLTWH(0, floorY, w, h - floorY)),
    );
    canvas.drawLine(Offset(0, floorY), Offset(w, floorY), _line(5, _outline));
    for (var i = 1; i < 5; i++) {
      final y = floorY + (h - floorY) * i / 5;
      canvas.drawLine(Offset(0, y), Offset(w, y), _line(2, const Color(0x55402010)));
    }

    // Jarres.
    _jar(canvas, Offset(w * 0.9, floorY + 6), h * 0.12);
    _jar(canvas, Offset(w * 0.8, floorY + 14), h * 0.08);
    _jar(canvas, Offset(w * 0.07, floorY + 10), h * 0.1);
  }

  void _jar(Canvas canvas, Offset base, double height) {
    final w = height * 0.8;
    final body = Path()
      ..moveTo(base.dx - w * 0.28, base.dy - height)
      ..quadraticBezierTo(base.dx - w * 0.62, base.dy - height * 0.4, base.dx - w * 0.3, base.dy)
      ..lineTo(base.dx + w * 0.3, base.dy)
      ..quadraticBezierTo(base.dx + w * 0.62, base.dy - height * 0.4, base.dx + w * 0.28, base.dy - height)
      ..close();
    canvas.drawPath(body, _fill(const Color(0xFFC9703F)));
    canvas.drawPath(body, _line(3, _outline));
    canvas.drawLine(Offset(base.dx - w * 0.4, base.dy - height * 0.6), Offset(base.dx + w * 0.4, base.dy - height * 0.6), _line(3, const Color(0xFF7A3A1C)));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(base.dx, base.dy - height), width: w * 0.62, height: height * 0.14),
      _fill(const Color(0xFF7A3A1C)),
    );
  }

  @override
  bool shouldRepaint(_HousePainter old) => false;
}

/// Salle du palais : mur bleu, bandeau d'or, colonnes, disque solaire et
/// sol en damier.
class _PalacePainter extends CustomPainter {
  const _PalacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floorY = h * 0.7;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, floorY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palaceWall,
        ).createShader(Rect.fromLTWH(0, 0, w, floorY)),
    );
    // Frise bleu lapis bordee d'or.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.05, w, h * 0.05), _fill(const Color(0xFF2E5FA8)));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.1, w, h * 0.012), _fill(const Color(0xFFE8B930)));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.05 - 3, w, 3), _fill(const Color(0xFFE8B930)));

    // Disque solaire central, ailes ouvertes.
    final sun = Offset(w / 2, h * 0.3);
    canvas.drawCircle(sun, w * 0.2, _fill(const Color(0x55F7DD86)));
    canvas.drawCircle(sun, w * 0.13, _fill(const Color(0xFF2E5FA8)));
    for (var i = 0; i < 14; i++) {
      final a = math.pi + i * math.pi / 13;
      canvas.drawLine(
        sun + Offset(math.cos(a), math.sin(a)) * (w * 0.11),
        sun + Offset(math.cos(a), math.sin(a)) * (w * 0.19),
        _line(3, const Color(0xFFE8B930)),
      );
    }
    canvas.drawCircle(sun, w * 0.1, _fill(const Color(0xFFE8B930)));
    canvas.drawCircle(sun, w * 0.1, _line(4, _outline));

    // Colonnes.
    _column(canvas, w * 0.1, floorY, h);
    _column(canvas, w * 0.9, floorY, h);

    // Sol en damier avec fuite.
    final rows = 6;
    for (var r = 0; r < rows; r++) {
      final y0 = floorY + (h - floorY) * r / rows;
      final y1 = floorY + (h - floorY) * (r + 1) / rows;
      final cols = 8;
      for (var c = 0; c < cols; c++) {
        canvas.drawRect(
          Rect.fromLTRB(w * c / cols, y0, w * (c + 1) / cols, y1),
          _fill((r + c).isEven ? const Color(0xFFEAD9AE) : const Color(0xFFC6B07E)),
        );
      }
    }
    canvas.drawLine(Offset(0, floorY), Offset(w, floorY), _line(5, _outline));
  }

  void _column(Canvas canvas, double cx, double floorY, double h) {
    final shaft = Rect.fromLTRB(cx - 26, h * 0.13, cx + 26, floorY);
    canvas.drawRect(shaft, _fill(const Color(0xFF3F70B8)));
    for (var i = -1; i <= 1; i++) {
      canvas.drawLine(Offset(cx + i * 14, shaft.top), Offset(cx + i * 14, shaft.bottom), _line(2, const Color(0x55FFFFFF)));
    }
    canvas.drawRect(shaft, _line(4, _outline));
    for (final r in [Rect.fromLTRB(cx - 36, h * 0.11, cx + 36, h * 0.145), Rect.fromLTRB(cx - 34, floorY - 18, cx + 34, floorY)]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), _fill(const Color(0xFFD9BD73)));
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), _line(4, _outline));
    }
    // Torche.
    final torch = Offset(cx, h * 0.2);
    canvas.drawCircle(torch, 12, _fill(const Color(0x66FFB347)));
    canvas.drawCircle(torch, 6, _fill(const Color(0xFFFF9A2E)));
    canvas.drawCircle(torch + const Offset(0, -2), 3, _fill(const Color(0xFFFFE08A)));
  }

  @override
  bool shouldRepaint(_PalacePainter old) => false;
}

/// Souvenir : tons sepia, bords assombris, poussieres de lumiere.
class _MemoryPainter extends CustomPainter {
  const _MemoryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [memoryTone[0], memoryTone[1], Color(0xFF9C7A4C)],
        ).createShader(Offset.zero & size),
    );
    final rng = math.Random(12);
    for (var i = 0; i < 34; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.7),
        1.5 + rng.nextDouble() * 4,
        _fill(Color.fromRGBO(255, 244, 214, 0.25 + rng.nextDouble() * 0.35)),
      );
    }
    // Colline lointaine et tente : silhouette adoucie.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.62)
        ..quadraticBezierTo(w * 0.3, h * 0.5, w * 0.6, h * 0.6)
        ..quadraticBezierTo(w * 0.85, h * 0.66, w, h * 0.58)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      _fill(const Color(0x33603818)),
    );
    final tent = Path()
      ..moveTo(w * 0.7, h * 0.64)
      ..lineTo(w * 0.8, h * 0.5)
      ..lineTo(w * 0.9, h * 0.64)
      ..close();
    canvas.drawPath(tent, _fill(const Color(0x55402010)));
    // Vignette.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.95,
          colors: [Color(0x00000000), Color(0x66301808)],
          stops: [0.55, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_MemoryPainter old) => false;
}
