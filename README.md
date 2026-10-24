# KAIROS — Le Chemin du Disciple

Jeu mobile narratif d'éducation biblique (Flutter). Cahier des charges v1.0 + [avenant v1.1](docs/AVENANT_v1.1.md).
Architecture et sécurité : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## État

- **Phase 0 — Fondations : terminée** (moteur Dart pur, schéma, validateur CLI).
- **Phase 1 — Cœur de jeu : en cours** (voir ci-dessous).

| Brique | Emplacement |
|---|---|
| Moteur Dart pur (verset, SRS, contenu, narration, Huile, Journal, Portes) | `packages/kairos_core` |
| Application Flutter Android | `apps/kairos_app` |
| Schéma de contenu (JSON Schema, pour l'édition) | `schema/arc.schema.json` |
| Arc de test (2 chapitres, 3 méditations) | `content/test_arc/arc.json` |

### Phase 1 — livré
Lecteur narratif (reprise exacte après fermeture), Portes aux niveaux 1, 2 et 3 avec indices et repli, discernement avec explication, débriefing biblique, méditation et Huile (anti-triche doux), Journal chiffré (SQLCipher) avec notes libres.

### Phase 1 — pas encore fait
Signature Ed25519 des paquets, sauvegarde chiffrée optionnelle, notifications, arc Joseph complet (10 chapitres, contenu éditorial), tests sur appareil physique d'entrée de gamme.

## Commandes

Moteur (`packages/kairos_core`) :

```bash
dart pub get
dart analyze
dart test
dart run kairos_core:kairos_validate ../../content/test_arc
dart run kairos_core:kairos_play ../../content/test_arc/arc.json
```

Application (`apps/kairos_app`) :

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # après modification de lib/data/app_database.dart
flutter analyze
flutter test
flutter run
```

Après toute modification de `content/test_arc/arc.json`, recopier le fichier vers `apps/kairos_app/assets/arcs/joseph-test/arc.json` (un test vérifie que les deux sont identiques).

## Règles de conception

- Le moteur est une fonction pure de `(arc, état)` : pas d'horloge ni d'aléa implicites (l'heure et la graine sont injectées).
- Le contenu est une donnée, jamais du code. Les clés JSON inconnues sont des erreurs.
- Une Porte n'est jamais bloquante. L'Huile ne s'achète jamais et ne pénalise jamais.
- Le texte biblique de l'arc de test doit être relu contre une édition de référence de la LSG 1910 avant toute publication (comité théologique, CDC §9.5).
