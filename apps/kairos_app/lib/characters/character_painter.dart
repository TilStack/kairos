import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor, RadialGradient;

import '../app/palette.dart' show characterOutline;
import 'character_spec.dart';
import 'pose.dart';

/// Zone de dessin d'un personnage : 200 x 320 unites, pieds sur y = 312.
const characterBox = Size(200, 320);

const _outline = characterOutline;
const _ink = Color(0xFF3B2A20);

Color _darken(Color c, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

Offset _dir(double angle, {required bool left}) =>
    Offset((left ? -1 : 1) * math.sin(angle), math.cos(angle));

/// Dessine [spec] dans [size] (pieds au bas, centre horizontalement).
///
/// Dessin vectoriel pur : aucun fichier image, quelques ko de code, net a
/// toutes les tailles. [t] (secondes) anime la flamme de la mascotte.
void paintCharacter(
  Canvas canvas,
  Size size,
  CharacterSpec spec,
  Pose pose,
  Face face,
  double t,
) {
  final fit = math.min(size.width / characterBox.width, size.height / characterBox.height) * spec.scale;
  canvas.save();
  canvas.translate(size.width / 2, size.height);
  canvas.scale(fit);
  canvas.translate(-characterBox.width / 2, -characterBox.height);

  // Ombre au sol.
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(100, 312), width: 110, height: 14),
    Paint()..color = const Color(0x33000000),
  );

  canvas.save();
  canvas.translate(0, pose.bob);
  canvas.translate(100, 236);
  canvas.rotate(pose.lean);
  canvas.translate(-100, -236);

  _legs(canvas, spec, pose);
  _torso(canvas, spec);
  _arms(canvas, spec, pose, t);

  canvas.save();
  canvas.translate(100, 122);
  canvas.rotate(pose.headTilt);
  canvas.translate(-100, -122);
  if (spec.flameHead) {
    _flameHead(canvas, face, t);
  } else {
    _head(canvas, spec, face);
  }
  canvas.restore();

  canvas.restore();
  canvas.restore();
}

// ------------------------------------------------------------------ corps

void _limb(Canvas canvas, Offset a, Offset b, Offset c, Color color, double width) {
  final path = Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy)
    ..lineTo(c.dx, c.dy);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.drawPath(path, stroke..strokeWidth = width + 7..color = _outline);
  canvas.drawPath(path, stroke..strokeWidth = width..color = color);
}

void _legs(Canvas canvas, CharacterSpec spec, Pose pose) {
  for (final left in [true, false]) {
    final hip = Offset(left ? 86 : 114, 240);
    final angle = left ? pose.lLeg : pose.rLeg;
    final knee = hip + _dir(angle, left: left) * 36;
    final foot = knee + _dir(angle * 0.6, left: left) * 34;
    final legColor = spec.flameHead ? _darken(spec.outfit, 0.12) : _darken(spec.skin, 0.05);
    _limb(canvas, hip, knee, foot, legColor, 15);
    final shoe = Rect.fromCenter(center: foot + const Offset(0, 4), width: 28, height: 13);
    canvas.drawOval(shoe, Paint()..color = _outline);
    canvas.drawOval(shoe.deflate(2.5), Paint()..color = const Color(0xFF8A5A3C));
  }
}

void _torso(Canvas canvas, CharacterSpec spec) {
  final robe = Path()
    ..moveTo(70, 124)
    ..quadraticBezierTo(100, 112, 130, 124)
    ..lineTo(150, 258)
    ..quadraticBezierTo(100, 272, 50, 258)
    ..close();

  canvas.drawPath(robe, Paint()..color = spec.outfit);
  if (spec.stripes.isNotEmpty) {
    canvas.save();
    canvas.clipPath(robe);
    final w = 120 / spec.stripes.length;
    for (var i = 0; i < spec.stripes.length; i++) {
      canvas.drawRect(Rect.fromLTWH(40 + i * w, 100, w + 0.5, 190), Paint()..color = spec.stripes[i]);
    }
    canvas.restore();
  } else {
    // Pli central pour donner du volume.
    canvas.drawPath(
      Path()
        ..moveTo(100, 150)
        ..lineTo(104, 262)
        ..lineTo(96, 262)
        ..close(),
      Paint()..color = _darken(spec.outfit, 0.1),
    );
  }
  canvas.drawPath(
    robe,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..color = _outline,
  );
  final accent = spec.outfitAccent;
  if (accent != null) {
    final belt = RRect.fromRectAndRadius(const Rect.fromLTWH(70, 188, 62, 13), const Radius.circular(5));
    canvas.drawRRect(belt, Paint()..color = accent);
    canvas.drawRRect(belt, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = _outline);
    canvas.drawCircle(const Offset(100, 194.5), 5, Paint()..color = _darken(accent, 0.2));
  }
}

