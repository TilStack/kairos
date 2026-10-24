import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Une sauvegarde de partie par arc (ecrite a chaque noeud, RF-01).
@DataClassName('SaveRow')
class Saves extends Table {
  TextColumn get arcId => text()();
  TextColumn get stateJson => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {arcId};
}

/// Maitrise d'un verset (repetition espacee).
@DataClassName('MasteryRow')
class KeyMasteries extends Table {
  TextColumn get verseId => text()();
  TextColumn get json => text()();
  IntColumn get dueAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {verseId};
}

/// Journal de disciple : colonnes de filtre + entree complete en JSON.
@DataClassName('JournalRow')
class JournalRows extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get createdAt => integer()();
  TextColumn get arcId => text().nullable()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Petites valeurs de profil (profileId, Huile, progression par arc).
@DataClassName('KvRow')
class ProfileKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Saves, KeyMasteries, JournalRows, ProfileKv])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
