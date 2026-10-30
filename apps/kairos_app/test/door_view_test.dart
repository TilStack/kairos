import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/adventure/stone_button.dart';
import 'package:kairos_app/features/keys/door_view.dart';
import 'package:kairos_core/kairos_core.dart';

const verse = 'Ta parole est une lampe à mes pieds, Et une lumière sur mon sentier.';

Future<void> pumpDoor(WidgetTester tester, DoorChallenge challenge, {VoidCallback? onFinished}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: DoorView(
        challenge: challenge,
        prompt: 'La porte est close.',
        reference: 'Psaumes 119:105',
        onFinished: onFinished ?? () {},
      ),
    ),
  ));
}

DoorChallenge door(int level) => DoorChallenge(verse: verse, verseId: 'PSA.119.105', level: level, seed: 3);

void main() {
  testWidgets('niveau 1 : Verifier desactive tant que tous les mots ne sont pas poses', (tester) async {
    await pumpDoor(tester, door(1));
    final button = find.byKey(const ValueKey('door-verify'));
    expect(tester.widget<StoneButton>(button).onPressed, isNull);
    // Le joueur sait pourquoi le bouton est grise.
    expect(find.text('Pose tous les mots pour pouvoir vérifier.'), findsOneWidget);
    await tester.tap(find.byType(WordTile).first);
    await tester.pump();
    expect(tester.widget<StoneButton>(button).onPressed, isNull);
  });

  testWidgets('chaque niveau dit au joueur quoi faire', (tester) async {
    for (final level in [1, 2, 3]) {
      await pumpDoor(tester, door(level));
      expect(find.text('Forge la Clé'), findsOneWidget, reason: 'niveau $level');
      expect(find.text(doorInstructions[level]!), findsOneWidget, reason: 'niveau $level');
      expect(find.bySemanticsLabel('Essais restants : 3 sur 3'), findsOneWidget);
    }
  });

  testWidgets('niveau 1 : un mot pose peut etre retire', (tester) async {
    await pumpDoor(tester, door(1));
    final total = door(1).scrambled.length;
    await tester.tap(find.byType(WordTile).first);
    await tester.pump();
    expect(find.byType(WordTile), findsNWidgets(total - 1));
    await tester.tap(find.byType(PlacedWordTile));
    await tester.pump();
    expect(find.byType(WordTile), findsNWidgets(total));
  });

  testWidgets('niveau 2 : champs pour chaque trou, reussite', (tester) async {
    final c = door(2);
    await pumpDoor(tester, c);
    final answers = c.gaps.answers;
    for (var i = 0; i < answers.length; i++) {
      await tester.enterText(find.byKey(ValueKey('gap-$i')), answers[i]);
    }
    await tester.tap(find.byKey(const ValueKey('door-verify')));
    await tester.pumpAndSettle();
    expect(find.text('La Clé est forgée.'), findsOneWidget);
    expect(c.status, DoorStatus.forged);
  });

  testWidgets('niveau 3 : verset et reference saisis de memoire', (tester) async {
    final c = door(3);
    await pumpDoor(tester, c);
    await tester.enterText(find.byKey(const ValueKey('recall-verse')), verse.toLowerCase());
    await tester.enterText(find.byKey(const ValueKey('recall-ref')), 'Ps 119.105');
    await tester.tap(find.byKey(const ValueKey('door-verify')));
    await tester.pumpAndSettle();
    expect(find.text('La Clé est forgée.'), findsOneWidget);
    expect(find.text('Sans aucun indice : bravo.'), findsOneWidget);
  });

  testWidgets('niveau 3 : indices progressifs puis Porte jamais bloquante', (tester) async {
    var finished = 0;
    final c = door(3);
    await pumpDoor(tester, c, onFinished: () => finished++);

    Future<void> failOnce() async {
      await tester.enterText(find.byKey(const ValueKey('recall-verse')), 'je ne sais plus');
      await tester.tap(find.byKey(const ValueKey('door-verify')));
      await tester.pumpAndSettle();
    }

    await failOnce();
    expect(find.textContaining('Il te reste 2 essais'), findsOneWidget);
    expect(find.textContaining('Indice : '), findsOneWidget);
    await failOnce();
    expect(find.textContaining('Il te reste 1 essai.'), findsOneWidget);
    await failOnce();

    expect(c.status, DoorStatus.exhausted);
    expect(find.textContaining('La Porte s\'ouvre malgré tout'), findsOneWidget);
    expect(find.text('« $verse »'), findsOneWidget); // le verset est donne, jamais cache
    await tester.tap(find.byKey(const ValueKey('door-continue')));
    expect(finished, 1);
  });

  test('stableSeed : deterministe et different selon l entree', () {
    expect(stableSeed('GEN.39.9/0'), stableSeed('GEN.39.9/0'));
    expect(stableSeed('GEN.39.9/0'), isNot(stableSeed('GEN.39.9/1')));
    expect(stableSeed('GEN.39.9/0'), lessThanOrEqualTo(0xFFFFFFFF));
  });
}
