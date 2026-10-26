import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/app/kairos_app.dart';
import 'package:kairos_app/app/music.dart';
import 'package:kairos_app/app/providers.dart';
import 'package:kairos_app/data/memory_repository.dart';
import 'package:kairos_app/data/repository.dart';
import 'package:kairos_core/kairos_core.dart';

/// Arc de test commun a l'app et au moteur.
Arc loadTestArc() => parseArcString(File('../../content/test_arc/arc.json').readAsStringSync());

/// Faux lecteur de musique : aucun son en test, on note juste les appels.
class FakeMusicPlayer implements MusicPlayer {
  int starts = 0;
  int stops = 0;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> stop() async => stops++;
}

/// Horloge modifiable par les tests.
class FakeClock {
  FakeClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

/// Ecran assez grand pour afficher les formulaires sans defilement.
void tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget testApp({
  required KairosRepository repo,
  required FakeClock clock,
  Widget child = const KairosApp(),
  MusicPlayer? music,
}) {
  var n = 0;
  return ProviderScope(
    overrides: [
      arcProvider.overrideWithValue(loadTestArc()),
      repositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(clock.call),
      idProvider.overrideWithValue(() => 'id-${++n}'),
      musicPlayerProvider.overrideWithValue(music ?? FakeMusicPlayer()),
      // La scene Flame tourne en continu : desactivee pour pumpAndSettle.
      animationsProvider.overrideWithValue(false),
    ],
    child: child,
  );
}

MemoryRepository newRepo() => MemoryRepository();

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
