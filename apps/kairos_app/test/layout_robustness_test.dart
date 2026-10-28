import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Cherche les erreurs de mise en page (debordements, contraintes impossibles)
/// sur de petits ecrans, en paysage, avec le clavier ouvert et avec une
/// police agrandie (accessibilite, CDC §9.6). Chaque cas echoue au premier
/// « RenderFlex overflowed » ou ArgumentError.
void main() {
  final start = DateTime(2026, 11, 1, 8);

  const screens = <String, (Size, double)>{
    'petit telephone 320x568': (Size(320, 568), 1.0),
    'telephone courant 360x740': (Size(360, 740), 1.0),
    'grand telephone 412x915': (Size(412, 915), 1.0),
    'paysage 740x360': (Size(740, 360), 1.0),
    'paysage minuscule 568x300': (Size(568, 300), 1.0),
    'police agrandie x1,5 sur 360x740': (Size(360, 740), 1.5),
    'police agrandie x2 sur 320x568': (Size(320, 568), 2.0),
  };

  for (final entry in screens.entries) {
    testWidgets('pages et scenes sans erreur : ${entry.key}', (tester) async {
      final (size, scale) = entry.value;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final repo = newRepo();
      await tester.pumpWidget(testApp(repo: repo, clock: FakeClock(start)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'ecran-titre');

      Future<void> tap(String key) async {
        final target = find.byKey(ValueKey(key));
        // Les listes peuvent defiler : on amene la cible a l'ecran, comme le ferait le joueur.
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      void expectOnScreen(String key, String what) {
        final c = tester.getCenter(find.byKey(ValueKey(key)));
        expect(c.dy, lessThan(size.height), reason: '$what doit etre visible sans defiler');
        expect(c.dy, greaterThan(0), reason: what);
      }

      Future<void> back() async {
        await tester.tap(find.byIcon(Icons.arrow_back).last);
        await tester.pumpAndSettle();
      }

      // Lampe (formulaire avec champ de texte) et Journal.
      await tap('lamp');
      expect(tester.takeException(), isNull, reason: 'lampe');
      await back();
      await tap('journal');
      expect(tester.takeException(), isNull, reason: 'journal');
      await back();

      // Carte, puis chaque type de scene du chapitre 1.
      await tap('play');
      expect(tester.takeException(), isNull, reason: 'carte');
      await tap('chapter-ch1-potiphar');
      expect(tester.takeException(), isNull, reason: 'dialogue');
      // L'action principale reste visible, quelle que soit la longueur du texte.
      if (scale == 1.0 && size.height >= 700) expectOnScreen('continue', 'CONTINUER');
      await tap('continue');
      await tap('continue');
      expect(tester.takeException(), isNull, reason: 'choix');
      await tap('option-defend');
      await tap('continue');
      expect(tester.takeException(), isNull, reason: 'discernement');
      await tap('anomaly-misattributed');
      expect(tester.takeException(), isNull, reason: 'explication');
      await tap('feedback-continue');
      expect(tester.takeException(), isNull, reason: 'porte');
    });
  }

  testWidgets('clavier ouvert : la page Lampe reste affichable', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    // Le clavier mange la moitie basse de l'ecran.
    tester.view.viewInsets = const FakeViewPadding(bottom: 380);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp(repo: newRepo(), clock: FakeClock(start)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lamp')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
