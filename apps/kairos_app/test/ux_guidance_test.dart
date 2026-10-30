import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/data/repository.dart';
import 'package:kairos_app/features/onboarding/how_to_play_screen.dart';
import 'package:kairos_core/kairos_core.dart';

import 'helpers.dart';

/// Le jeu dit au joueur ce qu'il doit faire, sur chaque ecran.
void main() {
  final arc = loadTestArc();
  final start = DateTime(2026, 11, 1, 8);

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  group('guide du premier lancement', () {
    testWidgets('s ouvre tout seul une fois, puis plus jamais', (tester) async {
      final repo = newRepo();
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start), onboarding: true));
      await tester.pumpAndSettle();
      expect(find.text('Comment jouer'), findsOneWidget);
      for (final rule in howToRules) {
        expect(find.text(rule.title), findsOneWidget);
      }

      await tapKey(tester, 'howto-done');
      expect(find.text('Comment jouer'), findsNothing);
      expect(find.byKey(const ValueKey('play')), findsOneWidget);

      // Deuxieme lancement : le guide ne revient pas.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start), onboarding: true));
      await tester.pumpAndSettle();
      expect(find.text('Comment jouer'), findsNothing);
    });

    testWidgets('le bouton ? le rouvre a tout moment', (tester) async {
      await tester.pumpWidget(testApp(repo: newRepo(), clock: FakeClock(start)));
      await tester.pumpAndSettle();
      expect(find.text('Comment jouer'), findsNothing);
      await tapKey(tester, 'howto');
      expect(find.text('Comment jouer'), findsOneWidget);
    });
  });

  group('ecran-titre', () {
    testWidgets('la lampe dit ce qu\'il faut faire aujourd\'hui', (tester) async {
      tallScreen(tester);
      final repo = newRepo();
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start)));
      await tester.pumpAndSettle();
      expect(find.textContaining('À méditer aujourd\'hui'), findsOneWidget);

      await repo.saveLamp(LampState(
        oil: 50,
        streak: 2,
        lastMeditationDay: dayNumber(start),
        lastUpdateDay: dayNumber(start),
      ));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Médité aujourd\'hui · série 2 j'), findsOneWidget);
    });

    testWidgets('JOUER devient CONTINUER des qu\'un chapitre est termine', (tester) async {
      tallScreen(tester);
      final repo = newRepo();
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start)));
      await tester.pumpAndSettle();
      expect(find.text('JOUER'), findsWidgets);

      await repo.saveProgress(arc.id, const ArcProgress(completed: {'ch1-potiphar'}));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start)));
      await tester.pumpAndSettle();
      expect(find.text('CONTINUER'), findsWidgets);
      expect(find.text('JOUER'), findsNothing);
    });
  });

  testWidgets('carte : prochain pas annonce et chapitre verrouille explique', (tester) async {
    tallScreen(tester);
    await tester.pumpWidget(testApp(repo: newRepo(), clock: FakeClock(start)));
    await tester.pumpAndSettle();
    await tapKey(tester, 'play');

    expect(find.text('Ton prochain pas'), findsOneWidget);
    expect(find.text('Touche le chapitre 1 pour continuer ton histoire.'), findsOneWidget);
    expect(find.textContaining('À jouer'), findsOneWidget);
    expect(find.text('Termine le chapitre 1 pour l\'ouvrir'), findsOneWidget);
  });

  testWidgets('carte : arc termine -> message de fin', (tester) async {
    tallScreen(tester);
    final repo = newRepo();
    await repo.saveProgress(arc.id, ArcProgress(completed: {for (final c in arc.chapters) c.id}));
    await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start)));
    await tester.pumpAndSettle();
    await tapKey(tester, 'play');
    expect(find.text('Arc terminé !'), findsOneWidget);
  });

  testWidgets('histoire : choix et discernement expliquent quoi faire', (tester) async {
    tallScreen(tester);
    await tester.pumpWidget(testApp(repo: newRepo(), clock: FakeClock(start)));
    await tester.pumpAndSettle();
    await tapKey(tester, 'play');
    await tapKey(tester, 'chapter-ch1-potiphar');
    while (find.byKey(const ValueKey('continue')).evaluate().isNotEmpty) {
      await tapKey(tester, 'continue');
    }
    expect(find.textContaining('Il n\'y a pas de mauvaise réponse'), findsOneWidget);

    await tapKey(tester, 'option-defend');
    while (find.byKey(const ValueKey('continue')).evaluate().isNotEmpty) {
      await tapKey(tester, 'continue');
    }
    expect(find.text('Défi de discernement'), findsOneWidget);
    // Chaque type d'anomalie est explique en une phrase.
    for (final type in AnomalyType.values) {
      expect(find.byKey(ValueKey('anomaly-${type.id}')), findsOneWidget);
    }
    expect(find.textContaining('La phrase vient d\'ailleurs'), findsOneWidget);
  });

  testWidgets('lampe : trois etapes numerotees et reponse visiblement cochee', (tester) async {
    tallScreen(tester);
    await tester.pumpWidget(testApp(repo: newRepo(), clock: FakeClock(start)));
    await tester.pumpAndSettle();
    await tapKey(tester, 'lamp');

    expect(find.text('Lis le passage du jour'), findsOneWidget);
    expect(find.text('Réponds à la question'), findsOneWidget);
    expect(find.text('Écris ta réflexion'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsWidgets);
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);

    await tapKey(tester, 'answer-1');
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });
}