void _arms(Canvas canvas, CharacterSpec spec, Pose pose, double t) {
  Offset? rightHand;
  double rightForearm = 0;
  for (final left in [true, false]) {
    final shoulder = Offset(left ? 68 : 132, 138);
    final a1 = left ? pose.lArm : pose.rArm;
    final bend = left ? pose.lElbow : pose.rElbow;
    final elbow = shoulder + _dir(a1, left: left) * 40;
    final a2 = a1 + bend;
    final hand = elbow + _dir(a2, left: left) * 36;
    _limb(canvas, shoulder, elbow, hand, spec.outfit, 19);
    canvas.drawCircle(hand, 12, Paint()..color = _outline);
    canvas.drawCircle(hand, 9, Paint()..color = spec.skin);
    if (!left) {
      rightHand = hand;
      rightForearm = a2;
    }
  }
  if (rightHand != null) _prop(canvas, spec, rightHand, rightForearm, t);
}

void _prop(Canvas canvas, CharacterSpec spec, Offset hand, double forearm, double t) {
  switch (spec.prop) {
    case Prop.none:
      return;
    case Prop.lamp:
      _lamp(canvas, hand, t);
    case Prop.staff:
      final top = hand + const Offset(0, -118);
      final bottom = hand + const Offset(0, 76);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(top, bottom, p..strokeWidth = 11..color = _outline);
      canvas.drawLine(top, bottom, p..strokeWidth = 6..color = const Color(0xFF9B6B3F));
      final crook = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(top.dx + 20, top.dy - 10, top.dx + 14, top.dy + 12);
      canvas.drawPath(crook, p..strokeWidth = 11..color = _outline);
      canvas.drawPath(crook, p..strokeWidth = 6..color = const Color(0xFF9B6B3F));
    case Prop.scroll:
      canvas.save();
      canvas.translate(hand.dx, hand.dy);
      canvas.rotate(-0.5);
      final r = RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -34, 16, 52), const Radius.circular(6));
      canvas.drawRRect(r, Paint()..color = const Color(0xFFF4E4BA));
      canvas.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = _outline);
      for (final y in [-34.0, 18.0]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(0, y), width: 20, height: 9), Paint()..color = const Color(0xFFB8854F));
      }
      canvas.restore();
  }
}

/// Petite lampe a huile en argile, tenue par une anse : la flamme vacille.
void _lamp(Canvas canvas, Offset hand, double t) {
  final top = hand + const Offset(0, 8);
  final flicker = math.sin(t * 9) * 1.6;
  // Halo chaud.
  canvas.drawCircle(
    top + const Offset(2, 12),
    34,
    Paint()
      ..shader = const RadialGradient(colors: [Color(0x66FFD54A), Color(0x00FFD54A)])
          .createShader(Rect.fromCircle(center: top + const Offset(2, 12), radius: 34)),
  );
  // Anse.
  canvas.drawLine(hand, top + const Offset(0, 10), Paint()..strokeWidth = 3..color = _outline);
  // Corps de la lampe.
  final body = Path()
    ..moveTo(top.dx - 17, top.dy + 12)
    ..quadraticBezierTo(top.dx - 16, top.dy + 30, top.dx + 2, top.dy + 30)
    ..quadraticBezierTo(top.dx + 18, top.dy + 30, top.dx + 17, top.dy + 12)
    ..close();
  canvas.drawPath(body, Paint()..color = const Color(0xFFC9923F));
  canvas.drawPath(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeJoin = StrokeJoin.round..color = _outline);
  // Bec.
  final spout = Path()
    ..moveTo(top.dx + 14, top.dy + 14)
    ..lineTo(top.dx + 27, top.dy + 10)
    ..lineTo(top.dx + 17, top.dy + 20)
    ..close();
  canvas.drawPath(spout, Paint()..color = const Color(0xFFC9923F));
  canvas.drawPath(spout, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeJoin = StrokeJoin.round..color = _outline);
  // Flamme.
  final flame = Path()
    ..moveTo(top.dx + 24, top.dy + 9)
    ..quadraticBezierTo(top.dx + 19 + flicker, top.dy - 4, top.dx + 25 + flicker, top.dy - 12)
    ..quadraticBezierTo(top.dx + 33, top.dy - 2, top.dx + 28, top.dy + 9)
    ..close();
  canvas.drawPath(flame, Paint()..color = const Color(0xFFFF9A2E));
  canvas.drawPath(
    Path()
      ..moveTo(top.dx + 25, top.dy + 8)
      ..quadraticBezierTo(top.dx + 23, top.dy, top.dx + 26 + flicker * 0.5, top.dy - 4)
      ..quadraticBezierTo(top.dx + 29, top.dy + 2, top.dx + 27, top.dy + 8)
      ..close(),
    Paint()..color = const Color(0xFFFFE08A),
  );
}

