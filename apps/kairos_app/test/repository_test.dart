import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/data/app_database.dart';
import 'package:kairos_app/data/drift_repository.dart';
import 'package:kairos_app/data/memory_repository.dart';
import 'package:kairos_app/data/repository.dart';
import 'package:kairos_app/data/secure_database.dart';
import 'package:kairos_core/kairos_core.dart';

final t0 = DateTime.utc(2026, 11, 1, 8);

void contract(String name, Future<KairosRepository> Function() make) {
  group('contrat du depot : $name', () {
    late KairosRepository repo;
    setUp(() async => repo = await make());

    test('profileId cree une seule fois', () async {
      var n = 0;
      final a = await repo.profileId(() => 'id-${++n}');
      final b = await repo.profileId(() => 'id-${++n}');
      expect(a, 'id-1');
      expect(b, 'id-1');
    });

    test('sauvegarde de partie : ecriture, relecture, ecrasement, effacement', () async {
      expect(await repo.loadSave('arc'), isNull);
      const s1 = GameState(arcId: 'arc', chapterId: 'c1', nodeId: 'n1', traits: {Trait.faith: 2}, flags: {'f'});
      await repo.writeSave(s1, t0);
      final back = await repo.loadSave('arc');
      expect(back!.toJson(), s1.toJson());
      await repo.writeSave(s1.copyWith(nodeId: 'n2'), t0);
      expect((await repo.loadSave('arc'))!.nodeId, 'n2');
      await repo.clearSave('arc');
      expect(await repo.loadSave('arc'), isNull);
    });

    test('progression par arc', () async {
      expect((await repo.loadProgress('arc')).completed, isEmpty);
      const p = ArcProgress(completed: {'c1'}, traits: {Trait.courage: 3}, flags: {'x'}, keys: {'GEN.39.9'});
      await repo.saveProgress('arc', p);
      expect((await repo.loadProgress('arc')).toJson(), p.toJson());
      expect((await repo.loadProgress('autre')).completed, isEmpty);
    });

    test('maitrise des versets', () async {
      expect(await repo.mastery('GEN.39.9'), isNull);
      final m = review(KeyMastery.fresh('GEN.39.9', t0), 5, t0).mastery;
      await repo.saveMastery(m);
      expect((await repo.mastery('GEN.39.9'))!.toJson(), m.toJson());
      await repo.saveMastery(m.copyWith(level: 3));
      expect((await repo.allMasteries()).single.level, 3);
    });

    test('Huile : valeur initiale puis persistance', () async {
      expect((await repo.loadLamp()).oil, 0);
      await repo.saveLamp(const LampState(oil: 50, streak: 2, lastMeditationDay: 7));
      final lamp = await repo.loadLamp();
      expect(lamp.oil, 50);
      expect(lamp.lastMeditationDay, 7);
    });

    test('Journal : plus recent d abord, aller-retour complet', () async {
      final a = JournalEntry.note(id: 'a', at: t0, text: 'ancienne');
      final b = JournalEntry.note(id: 'b', at: t0.add(const Duration(days: 1)), text: 'récente é');
      await repo.addJournalEntry(a);
      await repo.addJournalEntry(b);
      final entries = await repo.journalEntries();
      expect(entries.map((e) => e.id), ['b', 'a']);
      expect(entries.first.body, 'récente é');
    });
  });
}

void main() {
  // Les tests ouvrent volontairement de nombreuses bases independantes.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  contract('memoire', () async => MemoryRepository());
  contract('Drift (base en memoire)', () async => DriftRepository(AppDatabase(NativeDatabase.memory())));

  group('chiffrement SQLCipher', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('kairos_db_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('cle generee : 64 caracteres hexadecimaux, differente a chaque appel', () {
      final a = generateDatabaseKey();
      expect(a, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(generateDatabaseKey(), isNot(a));
    });

    test('cle invalide refusee avant toute ouverture', () {
      expect(() => openEncryptedDatabase(File('${dir.path}/x.db'), "abc'; DROP"), throwsArgumentError);
    });

    test('donnees relues avec la bonne cle, illisibles en clair sur le disque', () async {
      final file = File('${dir.path}/kairos.db');
      final key = generateDatabaseKey();

      var db = openEncryptedDatabase(file, key);
      var repo = DriftRepository(db);
      await repo.addJournalEntry(JournalEntry.note(id: 'n', at: t0, text: 'PRIERE-SECRETE-XYZ'));
      await db.close();

      // Rien d'identifiable dans les fichiers de la base (WAL inclus).
      for (final f in dir.listSync().whereType<File>()) {
        final bytes = f.readAsBytesSync();
        final text = String.fromCharCodes(bytes);
        expect(text.contains('PRIERE-SECRETE-XYZ'), isFalse, reason: f.path);
        expect(text.startsWith('SQLite format 3'), isFalse, reason: f.path);
      }

      db = openEncryptedDatabase(file, key);
      repo = DriftRepository(db);
      expect((await repo.journalEntries()).single.body, 'PRIERE-SECRETE-XYZ');
      await db.close();
    });

    test('mauvaise cle : ouverture refusee', () async {
      final file = File('${dir.path}/kairos.db');
      final db = openEncryptedDatabase(file, generateDatabaseKey());
      await DriftRepository(db).saveLamp(const LampState(oil: 10));
      await db.close();

      final wrong = openEncryptedDatabase(file, generateDatabaseKey());
      await expectLater(DriftRepository(wrong).loadLamp(), throwsA(anything));
      await wrong.close().catchError((Object _) {});
    });
  });
}
