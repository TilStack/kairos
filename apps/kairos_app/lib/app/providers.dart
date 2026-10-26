import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';
import 'package:uuid/uuid.dart';

import '../characters/cast.dart';
import '../characters/character_spec.dart';
import '../characters/spec_from_def.dart';

import '../data/repository.dart';

/// Depot de donnees : fourni au demarrage (base chiffree) ou par les tests.
final repositoryProvider = Provider<KairosRepository>(
  (ref) => throw UnimplementedError('repositoryProvider doit etre surcharge'),
);

/// Arc charge au demarrage (valide avant l'ouverture de l'interface).
final arcProvider = Provider<Arc>(
  (ref) => throw UnimplementedError('arcProvider doit etre surcharge'),
);

/// Heure locale du joueur. Surchargeable dans les tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Generateur d'identifiants (UUID v4). Surchargeable dans les tests.
final idProvider = Provider<String Function()>((ref) => const Uuid().v4);

final engineProvider = Provider<NarrativeEngine>(
  (ref) => NarrativeEngine(ref.watch(arcProvider)),
);

/// Animations d'ambiance (decor, personnages) et de fete (scene Flame).
/// Desactivables : tests, et plus tard mode economie de batterie.
final animationsProvider = Provider<bool>((ref) => true);

/// Distribution disponible : personnages integres, completes (et au besoin
/// remplaces) par ceux que l'arc declare dans son contenu.
final castProvider = Provider<Map<String, CharacterSpec>>((ref) {
  final arc = ref.watch(arcProvider);
  return {
    for (final c in Cast.all) c.id: c,
    for (final d in arc.characters.values) d.id: specFromDef(d),
  };
});
