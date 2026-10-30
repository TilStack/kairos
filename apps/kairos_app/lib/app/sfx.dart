import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'music.dart';

/// Effets sonores du jeu.
enum Sfx {
  /// Clic sur un bouton, un choix, un mot.
  tap('tap.wav', 0.8),

  /// La Cle est forgee.
  success('success.wav', 0.7),

  /// Mauvaise reponse : douce, sans reproche.
  error('error.wav', 0.6);

  const Sfx(this.file, this.volume);
  final String file;
  final double volume;
}

/// Lecteur d'effets. Les tests le remplacent par un faux (aucun son).
abstract class SfxPlayer {
  void play(Sfx sfx);
}

class FlameSfxPlayer implements SfxPlayer {
  @override
  void play(Sfx sfx) => unawaited(_play(sfx));

  Future<void> _play(Sfx sfx) async {
    // Le son ne doit jamais gener le jeu : toute erreur audio est ignoree.
    try {
      await FlameAudio.play(sfx.file, volume: sfx.volume);
    } on Object {
      // Pas de peripherique audio ou fichier illisible.
    }
  }
}

final sfxPlayerProvider = Provider<SfxPlayer>((ref) => FlameSfxPlayer());

/// Effets sonores, coupes en meme temps que la musique (bouton son de l'ecran-titre).
class SoundEffects {
  SoundEffects(this._player, this._enabled);

  final SfxPlayer _player;
  final bool Function() _enabled;

  void play(Sfx sfx) {
    if (_enabled()) _player.play(sfx);
  }
}

final soundEffectsProvider = Provider<SoundEffects>(
  (ref) => SoundEffects(
    ref.watch(sfxPlayerProvider),
    () => ref.read(musicProvider).value ?? true,
  ),
);

/// Joue un effet depuis n'importe quel widget, sans le transformer en
/// ConsumerWidget. Hors `ProviderScope`, reste silencieux.
void playSfx(BuildContext context, [Sfx sfx = Sfx.tap]) {
  try {
    ProviderScope.containerOf(context, listen: false).read(soundEffectsProvider).play(sfx);
  } on Object {
    // Pas de scope (apercu isole) : pas de son.
  }
}
