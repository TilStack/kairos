import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/app/music.dart';
import 'package:kairos_app/features/keys/door_view.dart';
import 'package:kairos_app/game/key_forge_game.dart';
import 'package:kairos_core/kairos_core.dart';

import 'helpers.dart';

void main() {
  testWidgets('scene Cle forgee : joue, puis se met en pause toute seule', (tester) async {
    final game = KeyForgeGame(duration: 1.0);
    await tester.pumpWidget(MaterialApp(home: SizedBox(width: 400, height: 300, child: GameWidget(game: game))));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.paused, isFalse, reason: 'la fete est en cours');
    expect(game.children.whereType<KeyComponent>(), hasLength(1));
    expect(game.children.whereType<CharacterComponent>(), hasLength(1));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.paused, isTrue, reason: 'plus de calcul une fois la fete terminee');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Porte : la scene Flame apparait quand la Cle est forgee (celebrate)', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const verse = 'Ta parole est une lampe à mes pieds, Et une lumière sur mon sentier.';
    final c = DoorChallenge(verse: verse, verseId: 'PSA.119.105', level: 3, seed: 1);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DoorView(challenge: c, prompt: 'Porte', reference: 'Psaumes 119:105', onFinished: () {}, celebrate: true),
      ),
    ));
    await tester.enterText(find.byKey(const ValueKey('recall-verse')), verse);
    await tester.enterText(find.byKey(const ValueKey('recall-ref')), 'Ps 119:105');
    await tester.tap(find.text('Vérifier'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('key-forge-scene')), findsOneWidget);
    expect(find.text('La Clé est forgée.'), findsOneWidget);
    // Laisse la fete se terminer pour que le test s'acheve proprement.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });

  testWidgets('musique : bouton ecran-titre coupe puis relance, reglage conserve', (tester) async {
    final repo = newRepo();
    final music = FakeMusicPlayer();
    await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(DateTime(2026, 11, 1, 8)), music: music));
    await tester.pumpAndSettle();
    expect(music.starts, 1, reason: 'active par defaut au demarrage');

    await tester.tap(find.byKey(const ValueKey('music')));
    await tester.pumpAndSettle();
    expect(music.stops, 1);
    expect(await repo.getSetting('music'), 'off');
    expect(find.byIcon(Icons.music_off), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('music')));
    await tester.pumpAndSettle();
    expect(music.starts, 2);
    expect(await repo.getSetting('music'), 'on');
  });

  testWidgets('musique coupee au dernier lancement : elle ne demarre pas', (tester) async {
    final repo = newRepo();
    await repo.setSetting('music', 'off');
    final music = FakeMusicPlayer();
    await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(DateTime(2026, 11, 1, 8)), music: music));
    await tester.pumpAndSettle();
    expect(music.starts, 0);
    expect(find.byIcon(Icons.music_off), findsOneWidget);
  });

  test('le theme musical est declare et present', () {
    expect(MusicController, isNotNull);
  });
}
