import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'character_animator.dart';
import 'character_painter.dart';
import 'character_spec.dart';
import 'pose.dart';

/// Personnage anime, dessine en code. Leger : un seul `CustomPaint`, un seul
/// ticker, aucune image a charger (important sur appareils 2 Go).
class CharacterWidget extends StatefulWidget {
  const CharacterWidget({
    super.key,
    required this.spec,
    this.action = CharacterAction.idle,
    this.mood = Mood.happy,
    this.talking = false,
    this.height = 220,
    this.animated = true,
  });

  final CharacterSpec spec;
  final CharacterAction action;
  final Mood mood;
  final bool talking;
  final double height;

  /// Faux : image fixe (tests, economie de batterie), aucun ticker.
  final bool animated;

  @override
  State<CharacterWidget> createState() => _CharacterWidgetState();
}

class _CharacterWidgetState extends State<CharacterWidget> with SingleTickerProviderStateMixin {
  late final CharacterAnimator _animator;
  late final Ticker _ticker;
  final _frame = ValueNotifier<int>(0);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _animator = CharacterAnimator(action: widget.action, mood: widget.mood, talking: widget.talking);
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      _animator.update(dt.clamp(0.0, 0.1));
      _frame.value++;
    });
    if (widget.animated) {
      _ticker.start();
    } else {
      _animator.update(0.8); // pose fixe, vivante : bras leves, flamme a mi-course
    }
  }

  @override
  void didUpdateWidget(CharacterWidget old) {
    super.didUpdateWidget(old);
    _animator
      ..setAction(widget.action)
      ..mood = widget.mood
      ..talking = widget.talking;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * characterBox.width / characterBox.height;
    return Semantics(
      label: widget.spec.name,
      image: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size(width, widget.height),
            painter: _Painter(widget.spec, _animator, _frame),
          ),
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter(this.spec, this.animator, Listenable repaint) : super(repaint: repaint);

  final CharacterSpec spec;
  final CharacterAnimator animator;

  @override
  void paint(Canvas canvas, Size size) =>
      paintCharacter(canvas, size, spec, animator.pose, animator.face, animator.time);

  @override
  bool shouldRepaint(_Painter old) => old.spec != spec;
}
