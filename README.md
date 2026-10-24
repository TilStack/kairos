# KAIROS — Le Chemin du Disciple

Jeu mobile narratif d'éducation biblique (Flutter). Cahier des charges v1.0 + [avenant v1.1](docs/AVENANT_v1.1.md).

## État : Phase 0 — Fondations (terminée)

| Brique | Emplacement |
|---|---|
| Avenant au cahier des charges | `docs/AVENANT_v1.1.md` |
| Schéma de contenu (JSON Schema, pour l'édition) | `schema/arc.schema.json` |
| Arc de test (2 chapitres) | `content/test_arc/arc.json` |
| Moteur Dart pur | `packages/kairos_core` |

`kairos_core` ne dépend pas de Flutter : il se teste et se joue en console.

- `lib/src/verse` : normalisation, références bibliques, validation des Clés (niveaux 1, 2, 3, indices progressifs)
- `lib/src/srs` : répétition espacée SM-2 adaptée (repli de niveau après 3 échecs, jamais bloquant)
- `lib/src/content` : modèle d'arc, lecteur JSON strict, validateur de graphe et de références
- `lib/src/engine` : moteur narratif déterministe et état de partie sérialisable

## Commandes

Depuis `packages/kairos_core` :

```bash
dart pub get
dart analyze
dart test
dart run kairos_core:kairos_validate ../../content/test_arc
dart run kairos_core:kairos_play ../../content/test_arc/arc.json
```

`kairos_validate` retourne 0 (valide), 1 (arc invalide), 2 (usage). `--strict` fait échouer les avertissements.

## Règles de conception

- Le moteur est une fonction pure de `(arc, état)` : pas d'horloge ni d'aléa implicites (l'heure et la graine sont injectées).
- Le contenu est une donnée, jamais du code. Les clés JSON inconnues sont des erreurs.
- Une Porte n'est jamais bloquante.
- Le texte biblique de l'arc de test doit être relu contre une édition de référence de la LSG 1910 avant toute publication (comité théologique, CDC §9.5).

## Suite (Phase 1)

UI Flutter du lecteur narratif, stockage SQLCipher (clé dans le Keystore), signature Ed25519 des paquets, Journal chiffré.
