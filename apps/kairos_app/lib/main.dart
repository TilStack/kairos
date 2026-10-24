import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';

import 'app/kairos_app.dart';
import 'app/providers.dart';
import 'data/drift_repository.dart';
import 'data/secure_database.dart';

const arcAsset = 'assets/arcs/joseph-test/arc.json';

/// Charge et valide l'arc embarque : un arc invalide arrete le demarrage
/// avec un message clair plutot que de planter en cours de partie.
Future<Arc> loadBundledArc() async {
  final arc = parseArcString(await rootBundle.loadString(arcAsset));
  final report = validateArc(arc);
  if (!report.ok) {
    throw StateError('Arc invalide :\n${report.errors.join('\n')}');
  }
  return arc;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final arc = await loadBundledArc();
    final db = await openProductionDatabase(SecureStorageKeyStore());
    runApp(ProviderScope(
      overrides: [
        arcProvider.overrideWithValue(arc),
        repositoryProvider.overrideWithValue(DriftRepository(db)),
      ],
      child: const KairosApp(),
    ));
  } on Object catch (e) {
    runApp(StartupErrorApp(message: '$e'));
  }
}
