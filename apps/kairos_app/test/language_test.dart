import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/app/l10n.dart';
import 'package:kairos_app/app/l10n_en.dart';
import 'package:kairos_app/app/l10n_fr.dart';
import 'package:kairos_app/data/repository.dart';

import 'helpers.dart';

void main() {
  final start = DateTime(2026, 11, 1, 8);

  Set<String> placeholders(String text) =>
      RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

  group('textes de l\'interface', () {
    test('le francais et l\'anglais ont exactement les memes cles', () {
      expect(enStrings.keys.toSet(), frStrings.keys.toSet());
    });

    test('chaque texte garde les memes {parametres} dans les deux langues', () {
      for (final key in frStrings.keys) {
        expect(placeholders(enStrings[key]!), placeholders(frStrings[key]!), reason: key);
      }
    });

    test('aucun texte anglais vide ou reste en francais accentue', () {
      for (final e in enStrings.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
        // « Français » est le nom de la langue : seul mot accentue permis.
        expect(RegExp(r'[éèêàùçôîÉ]').hasMatch(e.value.replaceAll('Français', '')), isFalse, reason: e.key);
      }
    });

    test('toute cle utilisee dans le code existe', () {
      final used = <String>{};
      final prefixes = <String>{};
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in files) {
        final src = f.readAsStringSync();
        for (final m in RegExp(r"tr\(\s*'([^'$]+)'").allMatches(src)) {
          used.add(m.group(1)!);
        }
        // Cles construites : tr('prefixe.${...}').
        for (final m in RegExp(r"tr\(\s*'([\w.]+\.)\$").allMatches(src)) {
          prefixes.add(m.group(1)!);
        }
        // Cles choisies par condition : tr(cond ? 'a' : 'b').
        for (final m in RegExp(r"\?\s*'([\w.]+)'\s*:\s*'([\w.]+)'").allMatches(src)) {
          for (final k in [m.group(1)!, m.group(2)!]) {
            if (frStrings.containsKey(k)) used.add(k);
          }
        }
      }
      for (final key in used) {
        expect(frStrings.keys, contains(key), reason: 'cle absente : $key');
      }
      for (final p in prefixes) {
        expect(frStrings.keys.any((k) => k.startsWith(p)), isTrue, reason: 'aucune cle ne commence par $p');
      }
      expect(used.length, greaterThan(40));
    });

    test('translate : parametres, repli sur le francais, puis sur la cle', () {
      expect(translate('en', 'lamp.oil', {'oil': 40, 'max': 100}), 'Oil: 40 / 100');
      expect(translate('fr', 'lamp.oil', {'oil': 40, 'max': 100}), 'Huile : 40 / 100');
      expect(translate('de', 'play'), 'JOUER');
      expect(translate('en', 'cle.inconnue'), 'cle.inconnue');
    });
  });

  group('changement de langue dans le jeu', () {
    testWidgets('le bouton FR/EN bascule le jeu et se souvient du choix', (tester) async {
      tallScreen(tester);
      final repo = newRepo();
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start), arcs: loadRealArcs()));
      await tester.pumpAndSettle();
      expect(find.text('JOUER'), findsWidgets);
      expect(find.text('EN'), findsWidgets); // la langue vers laquelle on bascule

      await tester.tap(find.byKey(const ValueKey('lang')));
      await tester.pumpAndSettle();
      expect(find.text('PLAY'), findsWidgets);
      expect(find.text('MY LAMP'), findsWidgets);
      expect(find.text('FR'), findsWidgets);
      expect(await repo.getSetting('language'), 'en');

      // Reouverture de l'application : l'anglais est conserve.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start), arcs: loadRealArcs()));
      await tester.pumpAndSettle();
      expect(find.text('PLAY'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('lang')));
      await tester.pumpAndSettle();
      expect(find.text('JOUER'), findsWidgets);
      expect(await repo.getSetting('language'), 'fr');
    });

    testWidgets('l\'histoire, les versets et la voix suivent la langue', (tester) async {
      tallScreen(tester);
      final repo = newRepo();
      await repo.setSetting('language', 'en');
      final speech = FakeSpeechPlayer();
      await tester.pumpWidget(
        testApp(repo: repo, clock: FakeClock(start), arcs: loadRealArcs(), speech: speech),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('play')));
      await tester.pumpAndSettle();
      expect(find.text('Adventure'), findsOneWidget);
      expect(find.text('The Dreamer'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('chapter-ch1-reveur')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Welcome, witness!'), findsOneWidget);
      expect(find.text('CONTINUE'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('listen')));
      await tester.pumpAndSettle();
      expect(speech.spoken.single, contains('Welcome, witness!'));
      expect(speech.languages.single, 'en');
    });

    testWidgets('la progression survit au changement de langue', (tester) async {
      tallScreen(tester);
      final repo = newRepo();
      await repo.saveProgress('joseph', const ArcProgress(completed: {'ch1-reveur'}));
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start), arcs: loadRealArcs()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('play')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Terminé'), findsWidgets);

      await tester.tap(find.byIcon(Icons.arrow_back).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lang')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('play')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Completed'), findsWidgets);
    });
  });
}
