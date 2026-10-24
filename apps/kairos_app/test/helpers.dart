import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/app/kairos_app.dart';
import 'package:kairos_app/app/providers.dart';
import 'package:kairos_app/data/memory_repository.dart';
import 'package:kairos_app/data/repository.dart';
import 'package:kairos_core/kairos_core.dart';

/// Arc de test commun a l'app et au moteur.
Arc loadTestArc() => parseArcString(File('../../content/test_arc/arc.json').readAsStringSync());

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

Widget testApp({required KairosRepository repo, required FakeClock clock, Widget child = const KairosApp()}) {
  var n = 0;
  return ProviderScope(
    overrides: [
      arcProvider.overrideWithValue(loadTestArc()),
      repositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(clock.call),
      idProvider.overrideWithValue(() => 'id-${++n}'),
    ],
    child: child,
  );
}

MemoryRepository newRepo() => MemoryRepository();
