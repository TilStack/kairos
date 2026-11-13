import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';

import 'app/kairos_app.dart';
import 'app/providers.dart';
import 'data/drift_repository.dart';
import 'data/secure_database.dart';

const arcAssets = {
  'fr': 'assets/arcs/joseph/arc.json',
  'en': 'assets/arcs/joseph/arc.en.json',
};

/// Charge et valide l'arc embarque : un arc invalide arrete le demarrage
/// avec un message clair plutot que de planter en cours de partie.
Future<Arc> loadBundledArc({String lang = 'fr'}) async {
  final arc = parseArcString(await rootBundle.loadString(arcAssets[lang]!));
  final report = validateArc(arc);
  if (!report.ok) {
    throw StateError('Arc invalide :\n${report.errors.join('\n')}');
  }
  return arc;
}

/// Un arc par langue : tous sont valides avant l'ouverture de l'interface.
Future<Map<String, Arc>> loadBundledArcs() async => {
      for (final lang in arcAssets.keys) lang: await loadBundledArc(lang: lang),
    };

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final arcs = await loadBundledArcs();
    final db = await openProductionDatabase(SecureStorageKeyStore());
    runApp(ProviderScope(
      overrides: [
        arcsProvider.overrideWithValue(arcs),
        repositoryProvider.overrideWithValue(DriftRepository(db)),
      ],
      child: const KairosApp(),
    ));
  } on Object catch (e) {
    runApp(StartupErrorApp(message: '$e'));
  }
}