// ------------------------------------------------------------------- tete

const _headC = Offset(100, 80);

void _head(Canvas canvas, CharacterSpec spec, Face face) {
  if (spec.headwear == Headwear.hood) {
    _hood(canvas, spec, face);
    return;
  }
  final skin = Paint()..color = spec.skin;
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..color = _outline;

  // Oreilles.
  for (final x in [61.0, 139.0]) {
    canvas.drawCircle(Offset(x, 84), 9, skin);
    canvas.drawCircle(Offset(x, 84), 9, line..strokeWidth = 4);
  }

  // Barbe derriere le visage.
  if (spec.beard != null) {
    final beard = Path()
      ..moveTo(62, 88)
      ..quadraticBezierTo(60, 142, 100, 152)
      ..quadraticBezierTo(140, 142, 138, 88)
      ..quadraticBezierTo(100, 112, 62, 88)
      ..close();
    canvas.drawPath(beard, Paint()..color = spec.beard!);
    canvas.drawPath(beard, line..strokeWidth = 4);
  }

  canvas.drawCircle(_headC, 40, skin);
  canvas.drawCircle(_headC, 40, line..strokeWidth = 5);

  _hairAndHeadwear(canvas, spec);
  _face(canvas, face, spec.skin, glowing: spec.glowingEyes);
  if (spec.glasses) _glasses(canvas);
}

void _hairAndHeadwear(Canvas canvas, CharacterSpec spec) {
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeJoin = StrokeJoin.round
    ..color = _outline;
  if (spec.hair != null && spec.headwear != Headwear.nemes) {
    final hair = Path()
      ..moveTo(60, 78)
      ..quadraticBezierTo(62, 36, 100, 38)
      ..quadraticBezierTo(138, 36, 140, 78)
      ..quadraticBezierTo(120, 56, 100, 58)
      ..quadraticBezierTo(80, 56, 60, 78)
      ..close();
    canvas.drawPath(hair, Paint()..color = spec.hair!);
    canvas.drawPath(hair, line);
  }
  switch (spec.headwear) {
    case Headwear.none:
    case Headwear.hood:
      break;
    case Headwear.headband:
      final band = RRect.fromRectAndRadius(const Rect.fromLTWH(61, 52, 78, 12), const Radius.circular(6));
      canvas.drawRRect(band, Paint()..color = spec.headwearColor);
      canvas.drawRRect(band, line);
    case Headwear.turban:
      for (var i = 0; i < 3; i++) {
        final r = Rect.fromCenter(center: Offset(100, 50 - i * 6.0), width: 92 - i * 14, height: 30);
        canvas.drawOval(r, Paint()..color = i.isEven ? spec.headwearColor : _darken(spec.headwearColor, 0.08));
        canvas.drawOval(r, line);
      }
    case Headwear.nemes:
      final cloth = Path()
        ..moveTo(60, 70)
        ..quadraticBezierTo(60, 30, 100, 30)
        ..quadraticBezierTo(140, 30, 140, 70)
        ..lineTo(150, 128)
        ..lineTo(130, 124)
        ..lineTo(130, 74)
        ..quadraticBezierTo(100, 54, 70, 74)
        ..lineTo(70, 124)
        ..lineTo(50, 128)
        ..close();
      canvas.drawPath(cloth, Paint()..color = const Color(0xFFE8B930));
      canvas.save();
      canvas.clipPath(cloth);
      for (var y = 34.0; y < 130; y += 14) {
        canvas.drawRect(Rect.fromLTWH(40, y, 120, 6), Paint()..color = const Color(0xFF2E6FBF));
      }
      canvas.restore();
      canvas.drawPath(cloth, line);
      // Uraeus / diademe.
      canvas.drawCircle(const Offset(100, 38), 6, Paint()..color = const Color(0xFFD64545));
      canvas.drawCircle(const Offset(100, 38), 6, line);
  }
}

