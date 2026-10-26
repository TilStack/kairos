import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_core/kairos_core.dart';

import 'helpers.dart';

void main() {
  final arc = loadTestArc();
  final start = DateTime(2026, 11, 1, 8);
  final today = meditationForDay(arc, dayNumber(start))!;

  // Depuis l'ecran-titre : 'Lampe' et 'Journal' ouvrent l'ecran correspondant.
  Future<void> openTab(WidgetTester tester, String label) async {
    final key = label == 'Lampe' ? 'lamp' : 'journal';
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  Future<void> fillMeditation(WidgetTester tester, {required int answer, required String reflection}) async {
    await tester.tap(find.byKey(ValueKey('answer-$answer')));
    await tester.enterText(find.byKey(const ValueKey('reflection')), reflection);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('meditate')));
    await tester.pumpAndSettle();
  }

  testWidgets('lecture trop rapide : invitation douce, rien n est recharge', (tester) async {
    tallScreen(tester);
    final repo = newRepo();
    final clock = FakeClock(start);
    await tester.pumpWidget(testApp(repo: repo, clock: clock));
    await tester.pumpAndSettle();
    await openTab(tester, 'Lampe');

    await fillMeditation(tester, answer: today.answerIndex, reflection: 'Je veux me confier en Dieu.');
    expect(find.text(rejection('tooFast')), findsOneWidget);
    expect((await repo.loadLamp()).oil, 0);
    expect(await repo.journalEntries(), isEmpty);
  });

  testWidgets('mauvaise reponse puis succes : Huile rechargee, Journal ecrit', (tester) async {
    tallScreen(tester);
    final repo = newRepo();
    final clock = FakeClock(start);
    await tester.pumpWidget(testApp(repo: repo, clock: clock));
    await tester.pumpAndSettle();
    await openTab(tester, 'Lampe');

    clock.advance(const Duration(seconds: 40));
    final wrong = (today.answerIndex + 1) % today.options.length;
    await fillMeditation(tester, answer: wrong, reflection: 'Je veux me confier en Dieu.');
    expect(find.text(rejection('wrongAnswer')), findsOneWidget);

    await fillMeditation(tester, answer: today.answerIndex, reflection: 'Je veux me confier en Dieu.');
    expect(find.byKey(const ValueKey('blessing')), findsOneWidget);
    expect(find.text('Huile : $oilPerMeditation / $maxOil'), findsOneWidget);

    final lamp = await repo.loadLamp();
    expect(lamp.oil, oilPerMeditation);
    expect(lamp.streak, 1);
    final journal = await repo.journalEntries();
    expect(journal.single.type, JournalEntryType.meditation);
    expect(journal.single.body, contains('Je veux me confier en Dieu.'));
    expect(journal.single.refs, [today.passage]);
  });

  testWidgets('deja medite aujourd hui : pas de second formulaire', (tester) async {
    tallScreen(tester);
    final repo = newRepo();
    await repo.saveLamp(LampState(oil: 50, streak: 1, lastMeditationDay: dayNumber(start), lastUpdateDay: dayNumber(start)));
    await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start)));
    await tester.pumpAndSettle();
    await openTab(tester, 'Lampe');
    expect(find.text('Tu as médité aujourd\'hui.'), findsOneWidget);
    expect(find.byKey(const ValueKey('meditate')), findsNothing);
  });

  testWidgets('l Huile decroit doucement a l ouverture apres des jours d absence', (tester) async {
    tallScreen(tester);
    final repo = newRepo();
    final longAgo = dayNumber(start) - 4;
    await repo.saveLamp(LampState(oil: 50, streak: 3, lastMeditationDay: longAgo, lastUpdateDay: longAgo));
    await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start)));
    await tester.pumpAndSettle();
    await openTab(tester, 'Lampe');
    expect(find.text('Huile : ${50 - 4 * oilDecayPerDay} / $maxOil'), findsOneWidget);
    // Jamais punitif : le formulaire reste disponible.
    expect(find.byKey(const ValueKey('meditate')), findsOneWidget);
    expect((await repo.loadLamp()).oil, 50 - 4 * oilDecayPerDay);
  });

  testWidgets('Journal : vide, note ajoutee, filtre par type', (tester) async {
    tallScreen(tester);
    final repo = newRepo();
    final clock = FakeClock(start);
    await repo.addJournalEntry(JournalEntry.meditation(
      id: 'm1', at: start, arcId: arc.id, meditation: today, reflection: 'Une réflexion sincère.',
    ));
    await tester.pumpWidget(testApp(repo: repo, clock: clock));
    await tester.pumpAndSettle();
    await openTab(tester, 'Journal');
    expect(find.text('Méditation'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-note')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('note-field')), 'Merci Seigneur pour cette journée.');
    await tester.tap(find.byKey(const ValueKey('note-save')));
    await tester.pumpAndSettle();
    expect(find.text('Merci Seigneur pour cette journée.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('filter-note')));
    await tester.pumpAndSettle();
    expect(find.text('Merci Seigneur pour cette journée.'), findsOneWidget);
    expect(find.text('Méditation'), findsNothing);

    // Une note vide n'est pas enregistree.
    await tester.tap(find.byKey(const ValueKey('add-note')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('note-field')), '   ');
    await tester.tap(find.byKey(const ValueKey('note-save')));
    await tester.pumpAndSettle();
    expect((await repo.journalEntries()).where((e) => e.type == JournalEntryType.note), hasLength(1));
  });

  testWidgets('Journal vide : message d accueil rassurant', (tester) async {
    tallScreen(tester);
    await tester.pumpWidget(testApp(repo: newRepo(), clock: FakeClock(start)));
    await tester.pumpAndSettle();
    await openTab(tester, 'Journal');
    expect(find.textContaining('Rien ne quitte ton téléphone'), findsOneWidget);
  });
}

/// Message attendu pour un refus donne (voir meditation_screen.dart).
String rejection(String name) => switch (name) {
      'tooFast' => 'Prends encore un moment pour lire et méditer le passage.',
      'wrongAnswer' => 'Relis le passage : la réponse s\'y trouve.',
      _ => throw ArgumentError(name),
    };
