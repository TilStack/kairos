import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/adventure/title_screen.dart';
import 'package:kairos_app/app/theme.dart';

import 'helpers.dart';

/// Charge les polices : sans cela, flutter_test dessine le texte en blocs.
Future<void> loadFonts() async {
  final nunito = FontLoader('Nunito')..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
  await nunito.load();
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter_stable';
  final icons = File('$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

/// Capture l'ecran-titre en PNG (build/title_screen.png) pour controle visuel.
void main() {
  testWidgets('ecran-titre (capture)', (tester) async {
    await loadFonts();
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(testApp(
      repo: newRepo(),
      clock: FakeClock(DateTime(2026, 11, 1, 8)),
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: RepaintBoundary(key: key, child: const TitleScreen()),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('build/title_screen.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes.buffer.asUint8List());
    });
  });
}
