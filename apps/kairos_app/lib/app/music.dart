import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Lecteur de musique de fond. Interface minimale : les tests la remplacent
/// par un faux (aucun son en test).
abstract class MusicPlayer {
  Future<void> start();
  Future<void> stop();
}

/// Lecture en boucle du theme, avec Flame Audio. Se met en pause toute seule
/// quand l'application passe en arriere-plan.
class FlameMusicPlayer implements MusicPlayer {
  static const _track = 'theme.wav';
  static const _volume = 0.4;
  var _initialized = false;

  @override
  Future<void> start() async {
    try {
      if (!_initialized) {
        FlameAudio.bgm.initialize();
        _initialized = true;
      }
      if (FlameAudio.bgm.isPlaying) return;
      await FlameAudio.bgm.play(_track, volume: _volume);
    } on Object {
      // Pas de peripherique audio ou fichier illisible : le jeu reste jouable.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await FlameAudio.bgm.stop();
    } on Object {
      // Rien a arreter.
    }
  }
}

final musicPlayerProvider = Provider<MusicPlayer>((ref) => FlameMusicPlayer());

const _musicSetting = 'music';

/// Musique activee ou coupee. Reglage conserve sur l'appareil ; active par
/// defaut. Un bouton visible permet toujours de la couper (eglise, bus...).
class MusicController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final saved = await ref.watch(repositoryProvider).getSetting(_musicSetting);
    final enabled = saved != 'off';
    final player = ref.read(musicPlayerProvider);
    if (enabled) {
      await player.start();
    }
    return enabled;
  }

  Future<void> toggle() async {
    final next = !(state.value ?? true);
    state = AsyncData(next);
    await ref.read(repositoryProvider).setSetting(_musicSetting, next ? 'on' : 'off');
    final player = ref.read(musicPlayerProvider);
    if (next) {
      await player.start();
    } else {
      await player.stop();
    }
  }
}

final musicProvider = AsyncNotifierProvider<MusicController, bool>(MusicController.new);
