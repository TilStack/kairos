# KAIROS — Avenant v1.1 au cahier des charges v1.0

Statut : validé par le porteur du projet. Priorités MoSCoW (cf. §13 du CDC : tout ajout passe par avenant).

## A. Corrections

| Réf. | Correction | Priorité |
|---|---|---|
| A-01 | **Anti-triche** : le HMAC du journal d'événements ne protège que contre la corruption locale (la clé est extractible de l'APK). L'anti-triche repose sur la **validation serveur** (rejeu des événements, contrôle de plausibilité). Remplace la formulation de §9.3 et RF-10. | M |
| A-02 | **Invité / compte / Cellule** : tout joueur possède un `profileId` (UUID v4) dès le premier lancement. À la création du compte, le journal d'événements du profil local est rattaché au compte (migration sans perte). Remplace UC-08 §1a. | M |
| A-03 | **Mineurs et conformité** : date de naissance demandée à l'inscription ; consentement parental pour les moins de 16 ans ; politique de confidentialité ; conformité Google Play « Families ». Complète §9.4. | M |
| A-04 | **Budgets de poids** : budget par type de ressource (textes, images WebP, audio) mesuré en CI ; Android App Bundle ; mesure sur appareil 2 Go dès la Phase 1. Précise §9.2. | M |
| A-05 | **Niveau 3 des Clés remonté dans le MVP** (cohérence avec l'indicateur « 15 versets niveau 3 », §2.3). RF-03 : M pour les niveaux 1, 2 et 3. | M |
| A-06 | **Textes bibliques multi-versions** : table de versets par version avec champs `license` et `attribution`. LSG 1910 (domaine public) en référence. | M |
| A-07 | **Talents** : à ce stade, les Talents **se gagnent uniquement en jouant** (aucun achat en argent réel). Tout achat éventuel fera l'objet d'un avenant dédié (règles des stores, paiement local). | M |

## B. Ajouts

| Réf. | Ajout | Priorité |
|---|---|---|
| B-01 | Paiements locaux (Mobile Money MTN / Orange) — étude avant la Phase 4. | S |
| B-02 | Notifications FCM + gestion des constructeurs qui tuent les tâches de fond (Tecno, Infinix, Xiaomi). | M |
| B-03 | Sauvegarde du Journal optionnelle, chiffrée de bout en bout, déclenchée par le joueur. | S |
| B-04 | Suppression de compte et export des données personnelles. | M |
| B-05 | Mesure d'usage respectueuse de la vie privée (sans identifiant publicitaire). | S |
| B-06 | `minEngineVersion` dans le manifeste d'arc : un ancien client refuse proprement un arc trop récent. | M |
| B-07 | Écritures SQLite transactionnelles (WAL), reprise après coupure franche. | M |

## C. Décisions techniques de la Phase 0

- Monorepo ; le moteur vit dans `packages/kairos_core`, **Dart pur** (aucune dépendance Flutter).
- Contenu = JSON versionné (`schemaVersion`), schéma publié dans `schema/arc.schema.json`.
- Le moteur est déterministe : aucune horloge ni aléa implicite (l'horloge et la graine sont injectées).
- Signature Ed25519 des paquets et chiffrement SQLCipher : Phase 1 / 3 (hors Phase 0).
