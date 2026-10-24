import 'dart:convert';

import 'package:kairos_core/kairos_core.dart';

import 'repository.dart';

/// Implementation en memoire (tests). Passe par le JSON comme la vraie base,
/// pour attraper tout oubli de serialisation.
class MemoryRepository implements KairosRepository {
  final _saves = <String, String>{};
  final _progress = <String, String>{};
  final _masteries = <String, String>{};
  final _journal = <String, String>{};
  String? _lamp;
  String? _profileId;

  @override
  Future<T> transaction<T>(Future<T> Function() action) => action();

  @override
  Future<String> profileId(String Function() generate) async =>
      _profileId ??= generate();

  @override
  Future<GameState?> loadSave(String arcId) async {
    final raw = _saves[arcId];
    return raw == null ? null : GameState.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> writeSave(GameState state, DateTime now) async =>
      _saves[state.arcId] = jsonEncode(state.toJson());

  @override
  Future<void> clearSave(String arcId) async => _saves.remove(arcId);

  @override
  Future<ArcProgress> loadProgress(String arcId) async {
    final raw = _progress[arcId];
    return raw == null
        ? const ArcProgress()
        : ArcProgress.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> saveProgress(String arcId, ArcProgress progress) async =>
      _progress[arcId] = jsonEncode(progress.toJson());

  @override
  Future<KeyMastery?> mastery(String verseId) async {
    final raw = _masteries[verseId];
    return raw == null ? null : KeyMastery.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<List<KeyMastery>> allMasteries() async => [
        for (final raw in _masteries.values)
          KeyMastery.fromJson(jsonDecode(raw) as Map<String, Object?>),
      ];

  @override
  Future<void> saveMastery(KeyMastery mastery) async =>
      _masteries[mastery.verseRef] = jsonEncode(mastery.toJson());

  @override
  Future<LampState> loadLamp() async => _lamp == null
      ? const LampState()
      : LampState.fromJson(jsonDecode(_lamp!) as Map<String, Object?>);

  @override
  Future<void> saveLamp(LampState lamp) async => _lamp = jsonEncode(lamp.toJson());

  @override
  Future<void> addJournalEntry(JournalEntry entry) async =>
      _journal[entry.id] = jsonEncode(entry.toJson());

  @override
  Future<List<JournalEntry>> journalEntries() async => filterEntries([
        for (final raw in _journal.values)
          JournalEntry.fromJson(jsonDecode(raw) as Map<String, Object?>),
      ]);
}
