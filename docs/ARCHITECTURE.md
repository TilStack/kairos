# KAIROS — Architecture (état Phase 1)

## Organisation du dépôt

```
packages/kairos_core   Dart pur : verset, SRS, contenu, moteur, Huile, Journal (aucune dépendance Flutter)
apps/kairos_app        Application Flutter (Android)
content/test_arc       Arc de test (source) ; copie embarquée dans apps/kairos_app/assets
schema/                Schéma JSON d'édition des arcs
```

Règle : toute logique de jeu vit dans `kairos_core`, sans horloge ni aléa implicites ; l'application ne fait que la présenter et la persister.

## Couches de l'application

| Couche | Rôle |
|---|---|
| `features/*` | Écrans (lecteur, Portes, lampe, journal). Aucune règle de jeu. |
| `app/controllers.dart` | Contrôleurs Riverpod : orchestrent moteur + dépôt. Chaque action est persistée **avant** d'être affichée. |
| `data/repository.dart` | Interface d'accès aux données. Deux implémentations : Drift/SQLCipher (production) et mémoire (tests). |
| `data/secure_database.dart` | Ouverture de la base chiffrée et gestion de la clé. |

## Sécurité mise en œuvre

**Chiffrement au repos**
- Base SQLite chiffrée par **SQLCipher** (option `hooks.user_defines.sqlite3.source: sqlcipher` du `pubspec.yaml`).
- Clé : 32 octets aléatoires (`Random.secure`), conservée dans le **Keystore Android** via `flutter_secure_storage`. Jamais dans le code, jamais en clair sur le disque.
- La base refuse de s'ouvrir si SQLCipher est absent (`PRAGMA cipher_version` vide) : pas de repli silencieux vers une base en clair.
- Clé validée (64 caractères hexadécimaux) avant d'être placée dans le `PRAGMA key` : pas d'injection possible.
- Vérifié par test : mauvaise clé refusée ; aucun texte du Journal lisible dans les fichiers de la base.
- Mode WAL activé (écritures robustes à la coupure).

**Données hors de l'appareil**
- Sauvegarde cloud et transfert d'appareil désactivés (`allowBackup=false`, `dataExtractionRules`).
- Aucune permission réseau en version de production : la Phase 1 est entièrement hors ligne.

**Écran du Journal**
- `FLAG_SECURE` actif tant que le Journal est affiché : pas de capture d'écran, pas d'aperçu dans les applications récentes.

**Contenu**
- L'arc est validé au démarrage (schéma strict + graphe + références bibliques) ; un arc invalide arrête l'application avec un message clair.
- Le contenu est traité comme une donnée, jamais comme du code.

**Intégrité de la progression**
- Écriture atomique (transaction) de la sauvegarde, de la maîtrise du verset et du Journal à chaque nœud.
- Reprise exacte après fermeture brutale (testée).

## Limites connues de la Phase 1

- **Signature Ed25519 des paquets d'arcs** : non implémentée (l'arc est embarqué dans l'application). Obligatoire avant tout téléchargement d'arcs (Phase 3).
- **Perte de la clé Keystore** (données de l'application effacées, certains changements d'appareil) : la base devient illisible, par conception. La sauvegarde chiffrée optionnelle (avenant B-03) est le recours, non encore faite.
- **Signature de release** : la configuration de signature est encore celle de débogage. À remplacer par une clé de production avant publication.
- **Obfuscation** : à activer à la compilation de release (`--obfuscate --split-debug-info`).
- **Détection d'appareil rooté / intégrité de l'application** : non traitée ; sans effet sur le risque principal (données personnelles locales) tant qu'il n'y a pas de classement ni de serveur.
- **Anti-triche serveur, comptes, mineurs, consentement parental** : Phase 3.
