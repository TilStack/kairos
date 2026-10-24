import 'package:kairos_core/kairos_core.dart';

/// Progression d'un arc entre les chapitres.
class ArcProgress {
  const ArcProgress({
    this.completed = const {},
    this.traits = const {},
    this.flags = const {},
    this.keys = const {},
  });

  factory ArcProgress.fromJson(Map<String, Object?> json) => ArcProgress(
        completed: {...(json['completed']! as List<Object?>).cast<String>()},
        traits: {
          for (final e in (json['traits']! as Map<String, Object?>).entries)
            Trait.values.byName(e.key): e.value! as int,
        },
        flags: {...(json['flags']! as List<Object?>).cast<String>()},
        keys: {...(json['keys']! as List<Object?>).cast<String>()},
      );

  /// Chapitres termines.
  final Set<String> completed;

  /// Traits du coeur, drapeaux et Cles reportes au chapitre suivant.
  final Map<Trait, int> traits;
  final Set<String> flags;
  final Set<String> keys;

  Map<String, Object?> toJson() => {
        'completed': completed.toList()..sort(),
        'traits': {for (final e in traits.entries) e.key.name: e.value},
        'flags': flags.toList()..sort(),
        'keys': keys.toList()..sort(),
      };
}

/// Acces aux donnees locales. Tout est local et hors ligne ; l'implementation
/// de production est chiffree (SQLCipher).
abstract class KairosRepository {
  /// Groupe des ecritures dans une transaction : tout ou rien.
  Future<T> transaction<T>(Future<T> Function() action);

  /// Identifiant du profil, cree au premier appel (UUID, avenant A-02).
  Future<String> profileId(String Function() generate);

  Future<GameState?> loadSave(String arcId);
  Future<void> writeSave(GameState state, DateTime now);
  Future<void> clearSave(String arcId);

  Future<ArcProgress> loadProgress(String arcId);
  Future<void> saveProgress(String arcId, ArcProgress progress);

  Future<KeyMastery?> mastery(String verseId);
  Future<List<KeyMastery>> allMasteries();
  Future<void> saveMastery(KeyMastery mastery);

  Future<LampState> loadLamp();
  Future<void> saveLamp(LampState lamp);

  Future<void> addJournalEntry(JournalEntry entry);
  Future<List<JournalEntry>> journalEntries();
}
