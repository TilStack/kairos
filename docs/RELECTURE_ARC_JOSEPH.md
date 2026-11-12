# KAIROS — Arc « La Tunique et le Trône » : guide de relecture

Version du contenu : 0.9.0 (brouillon à relire). Texte biblique : Louis Segond 1910 (domaine public).

**Comment modifier :** éditer `content/joseph/arc.json`, puis recopier le fichier dans `apps/kairos_app/assets/arcs/joseph/arc.json` (un test vérifie que les deux sont identiques). Valider avec :

```
cd packages/kairos_core
dart run bin/kairos_validate.dart --strict ../../content/joseph/arc.json
```

## À vérifier en priorité

- **Versets** : 15 versets LSG 1910, récupérés d'une source en ligne puis normalisés (apostrophes, espaces avant « : »). Les 4 versets déjà présents dans l'arc de test sont identiques à la source. À comparer avec votre Bible papier avant diffusion.
- **Dialogues** : paraphrases du récit de Genèse 37 à 50, écrites pour être courtes et lisibles. Les citations directes de personnages bibliques restent proches du texte, mais ce sont des reformulations.
- **Défis de discernement** : 10 citations « piégées » du Murmure. Pour chacune, vérifier que l'explication est théologiquement juste.
- **Choix du joueur** : aucun choix n'est « mauvais » (principe du jeu), chaque option donne un trait du cœur.

## Les 10 chapitres

### 1. Le rêveur — *Humilité*

- Identifiant : `ch1-reveur` — 10 nœuds
- Porte (verset à mémoriser) : `PRO.16.18`
- Discernement (distorted) : « Ne t'en fais pas : « L'orgueil précède la gloire ». Joseph a bien raison de se montrer fier ! » — attribué à *Proverbes 16:18*

### 2. La citerne — *Jalousie et compassion*

- Identifiant : `ch2-citerne` — 11 nœuds
- Porte (verset à mémoriser) : `PRO.14.30`
- Discernement (truncated) : « Calme-toi : « Un cœur calme est la vie du corps. » Ne te mêle pas de ces histoires entre frères ! » — attribué à *Proverbes 14:30*

### 3. Dans la maison de Potiphar — *Intégrité*

- Identifiant : `ch3-potiphar` — 9 nœuds
- Porte (verset à mémoriser) : `GEN.39.9`
- Discernement (misattributed) : « Tu sais, il faut rester pragmatique : la Bible elle-même dit que « Dieu aide ceux qui s'aident ». » — attribué à *Proverbes 3:5*

### 4. La prison — *Dieu est avec nous dans l'épreuve*

- Identifiant : `ch4-prison` — 10 nœuds
- Porte (verset à mémoriser) : `GEN.39.21`
- Discernement (out_of_context) : « Courage : Dieu ne nous envoie jamais plus d'épreuves que nous ne pouvons en porter. C'est promis dans 1 Corinthiens 10:13. » — attribué à *1 Corinthiens 10:13*

### 5. Les songes de Pharaon — *Humilité devant Dieu*

- Identifiant : `ch5-songes` — 9 nœuds
- Porte (verset à mémoriser) : `GEN.41.16`
- Discernement (misattributed) : « Un sage d'Égypte te le dirait : « Les rêves disent toujours la vérité ». C'est écrit dans les Proverbes. » — attribué à *Proverbes 16:33*

### 6. Gouverneur d'Égypte — *Sagesse et service*

- Identifiant : `ch6-gouverneur` — 9 nœuds
- Porte (verset à mémoriser) : `GEN.41.52`
- Discernement (truncated) : « Même la Bible dit : « Si quelqu'un d'entre vous manque de sagesse, qu'il la demande. » Alors demande-la aux hommes : Joseph sait tout ! » — attribué à *Jacques 1:5*

### 7. Les frères en Égypte — *Vérité et conscience*

- Identifiant : `ch7-freres` — 12 nœuds
- Porte (verset à mémoriser) : `PRO.28.13`
- Discernement (distorted) : « « Celui qui cache ses transgressions prospère. » Ne dis rien : ce que personne ne sait n'existe pas. » — attribué à *Proverbes 28:13*

### 8. La coupe d'argent — *L'amour qui se donne*

- Identifiant : `ch8-coupe` — 11 nœuds
- Porte (verset à mémoriser) : `JHN.15.13`
- Discernement (out_of_context) : « Œil pour œil, dent pour dent ! La Bible le dit : Joseph a le droit de les punir comme ils le méritent. » — attribué à *Exode 21:24*

### 9. Je suis Joseph — *Dieu conduit l'histoire*

- Identifiant : `ch9-reconnaissance` — 10 nœuds
- Porte (verset à mémoriser) : `GEN.45.5`
- Discernement (misattributed) : « Joseph a tout effacé de sa mémoire, comme la Bible le dit : « Pardonne et oublie ». » — attribué à *Genèse 45:5*

### 10. Le pardon — *Pardon et souveraineté de Dieu*

- Identifiant : `ch10-pardon` — 12 nœuds
- Porte (verset à mémoriser) : `GEN.50.20`
- Discernement (out_of_context) : « Tu vois bien : « toutes choses concourent au bien ». Alors le mal que nous avons fait n'a finalement pas d'importance. » — attribué à *Romains 8:28*

## Pas encore faits
- Représentation de l'épouse de Potiphar : elle n'apparaît pas, on en parle seulement (à valider).
- Dieu et Jésus ne sont jamais dessinés.
- Relecture théologique (comité).
