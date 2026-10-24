import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kairos_core/kairos_core.dart';

import 'app_database.dart';
import 'repository.dart';

const _lampKey = 'lamp';
const _profileKey = 'profileId';
String _progressKey(String arcId) => 'progress:$arcId';

/// Implementation de production sur Drift (base chiffree par SQLCipher).
class DriftRepository implements KairosRepository {
  DriftRepository(this._db);

  final AppDatabase _db;

  @override
  Future<T> transaction<T>(Future<T> Function() action) => _db.transaction(action);

  Future<String?> _getKv(String key) async {
    final row = await (_db.select(_db.profileKv)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _setKv(String key, String value) => _db
      .into(_db.profileKv)
      .insertOnConflictUpdate(ProfileKvCompanion.insert(key: key, value: value));

  @override
  Future<String> profileId(String Function() generate) async {
    final existing = await _getKv(_profileKey);
    if (existing != null) return existing;
    final created = generate();
    await _setKv(_profileKey, created);
    return created;
  }

  @override
  Future<GameState?> loadSave(String arcId) async {
    final row = await (_db.select(_db.saves)..where((t) => t.arcId.equals(arcId))).getSingleOrNull();
    if (row == null) return null;
    return GameState.fromJson(jsonDecode(row.stateJson) as Map<String, Object?>);
  }

  @override
  Future<void> writeSave(GameState state, DateTime now) => _db.into(_db.saves).insertOnConflictUpdate(
        SavesCompanion.insert(
          arcId: state.arcId,
          stateJson: jsonEncode(state.toJson()),
          updatedAt: now.toUtc().millisecondsSinceEpoch,
        ),
      );

  @override
  Future<void> clearSave(String arcId) =>
      (_db.delete(_db.saves)..where((t) => t.arcId.equals(arcId))).go();

  @override
  Future<ArcProgress> loadProgress(String arcId) async {
    final raw = await _getKv(_progressKey(arcId));
    return raw == null
        ? const ArcProgress()
        : ArcProgress.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> saveProgress(String arcId, ArcProgress progress) =>
      _setKv(_progressKey(arcId), jsonEncode(progress.toJson()));

  @override
  Future<KeyMastery?> mastery(String verseId) async {
    final row =
        await (_db.select(_db.keyMasteries)..where((t) => t.verseId.equals(verseId))).getSingleOrNull();
    return row == null ? null : KeyMastery.fromJson(jsonDecode(row.json) as Map<String, Object?>);
  }

  @override
  Future<List<KeyMastery>> allMasteries() async {
    final rows = await _db.select(_db.keyMasteries).get();
    return [for (final r in rows) KeyMastery.fromJson(jsonDecode(r.json) as Map<String, Object?>)];
  }

  @override
  Future<void> saveMastery(KeyMastery mastery) => _db.into(_db.keyMasteries).insertOnConflictUpdate(
        KeyMasteriesCompanion.insert(
          verseId: mastery.verseRef,
          json: jsonEncode(mastery.toJson()),
          dueAt: mastery.due.millisecondsSinceEpoch,
        ),
      );

  @override
  Future<LampState> loadLamp() async {
    final raw = await _getKv(_lampKey);
    return raw == null ? const LampState() : LampState.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> saveLamp(LampState lamp) => _setKv(_lampKey, jsonEncode(lamp.toJson()));

  @override
  Future<void> addJournalEntry(JournalEntry entry) => _db.into(_db.journalRows).insertOnConflictUpdate(
        JournalRowsCompanion.insert(
          id: entry.id,
          type: entry.type.name,
          createdAt: entry.createdAt.millisecondsSinceEpoch,
          arcId: Value(entry.arcId),
          json: jsonEncode(entry.toJson()),
        ),
      );

  @override
  Future<List<JournalEntry>> journalEntries() async {
    final rows = await (_db.select(_db.journalRows)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt), (t) => OrderingTerm.desc(t.id)]))
        .get();
    return [for (final r in rows) JournalEntry.fromJson(jsonDecode(r.json) as Map<String, Object?>)];
  }
}
