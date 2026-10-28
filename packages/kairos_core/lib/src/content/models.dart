/// Modele de contenu d'un arc KAIROS (voir `schema/arc.schema.json`).
///
/// Le contenu est purement declaratif : aucune logique narrative n'est
/// codee en dur, le moteur interprete ces structures.
library;

/// Version du moteur : un arc dont `minEngineVersion` est superieure est refuse.
const engineVersion = 1;

/// Version du format de contenu comprise par ce code.
const supportedSchemaVersion = 1;

/// Humeurs, actions, coiffes et accessoires admis pour les personnages.
/// Ce sont des noms stables du format de contenu : l'application les relie
/// a ses animations. Ajouter un nom ici suppose de l'implementer cote app.
const characterMoods = {'happy', 'neutral', 'wow', 'sad', 'think', 'sly'};
const characterActions = {'idle', 'wave', 'cheer', 'think', 'sad', 'point', 'walk', 'talk'};
const characterHeadwear = {'none', 'headband', 'turban', 'nemes', 'hood'};
const characterProps = {'none', 'staff', 'scroll', 'lamp'};

/// Lieux de mise en scene (decor choisi par l'application).
const sceneSettings = {'desert', 'house', 'palace', 'memory'};

/// Les six traits du coeur.
enum Trait { faith, courage, integrity, compassion, humility, wisdom }

/// Nature de l'anomalie d'une citation trompeuse.
enum AnomalyType {
  distorted('distorted'),
  truncated('truncated'),
  outOfContext('out_of_context'),
  misattributed('misattributed');

  const AnomalyType(this.id);
  final String id;

  static AnomalyType? fromId(String id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

class Range {
  const Range({this.min, this.max});
  final int? min;
  final int? max;

  bool contains(int value) =>
      (min == null || value >= min!) && (max == null || value <= max!);
}

/// Condition d'entree (toutes les clauses doivent etre vraies).
class Condition {
  const Condition({
    this.traits = const {},
    this.keys = const {},
    this.flags = const {},
    this.notFlags = const {},
  });

  final Map<Trait, Range> traits;

  /// Identifiants de versets dont la Cle doit etre forgee.
  final Set<String> keys;
  final Set<String> flags;
  final Set<String> notFlags;
}

/// Effets appliques par un choix ou a l'entree d'un noeud.
class Effects {
  const Effects({
    this.traits = const {},
    this.setFlags = const {},
    this.clearFlags = const {},
  });

  static const none = Effects();

  final Map<Trait, int> traits;
  final Set<String> setFlags;
  final Set<String> clearFlags;
}

/// Arete du graphe : premiere dont la condition est vraie.
class Transition {
  const Transition(this.to, [this.requires]);
  final String to;
  final Condition? requires;
}

class ChoiceOption {
  const ChoiceOption({
    required this.id,
    required this.text,
    required this.next,
    this.requires,
    this.effects = Effects.none,
  });

  final String id;
  final String text;
  final Condition? requires;
  final Effects effects;
  final List<Transition> next;
}

sealed class Node {
  const Node({
    required this.id,
    this.scene,
    this.refs = const [],
    this.effects = Effects.none,
    this.character,
    this.mood,
    this.action,
    this.setting,
  });

  final String id;

  /// Libelle de scene (regroupement editorial, sans effet sur le moteur).
  final String? scene;

  /// References bibliques liees au noeud (identifiants de versets).
  final List<String> refs;

  /// Effets appliques a l'entree dans le noeud.
  final Effects effects;

  /// Personnage mis en scene (identifiant dans `Arc.characters`), son humeur
  /// et son action. Purement visuels : sans effet sur le moteur.
  final String? character;
  final String? mood;
  final String? action;

  /// Lieu de la scene (voir [sceneSettings]) ; null : decor du noeud precedent.
  final String? setting;

  /// Aretes sortantes, vide pour les noeuds terminaux.
  Iterable<Transition> get outgoing;
}

class DialogueNode extends Node {
  const DialogueNode({
    required super.id,
    required this.text,
    required this.next,
    this.speaker,
    super.scene,
    super.refs,
    super.effects,
    super.character,
    super.mood,
    super.action,
    super.setting,
  });

  final String? speaker;
  final String text;
  final List<Transition> next;

  @override
  Iterable<Transition> get outgoing => next;
}

class ChoiceNode extends Node {
  const ChoiceNode({
    required super.id,
    required this.prompt,
    required this.options,
    super.scene,
    super.refs,
    super.effects,
    super.character,
    super.mood,
    super.action,
    super.setting,
  });

  final String prompt;
  final List<ChoiceOption> options;

  @override
  Iterable<Transition> get outgoing => options.expand((o) => o.next);
}

/// Porte : s'ouvre avec une Cle de la Parole (jamais bloquante).
class DoorNode extends Node {
  const DoorNode({
    required super.id,
    required this.prompt,
    required this.verse,
    required this.next,
    super.scene,
    super.refs,
    super.effects,
    super.character,
    super.mood,
    super.action,
    super.setting,
  });

  final String prompt;

  /// Identifiant du verset a memoriser.
  final String verse;
  final List<Transition> next;

  @override
  Iterable<Transition> get outgoing => next;
}

/// Defi de discernement : une « voix trompeuse » cite un verset deforme.
class DiscernmentNode extends Node {
  const DiscernmentNode({
    required super.id,
    required this.quote,
    required this.anomaly,
    required this.explanation,
    required this.next,
    this.speaker,
    this.claimedRef,
    this.correctRef,
    super.scene,
    super.refs,
    super.effects,
    super.character,
    super.mood,
    super.action,
    super.setting,
  });

  final String? speaker;
  final String quote;

  /// Reference que la voix trompeuse pretend citer (libre).
  final String? claimedRef;
  final AnomalyType anomaly;

  /// Identifiant du verset authentique a l'appui de l'explication.
  final String? correctRef;
  final String explanation;
  final List<Transition> next;

  @override
  Iterable<Transition> get outgoing => next;
}

/// Debriefing biblique de fin de chapitre.
class DebriefNode extends Node {
  const DebriefNode({
    required super.id,
    required this.teaching,
    required this.verses,
    required this.next,
    super.scene,
    super.refs,
    super.effects,
    super.character,
    super.mood,
    super.action,
    super.setting,
  });

  final String teaching;
  final List<String> verses;
  final List<Transition> next;

  @override
  Iterable<Transition> get outgoing => next;
}

/// Fin de chapitre.
class EndNode extends Node {
  const EndNode({
    required super.id,
    super.scene,
    super.refs,
    super.effects,
    super.character,
    super.mood,
    super.action,
    super.setting,
  });

  @override
  Iterable<Transition> get outgoing => const [];
}

/// Fiche d'apparence d'un personnage (couleurs en `#RRGGBB`).
class CharacterDef {
  const CharacterDef({
    required this.id,
    required this.name,
    required this.skin,
    required this.outfit,
    this.outfitAccent,
    this.stripes = const [],
    this.hair,
    this.beard,
    this.headwear = 'none',
    this.headwearColor,
    this.prop = 'none',
    this.flameHead = false,
    this.glowingEyes = false,
    this.glasses = false,
    this.scale = 1.0,
  });

  final String id;
  final String name;
  final String skin;
  final String outfit;
  final String? outfitAccent;
  final List<String> stripes;
  final String? hair;
  final String? beard;
  final String headwear;
  final String? headwearColor;
  final String prop;
  final bool flameHead;
  final bool glowingEyes;
  final bool glasses;
  final double scale;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.start,
    required this.nodes,
    this.theme,
  });