void _hood(Canvas canvas, CharacterSpec spec, Face face) {
  final cloak = Path()
    ..moveTo(54, 126)
    ..quadraticBezierTo(48, 30, 100, 26)
    ..quadraticBezierTo(152, 30, 146, 126)
    ..quadraticBezierTo(100, 108, 54, 126)
    ..close();
  canvas.drawPath(cloak, Paint()..color = spec.outfit);
  canvas.drawPath(
    cloak,
    Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeJoin = StrokeJoin.round..color = _outline,
  );
  final void_ = Path()
    ..moveTo(70, 84)
    ..quadraticBezierTo(70, 46, 100, 46)
    ..quadraticBezierTo(130, 46, 130, 84)
    ..quadraticBezierTo(100, 112, 70, 84)
    ..close();
  canvas.drawPath(void_, Paint()..color = const Color(0xFF120D1E));
  final eye = Paint()..color = const Color(0xFFB6FF4D);
  final open = (face.eyeOpen * 7).clamp(1.5, 9.0);
  for (final x in [88.0, 112.0]) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, 78), width: 11, height: open), eye);
  }
  // Sourire en coin : la voix trompeuse est aimable... d'apparence.
  final smile = Path()
    ..moveTo(88, 96)
    ..quadraticBezierTo(100, 100 + 4 * face.mouthSmile, 112, 94);
  canvas.drawPath(
    smile,
    Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round..color = const Color(0xFFB6FF4D),
  );
}

void _face(Canvas canvas, Face face, Color skin, {required bool glowing}) {
  final eyeY = 80.0;
  for (final x in [85.0, 115.0]) {
    final h = 17 * face.eyeOpen.clamp(0.05, 1.3);
    final eye = Rect.fromCenter(center: Offset(x, eyeY), width: 15, height: h);
    canvas.drawOval(eye, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawOval(eye, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = _outline);
    if (face.eyeOpen > 0.2) {
      canvas.drawCircle(Offset(x + face.pupilX * 3, eyeY + 1), 4.4, Paint()..color = _ink);
      canvas.drawCircle(Offset(x + face.pupilX * 3 + 1.4, eyeY - 1), 1.4, Paint()..color = const Color(0xFFFFFFFF));
    }
    // Sourcils.
    // Le bout interieur monte quand l'humeur est inquiete (browTilt < 0).
    final sign = x < 100 ? 1.0 : -1.0;
    canvas.drawLine(
      Offset(x - 8, 64 + face.browTilt * 3 * sign),
      Offset(x + 8, 64 - face.browTilt * 3 * sign),
      Paint()..strokeWidth = 3.2..strokeCap = StrokeCap.round..color = _ink,
    );
  }
  // Joues.
  final blush = Paint()..color = const Color(0x33E0457B);
  canvas.drawCircle(const Offset(74, 98), 7, blush);
  canvas.drawCircle(const Offset(126, 98), 7, blush);
  _mouth(canvas, face, const Offset(100, 104), _ink);
}

/// Lunettes rondes a fine monture.
void _glasses(Canvas canvas) {
  final frame = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFF2B2230);
  for (final x in [85.0, 115.0]) {
    canvas.drawCircle(Offset(x, 80), 13.5, Paint()..color = const Color(0x1AFFFFFF));
    canvas.drawCircle(Offset(x, 80), 13.5, frame);
  }
  canvas.drawLine(const Offset(98.5, 79), const Offset(101.5, 79), frame);
  canvas.drawLine(const Offset(71.5, 79), const Offset(62, 77), frame);
  canvas.drawLine(const Offset(128.5, 79), const Offset(138, 77), frame);
}

