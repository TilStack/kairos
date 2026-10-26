import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

/// Attitude du corps. Les angles sont en radians, mesures depuis la verticale
/// vers le bas : 0 = bras pendant, pi = bras leve. Un angle positif ecarte le
/// membre vers l'exterieur du corps.
class Pose {
  const Pose({
    this.lean = 0,
    this.headTilt = 0,
    this.bob = 0,
    this.lArm = 0.18,
    this.lElbow = 0.1,
    this.rArm = 0.18,
    this.rElbow = 0.1,
    this.lLeg = 0.05,
    this.rLeg = 0.05,
  });

  final double lean;
  final double headTilt;

  /// Decalage vertical du corps (respiration, saut), en unites de dessin.
  final double bob;
  final double lArm;
  final double lElbow;
  final double rArm;
  final double rElbow;
  final double lLeg;
  final double rLeg;

  static Pose lerp(Pose a, Pose b, double t) => Pose(
        lean: lerpDouble(a.lean, b.lean, t)!,
        headTilt: lerpDouble(a.headTilt, b.headTilt, t)!,
        bob: lerpDouble(a.bob, b.bob, t)!,
        lArm: lerpDouble(a.lArm, b.lArm, t)!,
        lElbow: lerpDouble(a.lElbow, b.lElbow, t)!,
        rArm: lerpDouble(a.rArm, b.rArm, t)!,
        rElbow: lerpDouble(a.rElbow, b.rElbow, t)!,
        lLeg: lerpDouble(a.lLeg, b.lLeg, t)!,
        rLeg: lerpDouble(a.rLeg, b.rLeg, t)!,
      );
}

/// Actions jouables par un personnage.
enum CharacterAction { idle, wave, cheer, think, sad, point, walk, talk }

/// Pose de l'action [action] a l'instant [t] (secondes). Fonction pure :
/// meme entree, meme pose, ce qui rend les animations testables.
Pose poseFor(CharacterAction action, double t) {
  final breathe = math.sin(t * 2.2) * 1.6;
  switch (action) {
    case CharacterAction.idle:
      return Pose(
        bob: breathe,
        lArm: 0.2 + math.sin(t * 2.2) * 0.03,
        rArm: 0.2 - math.sin(t * 2.2) * 0.03,
      );
    case CharacterAction.wave:
      return Pose(
        bob: breathe,
        headTilt: 0.05,
        rArm: 2.55,
        rElbow: math.sin(t * 9) * 0.55,
        lArm: 0.2,
      );
    case CharacterAction.cheer:
      final hop = -(math.sin(t * 7)).abs() * 10;
      return Pose(
        bob: hop,
        lArm: 2.7 + math.sin(t * 7) * 0.15,
        rArm: 2.7 - math.sin(t * 7) * 0.15,
        lElbow: 0.2,
        rElbow: 0.2,
        lLeg: 0.12,
        rLeg: 0.12,
      );
    case CharacterAction.think:
      return Pose(
        bob: breathe * 0.6,
        headTilt: 0.12,
        rArm: 0.7,
        rElbow: 2.3,
        lArm: 0.25,
      );
    case CharacterAction.sad:
      return Pose(
        lean: 0.05,
        headTilt: -0.14,
        bob: breathe * 0.4 + 2,
        lArm: 0.05,
        rArm: 0.05,
        lElbow: 0,
        rElbow: 0,
      );
    case CharacterAction.point:
      return Pose(bob: breathe, rArm: 1.45, rElbow: 0.05, lArm: 0.2, headTilt: 0.04);
    case CharacterAction.walk:
      final s = math.sin(t * 6);
      return Pose(
        bob: -s.abs() * 3,
        lLeg: s * 0.5,
        rLeg: -s * 0.5,
        lArm: 0.2 - s * 0.5,
        rArm: 0.2 + s * 0.5,
        lean: 0.03,
      );
    case CharacterAction.talk:
      return Pose(
        bob: breathe,
        rArm: 0.9 + math.sin(t * 3.5) * 0.25,
        rElbow: 0.9,
        lArm: 0.2,
        headTilt: math.sin(t * 2) * 0.04,
      );
  }
}

/// Humeur du visage.
enum Mood { happy, neutral, wow, sad, think, sly }

/// Parametres du visage deduits d'une humeur et du temps.
class Face {
  const Face({
    required this.eyeOpen,
    required this.mouthSmile,
    required this.mouthOpen,
    required this.browTilt,
    this.pupilX = 0,
  });

  /// 0 = ferme, 1 = grand ouvert.
  final double eyeOpen;

  /// -1 = triste, 0 = droit, 1 = grand sourire.
  final double mouthSmile;

  /// 0 = ferme, 1 = bouche ouverte.
  final double mouthOpen;

  /// Inclinaison des sourcils : > 0 = vers le haut (joie), < 0 = inquiet.
  final double browTilt;
  final double pupilX;
}

/// Visage a l'instant [t], avec clignement automatique et mouvement de
/// bouche quand [talking].
Face faceFor(Mood mood, double t, {bool talking = false}) {
  // Clignement bref toutes les ~3,4 s.
  final phase = t % 3.4;
  final blink = phase > 3.25 ? (1 - ((phase - 3.25) / 0.075 - 1).abs()).clamp(0.0, 1.0) : 0.0;
  final mouthMove = talking ? (math.sin(t * 14).abs()) : 0.0;
  switch (mood) {
    case Mood.happy:
      return Face(eyeOpen: 1 - blink, mouthSmile: 0.9, mouthOpen: 0.25 + mouthMove * 0.5, browTilt: 0.3);
    case Mood.neutral:
      return Face(eyeOpen: 1 - blink, mouthSmile: 0.15, mouthOpen: mouthMove * 0.6, browTilt: 0);
    case Mood.wow:
      return Face(eyeOpen: 1.25 - blink, mouthSmile: 0, mouthOpen: 0.8, browTilt: 0.6);
    case Mood.sad:
      return Face(eyeOpen: 0.7 - blink * 0.7, mouthSmile: -0.8, mouthOpen: 0, browTilt: -0.6);
    case Mood.think:
      return Face(eyeOpen: 0.9 - blink, mouthSmile: -0.1, mouthOpen: 0, browTilt: -0.2, pupilX: 0.5);
    case Mood.sly:
      return Face(eyeOpen: 0.55, mouthSmile: 0.6, mouthOpen: 0, browTilt: -0.7);
  }
}