  final String id;
  final String title;
  final String? theme;
  final String start;
  final Map<String, Node> nodes;
}

class BibleVersionInfo {
  const BibleVersionInfo({
    required this.name,
    required this.license,
    this.attribution,
  });

  final String name;
  final String license;
  final String? attribution;
}

/// Passage de meditation quotidienne lie a l'arc (UC-04).
class Meditation {
  const Meditation({
    required this.id,
    required this.passage,
    required this.reflectionPrompt,
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  final String id;

  /// Identifiant du verset (ou de la plage) a lire.
  final String passage;

  /// Question de reflexion personnelle (reponse libre).
  final String reflectionPrompt;

  /// Question de comprehension douce.
  final String question;
  final List<String> options;
  final int answerIndex;
}

class Arc {
  const Arc({
    required this.schemaVersion,
    required this.id,
    required this.title,
    required this.version,
    required this.minEngineVersion,
    required this.defaultBible,
    required this.bibles,
    required this.verses,
    required this.chapters,
    this.meditations = const [],
    this.characters = const {},
  });

  final int schemaVersion;
  final String id;
  final String title;
  final String version;
  final int minEngineVersion;
  final String defaultBible;
  final Map<String, BibleVersionInfo> bibles;

  /// `verses[bibleId][verseId]` = texte exact.
  final Map<String, Map<String, String>> verses;
  final List<Chapter> chapters;
  final List<Meditation> meditations;

  /// Distribution : identifiant -> apparence.
  final Map<String, CharacterDef> characters;

  Chapter? chapter(String id) {
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Texte d'un verset dans une version, ou null.
  String? verseText(String verseId, {String? bible}) =>
      verses[bible ?? defaultBible]?[verseId];
}
