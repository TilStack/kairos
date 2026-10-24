import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';
import 'package:uuid/uuid.dart';

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