void _mouth(Canvas canvas, Face face, Offset c, Color ink) {
  final width = 22.0;
  final curve = 12 * face.mouthSmile;
  if (face.mouthOpen > 0.2) {
    final h = 4 + face.mouthOpen * 12;
    final m = Path()
      ..moveTo(c.dx - width / 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + curve + h, c.dx + width / 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + (curve * 0.2) - 1, c.dx - width / 2, c.dy)
      ..close();
    canvas.drawPath(m, Paint()..color = const Color(0xFF7A1F2B));
    canvas.drawPath(m, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeJoin = StrokeJoin.round..color = ink);
  } else {
    final m = Path()
      ..moveTo(c.dx - width / 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + curve, c.dx + width / 2, c.dy);
    canvas.drawPath(m, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = ink);
  }
}

// ---------------------------------------------------------- tete de feu

/// Tete de la mascotte : une flamme vivante (Actes 2:3, Psaume 119:105).
void _flameHead(Canvas canvas, Face face, double t) {
  const base = Offset(100, 88);

  // Halo.
  canvas.drawCircle(
    base + const Offset(0, -14),
    74,
    Paint()
      ..shader = const RadialGradient(colors: [Color(0x55FFD54A), Color(0x00FFD54A)])
          .createShader(Rect.fromCircle(center: base + const Offset(0, -14), radius: 74)),
  );

  Path tongue(double cx, double apexY, double halfWidth, double sway) {
    return Path()
      ..moveTo(cx - halfWidth, base.dy + 4)
      ..cubicTo(cx - halfWidth - 6, base.dy - 36, cx + sway - 8, apexY + 40, cx + sway, apexY)
      ..cubicTo(cx + sway + 8, apexY + 40, cx + halfWidth + 6, base.dy - 36, cx + halfWidth, base.dy + 4)
      ..close();
  }

  double flick(int i, double amp) => math.sin(t * 8 + i * 1.9) * amp;

  // Chevelure de flammes : cinq langues qui ondulent, de la plus basse a la
  // plus haute, puis un coeur orange plus petit par-dessus.
  final outer = <Path>[
    tongue(58, 34 + flick(0, 6), 17, flick(1, 5) - 10),
    tongue(78, 2 + flick(2, 7), 21, flick(3, 5) - 5),
    tongue(100, -22 + flick(4, 8), 27, flick(5, 6)),
    tongue(122, 2 + flick(6, 7), 21, flick(7, 5) + 5),
    tongue(142, 34 + flick(8, 6), 17, flick(9, 5) + 10),
  ];
  for (final p in outer) {
    canvas.drawPath(p, Paint()..color = const Color(0xFFE8452E));
    canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..strokeJoin = StrokeJoin.round..color = _outline);
  }
  for (final p in [
    tongue(100, -4 + flick(10, 6), 20, flick(11, 4)),
    tongue(80, 22 + flick(12, 5), 13, flick(13, 3) - 3),
    tongue(120, 22 + flick(14, 5), 13, flick(15, 3) + 3),
  ]) {
    canvas.drawPath(p, Paint()..color = const Color(0xFFFF9A2E));
  }
  canvas.drawPath(tongue(100, 16 + flick(16, 5), 11, flick(17, 3)), Paint()..color = const Color(0xFFFFD54A));
  // Visage : disque chaud, comme le coeur de la flamme.
  canvas.drawCircle(
    base,
    40,
    Paint()
      ..shader = const RadialGradient(colors: [Color(0xFFFFF3B0), Color(0xFFFFC93C)])
          .createShader(Rect.fromCircle(center: base, radius: 40)),
  );
  canvas.drawCircle(base, 40, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = _outline);

  _face(canvas, face, const Color(0xFFFFC93C), glowing: false);

  // Etincelles qui montent.
  for (var i = 0; i < 6; i++) {
    final life = ((t * 0.9 + i / 6) % 1.0);
    final x = 100 + math.sin(i * 2.4 + t) * 34;
    final y = 30 - life * 60;
    canvas.drawCircle(
      Offset(x, y),
      3.2 * (1 - life) + 0.8,
      Paint()..color = Color.fromRGBO(255, 214, 90, 1 - life),
    );
  }
}
