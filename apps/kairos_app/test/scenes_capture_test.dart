import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/app/kairos_app.dart';
import 'package:kairos_app/data/repository.dart';

import 'helpers.dart';

/// Captures des scenes reelles (build/scenes/*.png) pour controle visuel.
void main() {
  testWidgets('scenes du chapitre 1 et 2 (captures)', (tester) async {
    await loadFonts();
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final repo = newRepo();
    await repo.saveProgress('joseph-test', const ArcProgress(completed: {'ch1-potiphar'}));
    final key = GlobalKey();
    await tester.pumpWidget(testApp(
      repo: repo,
      clock: FakeClock(DateTime(2026, 11, 1, 8)),
      child: RepaintBoundary(key: key, child: const KairosApp()),
    ));
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        File('build/scenes/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes.buffer.asUint8List());
      });
    }

    Future<void> next() async {
      await tester.tap(find.byKey(const ValueKey('continue')));
      await tester.pumpAndSettle();
    }

    // Chapitre 1 : desert, puis maison.
    await tester.tap(find.byKey(const ValueKey('play')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chapter-ch1-potiphar')));
    await tester.pumpAndSettle();
    await shot('1_lumo_desert');
    await next();
    await shot('2_joseph_desert');
    await next();
    await shot('3_choix_intendant');
    await tester.tap(find.byKey(const ValueKey('option-defend')));
    await tester.pumpAndSettle();
    await shot('4_potiphar_maison');
    await next();
    await shot('5_murmure');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Chapitre 2 : palais, souvenir.
    await tester.tap(find.byKey(const ValueKey('chapter-ch2-egypte')));
    await tester.pumpAndSettle();
    await shot('6_lumo_palais');
    await next();
    await shot('7_frere_palais');
    await next();
    await shot('8_benjamin');
    await next();
    await shot('9_jacob_souvenir');
  });
}
