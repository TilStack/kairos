import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/app/sfx.dart';

import 'helpers.dart';

void main() {
  final start = DateTime(2026, 11, 1, 8);

  testWidgets('chaque clic sur un bouton joue le son de clic', (tester) async {
    final sfx = FakeSfxPlayer();
    await tester.pumpWidget(testApp(repo: newRepo(), clock: FakeClock(start), sfx: sfx));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('play')));
    await tester.pumpAndSettle();
    expect(sfx.played, [Sfx.tap]);

    await tester.tap(find.byKey(const ValueKey('chapter-ch1-potiphar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue')));
    await tester.pumpAndSettle();
    expect(sfx.played.length, 3);
    expect(sfx.played.every((s) => s == Sfx.tap), isTrue);
  });

  testWidgets('le son coupe rend aussi les clics muets', (tester) async {
    final sfx = FakeSfxPlayer();
    await tester.pumpWidget(testApp(repo: newRepo(), clock: FakeClock(start), sfx: sfx));
    await tester.pumpAndSettle();

    // Le clic qui coupe le son se fait entendre une derniere fois, puis plus rien.
    await tester.tap(find.byKey(const ValueKey('music')));
    await tester.pumpAndSettle();
    final afterMute = sfx.played.length;

    await tester.tap(find.byKey(const ValueKey('journal')));
    await tester.pumpAndSettle();
    expect(sfx.played.length, afterMute);
  });

  testWidgets('sans ProviderScope, un clic ne plante pas', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(Builder(builder: (context) {
      captured = context;
      return const SizedBox();
    }));
    expect(() => playSfx(captured), returnsNormally);
  });
}
