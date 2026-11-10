import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/app/voice.dart';

import 'helpers.dart';

void main() {
  final start = DateTime(2026, 11, 1, 8);

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  Future<void> openFirstChapter(WidgetTester tester) async {
    await tapKey(tester, 'play');
    await tapKey(tester, 'chapter-ch1-potiphar');
  }

  group('VoiceService', () {
    test('la musique baisse pendant la lecture puis remonte', () async {
      final music = FakeMusicPlayer();
      final speech = FakeSpeechPlayer();
      final voice = VoiceService(speech, music);
      await voice.speak('Bonjour', characterId: 'lumo');
      expect(speech.spoken, ['Bonjour']);
      expect(music.ducks, [true, false]);
      expect(voice.speaking.value, isNull);
    });

    test('stop coupe la voix et remonte la musique', () async {
      final music = FakeMusicPlayer();
      final speech = FakeSpeechPlayer();
      final voice = VoiceService(speech, music);
      await voice.stop();
      expect(speech.stops, 1);
      expect(music.ducks, [false]);
    });

    test('chaque personnage a sa voix, et le Murmure est le plus grave', () {
      expect(voiceFor('murmure').pitch, lessThan(voiceFor('lumo').pitch));
      expect(voiceFor('jacob').pitch, lessThan(voiceFor('joseph').pitch));
      expect(voiceFor('inconnu').pitch, defaultVoice.pitch);
    });

    test('speakable : sans guillemets ni retours a la ligne', () {
      expect(speakable('« Ta parole\n  est une lampe »'), 'Ta parole est une lampe');
    });
  });

  group('dans le jeu', () {
    testWidgets('par defaut rien n est lu tout seul, mais ECOUTER est la', (tester) async {
      final speech = FakeSpeechPlayer();
      await tester.pumpWidget(testApp(repo: newRepo(), clock: FakeClock(start), speech: speech));
      await tester.pumpAndSettle();
      await openFirstChapter(tester);

      expect(speech.spoken, isEmpty);
      expect(find.byKey(const ValueKey('listen')), findsOneWidget);
      expect(find.text('Écouter'), findsOneWidget);

      await tapKey(tester, 'listen');
      expect(speech.spoken.single, contains('Bienvenue, témoin'));
      // La voix de Lumo, pas la voix par defaut.
      expect(speech.profiles.single.pitch, voiceFor('lumo').pitch);
    });

    testWidgets('lecture automatique activee : chaque replique est lue', (tester) async {
      final repo = newRepo();
      await repo.setSetting('voice_auto', 'on');
      final speech = FakeSpeechPlayer();
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start), speech: speech));
      await tester.pumpAndSettle();
      await openFirstChapter(tester);
      expect(speech.spoken, hasLength(1));
      expect(speech.spoken.first, contains('Bienvenue, témoin'));

      await tapKey(tester, 'continue');
      expect(speech.spoken, hasLength(2));
      // Joseph prend la parole avec sa propre voix.
      expect(speech.profiles.last.pitch, voiceFor('joseph').pitch);
    });

    testWidgets('le haut-parleur de l\'ecran-titre active puis coupe la lecture', (tester) async {
      final repo = newRepo();
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start)));
      await tester.pumpAndSettle();
      expect(await repo.getSetting('voice_auto'), isNull);

      await tapKey(tester, 'voice');
      expect(await repo.getSetting('voice_auto'), 'on');
      expect(find.textContaining('Lecture à voix haute activée'), findsOneWidget);

      await tapKey(tester, 'voice');
      expect(await repo.getSetting('voice_auto'), 'off');
      expect(find.textContaining('Lecture à voix haute coupée'), findsOneWidget);
    });
  });
}
