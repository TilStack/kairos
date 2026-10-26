import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart' show Curves;

import '../characters/cast.dart';
import '../characters/character_animator.dart';
import '../characters/character_painter.dart';
import '../characters/character_spec.dart';
import '../characters/pose.dart';

/// Un personnage dessine en code, utilisable comme composant Flame.
/// Il partage l'animateur et le dessin du widget Flutter.
class CharacterComponent extends PositionComponent {
  CharacterComponent({
    required this.spec,
    CharacterAction action = CharacterAction.idle,
    Mood mood = Mood.happy,
    super.position,
    super.size,
    super.anchor = Anchor.bottomCenter,
  }) : animator = CharacterAnimator(action: action, mood: mood);

  final CharacterSpec spec;
  final CharacterAnimator animator;

  @override
  void update(double dt) => animator.update(dt);

  @override
  void render(Canvas canvas) =>
      paintCharacter(canvas, Size(size.x, size.y), spec, animator.pose, animator.face, animator.time);
}

/// Cle d'or dessinee en code : anneau, tige et dents.
class KeyComponent extends PositionComponent {
  KeyComponent({super.position, super.size}) : super(anchor: Anchor.center);

  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    angle = math.sin(_t * 3) * 0.08;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Halo qui pulse.
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * (0.62 + 0.05 * math.sin(_t * 4)),
      Paint()..color = const Color(0x55FFD54A),
    );
    final gold = Paint()..color = const Color(0xFFF2B632);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF4A3322);

    final ring = Rect.fromCircle(center: Offset(w * 0.5, h * 0.24), radius: w * 0.2);
    final shaft = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.455, h * 0.4, w * 0.09, h * 0.5),
      Radius.circular(w * 0.03),
    );
    final teeth = Path()
      ..moveTo(w * 0.54, h * 0.72)
      ..lineTo(w * 0.72, h * 0.72)
      ..lineTo(w * 0.72, h * 0.8)
      ..lineTo(w * 0.54, h * 0.8)
      ..moveTo(w * 0.54, h * 0.84)
      ..lineTo(w * 0.66, h * 0.84)
      ..lineTo(w * 0.66, h * 0.9)
      ..lineTo(w * 0.54, h * 0.9)
      ..close();
    canvas.drawPath(teeth, gold);
    canvas.drawPath(teeth, edge);
    canvas.drawRRect(shaft, gold);
    canvas.drawRRect(shaft, edge);
    canvas.drawOval(ring, gold);
    canvas.drawOval(ring, edge);
    canvas.drawCircle(ring.center, w * 0.07, Paint()..color = const Color(0xFFFFF3B0));
    canvas.drawCircle(ring.center, w * 0.07, edge);
  }
}

/// Scene courte « Cle forgee » : la cle surgit avec un rebond, une gerbe
/// d'etincelles jaillit et Lumo se met a danser de joie.
///
/// Elle se met en pause d'elle-meme au bout de [duration] pour ne pas
/// consommer de batterie une fois la fete terminee.
class KeyForgeGame extends FlameGame {
  KeyForgeGame({this.duration = 3.2, int seed = 5}) : _rng = math.Random(seed);

  final double duration;
  final math.Random _rng;
  double _elapsed = 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    final center = Vector2(size.x / 2, size.y * 0.48);
    final keySize = math.min(size.x, size.y) * 0.42;

    add(
      CharacterComponent(
        spec: Cast.lumo,
        action: CharacterAction.cheer,
        position: Vector2(size.x * 0.2, size.y * 0.98),
        size: Vector2(size.y * 0.62, size.y * 0.98),
      ),
    );

    final key = KeyComponent(position: center, size: Vector2.all(keySize))..scale = Vector2.zero();
    add(key);
    key.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.8, curve: Curves.elasticOut),
      ),
    );

    add(
      ParticleSystemComponent(
        position: center,
        particle: Particle.generate(
          count: 42,
          lifespan: 1.6,
          generator: (i) {
            final angle = _rng.nextDouble() * math.pi * 2;
            final speed = 80 + _rng.nextDouble() * 170;
            const colors = [Color(0xFFFFD54A), Color(0xFFFF9A2E), Color(0xFFFFF3B0), Color(0xFFE8452E)];
            return AcceleratedParticle(
              speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
              acceleration: Vector2(0, 170),
              child: CircleParticle(
                radius: 2 + _rng.nextDouble() * 3.2,
                paint: Paint()..color = colors[i % colors.length],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration && !paused) pauseEngine();
  }
}
