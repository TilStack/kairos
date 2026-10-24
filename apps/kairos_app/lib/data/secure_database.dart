import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

const _keyName = 'kairos_db_key_v1';

final _hexKey = RegExp(r'^[0-9a-f]{64}$');

/// Cle SQLCipher : 32 octets aleatoires, gardee dans le Keystore Android
/// (jamais dans le code ni dans les preferences en clair).
///
/// Si la cle est perdue (donnees de l'appli effacees), la base chiffree
/// devient illisible : c'est voulu, la sauvegarde optionnelle (avenant B-03)
/// est le recours.
abstract class DatabaseKeyStore {
  Future<String> getOrCreateKey();
}

class SecureStorageKeyStore implements DatabaseKeyStore {
  SecureStorageKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      if (!_hexKey.hasMatch(existing)) {
        throw StateError('cle de base corrompue dans le stockage securise');
      }
      return existing;
    }
    final created = generateDatabaseKey();
    await _storage.write(key: _keyName, value: created);
    return created;
  }
}

/// 64 caracteres hexadecimaux issus d'un generateur cryptographique.
String generateDatabaseKey([Random? random]) {
  final rng = random ?? Random.secure();
  return List.generate(32, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// Ouvre (ou cree) la base chiffree [file] avec la cle hexadecimale [hexKey].
///
/// Echoue explicitement si SQLCipher n'est pas present (sinon la base serait
/// ecrite en clair sans que personne ne le sache) ou si la cle est mauvaise.
AppDatabase openEncryptedDatabase(File file, String hexKey) {
  if (!_hexKey.hasMatch(hexKey)) {
    throw ArgumentError('cle de base invalide (64 caracteres hexadecimaux attendus)');
  }
  return AppDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (db) {
        if (db.select('PRAGMA cipher_version;').isEmpty) {
          throw StateError('SQLCipher indisponible : refus d\'ouvrir une base en clair');
        }
        // Cle brute (sans derivation) : le format x'..' est valide car
        // hexKey a ete verifiee ci-dessus.
        db.execute("PRAGMA key = \"x'$hexKey'\";");
        db.execute('PRAGMA journal_mode = WAL;'); // avenant B-07
        db.select('SELECT count(*) FROM sqlite_master;'); // echoue si mauvaise cle
      },
    ),
  );
}

/// Base de production : fichier prive de l'application, cle du Keystore.
Future<AppDatabase> openProductionDatabase(DatabaseKeyStore keys) async {
  final dir = await getApplicationSupportDirectory();
  final key = await keys.getOrCreateKey();
  return openEncryptedDatabase(File(p.join(dir.path, 'kairos.db')), key);
}
