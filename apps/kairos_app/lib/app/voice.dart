import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'music.dart';
import 'providers.dart';

/// Timbre et vitesse d'une voix. `pitch` : 0,5 (grave) a 2 (aigu) ;
/// `rate` : 0 (lent) a 1 (rapide), 0,5 etant le rythme normal d'Android.
class VoiceProfile {
  const VoiceProfile(this.pitch, this.rate);
  final double pitch;
  final double rate;
}

/// Voix de chaque personnage : meme moteur, reglages differents, pour qu'on
/// distingue les acteurs a l'oreille.
const voiceProfiles = {
  'lumo': VoiceProfile(1.1, 0.46),
  'joseph': VoiceProfile(1.0, 0.47),
  'jacob': VoiceProfile(0.7, 0.4),
  'potiphar': VoiceProfile(0.75, 0.44),
  'pharaon': VoiceProfile(0.6, 0.4),
  'frere': VoiceProfile(0.85, 0.5),
  'benjamin': VoiceProfile(1.4, 0.5),
  'intendant': VoiceProfile(0.8, 0.45),
  'murmure': VoiceProfile(0.55, 0.36),
};

const defaultVoice = VoiceProfile(1.0, 0.46);

VoiceProfile voiceFor(String? characterId) => voiceProfiles[characterId] ?? defaultVoice;

/// Moteur de synthese vocale. Les tests le remplacent par un faux.
abstract class SpeechPlayer {
  /// Rend la main quand la phrase est finie (ou interrompue).
  Future<void> speak(String text, VoiceProfile profile);
  Future<void> stop();
}

/// Voix du telephone (moteur de synthese d'Android), hors ligne.
class FlutterTtsPlayer implements SpeechPlayer {
  final _tts = FlutterTts();
  Future<void>? _ready;

  Future<void> _init() async {
    await _tts.setLanguage('fr-FR');
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  Future<void> speak(String text, VoiceProfile profile) async {
    try {
      await (_ready ??= _init());
      await _tts.setPitch(profile.pitch);
      await _tts.setSpeechRate(profile.rate);
      await _tts.speak(text);
    } on Object {
      // Pas de moteur vocal ou langue absente : le jeu reste lisible.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object {
      // Rien a arreter.
    }
  }
}

final speechPlayerProvider = Provider<SpeechPlayer>((ref) => FlutterTtsPlayer());

/// Texte prepare pour la voix : sans guillemets ni retours a la ligne.
String speakable(String text) =>
    text.replaceAll(RegExp(r'[«»]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// Lecture a voix haute : une seule voix a la fois, la musique baisse pendant
/// qu'elle parle. `speaking` donne le texte en cours de lecture (ou null).
class VoiceService {
  VoiceService(this._speech, this._music);

  final SpeechPlayer _speech;
  final MusicPlayer _music;
  final speaking = ValueNotifier<String?>(null);
  int _token = 0;

  Future<void> speak(String text, {String? characterId}) async {
    final mine = ++_token;
    await _speech.stop();
    speaking.value = text;
    await _music.duck(true);
    await _speech.speak(speakable(text), voiceFor(characterId));
    // Une lecture plus recente a pris la suite : elle gere l'etat elle-meme.
    if (mine == _token) {
      speaking.value = null;
      await _music.duck(false);
    }
  }

  Future<void> stop() async {
    _token++;
    speaking.value = null;
    await _speech.stop();
    await _music.duck(false);
  }

  /// N'arrete que si [text] est encore lu : un ecran qui se ferme ne coupe
  /// pas la phrase du suivant.
  Future<void> stopIfSpeaking(String text) async {
    if (speaking.value == text) await stop();
  }
}

final voiceProvider = Provider<VoiceService>(
  (ref) => VoiceService(ref.watch(speechPlayerProvider), ref.watch(musicPlayerProvider)),
);

const _autoSetting = 'voice_auto';

/// Lecture automatique des repliques. Coupee par defaut : le joueur
/// l'active lui-meme, et peut toujours ecouter une replique a la demande.
class VoiceAutoController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final saved = await ref.watch(repositoryProvider).getSetting(_autoSetting);
    return saved == 'on';
  }

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = AsyncData(next);
    await ref.read(repositoryProvider).setSetting(_autoSetting, next ? 'on' : 'off');
    if (!next) await ref.read(voiceProvider).stop();
  }
}

final voiceAutoProvider = AsyncNotifierProvider<VoiceAutoController, bool>(VoiceAutoController.new);
