import 'package:flutter/animation.dart';

import 'pose.dart';

/// Etat d'animation d'un personnage, independant de Flutter et de Flame :
/// le widget et le composant de jeu s'en servent a l'identique.
class CharacterAnimator {
  CharacterAnimator({
    CharacterAction action = CharacterAction.idle,
    this.mood = Mood.happy,
    this.talking = false,
    this.blendSeconds = 0.25,
  })  : _action = action,
        _pose = poseFor(action, 0);

  Mood mood;
  bool talking;
  final double blendSeconds;

  CharacterAction _action;
  Pose _pose;
  Pose _from = const Pose();
  double _t = 0;
  double _blend = 1;

  CharacterAction get action => _action;
  Pose get pose => _pose;
  double get time => _t;
  Face get face => faceFor(mood, _t, talking: talking);

  /// Change d'action : fondu depuis la pose actuelle (pas de saut brusque).
  void setAction(CharacterAction next) {
    if (next == _action) return;
    _from = _pose;
    _action = next;
    _blend = 0;
  }

  /// Avance de [dt] secondes.
  void update(double dt) {
    _t += dt;
    final target = poseFor(_action, _t);
    if (_blend < 1) {
      _blend = (_blend + dt / blendSeconds).clamp(0.0, 1.0);
      _pose = Pose.lerp(_from, target, Curves.easeInOut.transform(_blend));
    } else {
      _pose = target;
    }
  }
}
