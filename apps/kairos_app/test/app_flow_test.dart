import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/main.dart';
import 'package:kairos_core/kairos_core.dart';

import 'helpers.dart';

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Remet le verset du niveau 1 en ordre en touchant les mots.
Future<void> solveOrder(WidgetTester tester, String verse) async {
  for (final word in verse.split(' ')) {
    await tester.tap(find.widgetWithText(ActionChip, word).first);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  final arc = loadTestArc();
  final gen399 = arc.verseText('GEN.39.9')!;
  final start = DateTime(2026, 11, 1, 8);

  test('l asset embarque est identique a l arc de test du depot', () {
    String norm(String s) => s.replaceAll('\r\n', '\n');
    final asset = norm(File('assets/arcs/joseph-test/arc.json').readAsStringSync());
    final source = norm(File('../../content/test_arc/arc.json').readAsStringSync());
    expect(asset, source);
  });

  testWidgets('l arc embarque se charge et se valide au demarrage', (tester) async {
    final loaded = await loadBundledArc();
    expect(loaded.id, 'joseph-test');
  });

  testWidgets('parcours complet du chapitre 1, avec persistance', (tester) async {
    tallScreen(tester);
    final repo = newRepo();
    final clock = FakeClock(start);
    await tester.pumpWidget(testApp(repo: repo, clock: clock));
    await tester.pumpAndSettle();
    await tapKey(tester, 'play');

    // Le chapitre 2 est verrouille tant que le 1 n'est pas termine.
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    await tapKey(tester, 'chapter-ch1-potiphar');
    expect(find.textContaining('maison d\'Égypte'), findsOneWidget);
    await tapText(tester, 'Continuer');

    // Choix : l'option reservee au courage est masquee.
    expect(find.byKey(const ValueKey('option-warn')), findsNothing);
    await tapKey(tester, 'option-defend');

    // Discernement : mauvaise reponse d'abord -> explication, sans honte.
    await tapKey(tester, 'anomaly-truncated');
    expect(find.textContaining('Pas tout à fait'), findsOneWidget);
    expect(find.textContaining('ne figure nulle part dans la Bible'), findsOneWidget);
    await tapKey(tester, 'feedback-continue');

    // Porte, niveau 1 : on remet le verset en ordre.
    expect(find.text('Niveau 1 · Reconstitution'), findsOneWidget);
    await solveOrder(tester, gen399);
    await tapText(tester, 'Vérifier');
    expect(find.text('La Clé est forgée.'), findsOneWidget);
    await tapText(tester, 'Continuer');

    // Debriefing : texte exact de l'Ecriture + traits reveles.
    expect(find.text('« $gen399 »'), findsOneWidget);
    expect(find.textContaining('Intégrité · 1'), findsOneWidget);
    await tapKey(tester, 'debrief-continue');
    expect(find.text('Chapitre terminé'), findsOneWidget);

    // Persistance : progression, Cle, Journal, sauvegarde effacee.
    final progress = await repo.loadProgress('joseph-test');
    expect(progress.completed, {'ch1-potiphar'});
    expect(progress.keys, {'GEN.39.9'});
    expect(progress.traits[Trait.integrity], 1);
    expect((await repo.mastery('GEN.39.9'))!.level, 2); // promu au niveau 2
    final journal = await repo.journalEntries();
    expect(journal.map((e) => e.type), containsAll([JournalEntryType.key, JournalEntryType.discernment]));
    expect(await repo.loadSave('joseph-test'), isNull);

    // Retour a la carte : le chapitre 2 est debloque.
    await tapKey(tester, 'end-back');
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('fermeture brutale : reprise exacte au dernier noeud', (tester) async {
    tallScreen(tester);
    final repo = newRepo();
    final clock = FakeClock(start);
    await tester.pumpWidget(testApp(repo: repo, clock: clock));
    await tester.pumpAndSettle();
    await tapKey(tester, 'play');
    await tapKey(tester, 'chapter-ch1-potiphar');
    await tapText(tester, 'Continuer'); // arrive au choix
    expect(find.byKey(const ValueKey('option-defend')), findsOneWidget);

    // L'application est detruite (nouvel arbre de widgets, memes donnees).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(testApp(repo: repo, clock: clock));
    await tester.pumpAndSettle();
    await tapKey(tester, 'play');
    await tapKey(tester, 'chapter-ch1-potiphar');

    expect(find.byKey(const ValueKey('option-defend')), findsOneWidget);
    expect(find.textContaining('maison d\'Égypte'), findsNothing);
  });

  testWidgets('une Porte deja forgee reprend au niveau de maitrise', (tester) async {
    tallScreen(tester);
    final repo = newRepo();
    final clock = FakeClock(start);
    await repo.saveMastery(KeyMastery.fresh('GEN.39.9', start).copyWith(level: 3, forged: true));
    await tester.pumpWidget(testApp(repo: repo, clock: clock));
    await tester.pumpAndSettle();
    await tapKey(tester, 'play');
    await tapKey(tester, 'chapter-ch1-potiphar');
    await tapText(tester, 'Continuer');
    await tapKey(tester, 'option-defend');
    await tapKey(tester, 'anomaly-misattributed');
    expect(find.text('Bien vu.'), findsOneWidget);
    await tapKey(tester, 'feedback-continue');
    expect(find.text('Niveau 3 · De mémoire'), findsOneWidget);
  });
}
