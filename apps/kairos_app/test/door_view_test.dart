import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    final button = find.widgetWithText(FilledButton, 'Vérifier');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(find.byType(ActionChip).first);
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
  });

  testWidgets('niveau 1 : un mot pose peut etre retire', (tester) async {
    await pumpDoor(tester, door(1));
    final total = door(1).scrambled.length;
    await tester.tap(find.byType(ActionChip).first);
    await tester.pump();
    expect(find.byType(ActionChip), findsNWidgets(total - 1));
    await tester.tap(find.byType(InputChip));
    await tester.pump();
    expect(find.byType(ActionChip), findsNWidgets(total));
  });

  testWidgets('niveau 2 : champs pour chaque trou, reussite', (tester) async {
    final c = door(2);
    await pumpDoor(tester, c);
    final answers = c.gaps.answers;
    for (var i = 0; i < answers.length; i++) {
      await tester.enterText(find.byKey(ValueKey('gap-$i')), answers[i]);
    }
    await tester.tap(find.text('Vérifier'));
    await tester.pumpAndSettle();
    expect(find.text('La Clé est forgée.'), findsOneWidget);
    expect(c.status, DoorStatus.forged);
  });

  testWidgets('niveau 3 : verset et reference saisis de memoire', (tester) async {
    final c = door(3);
    await pumpDoor(tester, c);
    await tester.enterText(find.byKey(const ValueKey('recall-verse')), verse.toLowerCase());
    await tester.enterText(find.byKey(const ValueKey('recall-ref')), 'Ps 119.105');
    await tester.tap(find.text('Vérifier'));
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
      await tester.tap(find.text('Vérifier'));
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
    await tester.tap(find.text('Continuer'));
    expect(finished, 1);
  });

  test('stableSeed : deterministe et different selon l entree', () {
    expect(stableSeed('GEN.39.9/0'), stableSeed('GEN.39.9/0'));
    expect(stableSeed('GEN.39.9/0'), isNot(stableSeed('GEN.39.9/1')));
    expect(stableSeed('GEN.39.9/0'), lessThanOrEqualTo(0xFFFFFFFF));
  });
}
