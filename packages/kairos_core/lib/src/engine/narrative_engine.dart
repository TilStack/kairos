import '../content/models.dart';
import '../verse/bible_ref.dart';
import 'game_state.dart';

/// Erreur d'usage du moteur (appel incompatible avec le noeud courant).
class EngineException implements Exception {
  EngineException(this.message);
  final String message;

  @override
  String toString() => 'EngineException: $message';
}

/// Ce que l'interface doit presenter pour l'etat courant.
sealed class Step {
  const Step(this.node);
  final Node node;
}

class DialogueStep extends Step {
  const DialogueStep(DialogueNode super.node);
  @override
  DialogueNode get node => super.node as DialogueNode;
}

class ChoiceStep extends Step {
  const ChoiceStep(ChoiceNode super.node, this.options);
  @override
  ChoiceNode get node => super.node as ChoiceNode;

  /// Options visibles (celles dont la condition est remplie).
  final List<ChoiceOption> options;
}

class DoorStep extends Step {
  const DoorStep(DoorNode super.node, {required this.alreadyForged});
  @override
  DoorNode get node => super.node as DoorNode;

  /// La Cle est deja forgee : proposer une revision express.
  final bool alreadyForged;
}

class DiscernmentStep extends Step {
  const DiscernmentStep(DiscernmentNode super.node);
  @override
  DiscernmentNode get node => super.node as DiscernmentNode;
}

class VerseText {
  const VerseText(this.id, this.label, this.text);
  final String id;
  final String label;

  /// Texte exact de la version choisie, null si absent de la table.
  final String? text;
}

class DebriefStep extends Step {
  const DebriefStep(DebriefNode super.node, this.verses, this.traits);
  @override
  DebriefNode get node => super.node as DebriefNode;
  final List<VerseText> verses;

  /// Traits du coeur reveles au debriefing.
  final Map<Trait, int> traits;
}

class EndStep extends Step {
  const EndStep(EndNode super.node);
}

class DiscernmentResult {
  const DiscernmentResult(this.state, {required this.correct});
  final GameState state;
  final bool correct;
}

/// Interprete le graphe narratif d'un arc.
///
/// Totalement deterministe : le resultat ne depend que de l'arc et de
/// l'etat. Aucune logique narrative n'est codee en dur.
class NarrativeEngine {
  const NarrativeEngine(this.arc);

  final Arc arc;

  /// Demarre un chapitre. [keys] : Cles deja forgees ; [traits] : traits
  /// reportes des chapitres precedents.
  GameState start(
    String chapterId, {
    Set<String> keys = const {},
    Map<Trait, int> traits = const {},
    Set<String> flags = const {},
  }) {
    final chapter = _chapter(chapterId);
    final initial = GameState(
      arcId: arc.id,
      chapterId: chapterId,
      nodeId: chapter.start,
      traits: traits,
      flags: flags,
      keys: keys,
    );
    return _enter(initial, chapter.start);
  }

  /// Description du noeud courant pour l'interface.
  Step view(GameState state, {String? bible}) {
    final node = _node(state);
    return switch (node) {
      DialogueNode() => DialogueStep(node),
      ChoiceNode() => ChoiceStep(node, visibleOptions(state, node)),
      DoorNode() => DoorStep(node, alreadyForged: state.keys.contains(node.verse)),
      DiscernmentNode() => DiscernmentStep(node),
      DebriefNode() => DebriefStep(
          node,
          [
            for (final id in node.verses)
              VerseText(id, _label(id), arc.verseText(id, bible: bible)),
          ],
          state.traits,
        ),
      EndNode() => EndStep(node),
    };
  }

  /// Options de [node] visibles pour [state].
  List<ChoiceOption> visibleOptions(GameState state, ChoiceNode node) => [
        for (final o in node.options)
          if (o.requires == null || conditionMet(o.requires!, state)) o,
      ];

  /// Passe un dialogue ou un debriefing.
  GameState advance(GameState state) {
    final node = _node(state);
    return switch (node) {
      DialogueNode() => _follow(state, node.next),
      DebriefNode() => _follow(state, node.next),
      _ => throw EngineException(
          'advance impossible sur un noeud ${node.runtimeType} (${node.id})'),
    };
  }

  /// Choisit une option visible.
  GameState choose(GameState state, String optionId) {
    final node = _node(state);
    if (node is! ChoiceNode) {
      throw EngineException('choose impossible : ${node.id} n\'est pas un choix');
    }
    final option = visibleOptions(state, node)
        .where((o) => o.id == optionId)
        .firstOrNull;
    if (option == null) {
      throw EngineException('option "$optionId" indisponible sur ${node.id}');
    }
    final applied = _apply(state, option.effects).copyWith(
      choices: [...state.choices, ChoiceRecord(node.id, option.id)],
    );
    return _follow(applied, option.next);
  }

  /// Resout une Porte. Elle n'est jamais bloquante : le recit continue que
  /// la Cle ait ete forgee ou non (l'echec est consigne par un drapeau).
  GameState resolveDoor(GameState state, {required bool forged}) {
    final node = _node(state);
    if (node is! DoorNode) {
      throw EngineException('resolveDoor impossible : ${node.id} n\'est pas une porte');
    }
    final next = forged
        ? state.copyWith(keys: {...state.keys, node.verse})
        : state.copyWith(flags: {...state.flags, 'door_skipped:${node.verse}'});
    return _follow(next, node.next);
  }

  /// Repond a un defi de discernement. [answer] : nature de l'anomalie.
  DiscernmentResult answerDiscernment(GameState state, AnomalyType answer) {
    final node = _node(state);
    if (node is! DiscernmentNode) {
      throw EngineException('answerDiscernment impossible : ${node.id} n\'est pas un defi');
    }
    final correct = answer == node.anomaly;
    final recorded = state.copyWith(
      discernments: [...state.discernments, DiscernmentRecord(node.id, correct: correct)],
    );
    return DiscernmentResult(_follow(recorded, node.next), correct: correct);
  }

  /// Une condition est-elle remplie dans cet etat ?
  bool conditionMet(Condition c, GameState state) {
    for (final e in c.traits.entries) {
      if (!e.value.contains(state.trait(e.key))) return false;
    }
    return c.keys.every(state.keys.contains) &&
        c.flags.every(state.flags.contains) &&
        c.notFlags.every((f) => !state.flags.contains(f));
  }

  // -------------------------------------------------------------- interne

  Chapter _chapter(String id) {
    final chapter = arc.chapter(id);
    if (chapter == null) throw EngineException('chapitre inconnu "$id"');
    return chapter;
  }

  Node _node(GameState state) {
    if (state.arcId != arc.id) {
      throw EngineException('sauvegarde d\'un autre arc (${state.arcId})');
    }
    final node = _chapter(state.chapterId).nodes[state.nodeId];
    if (node == null) {
      throw EngineException('noeud inconnu "${state.nodeId}" (contenu mis a jour ?)');
    }
    return node;
  }

  GameState _follow(GameState state, List<Transition> next) {
    for (final t in next) {
      if (t.requires == null || conditionMet(t.requires!, state)) {
        return _enter(state, t.to);
      }
    }
    throw EngineException(
        'aucune transition applicable depuis ${state.nodeId} '
        '(le validateur exige une transition par defaut)');
  }

  GameState _enter(GameState state, String nodeId) {
    final node = _chapter(state.chapterId).nodes[nodeId];
    if (node == null) throw EngineException('noeud inconnu "$nodeId"');
    final moved = _apply(state.copyWith(nodeId: nodeId), node.effects);
    return node is EndNode ? moved.copyWith(finished: true) : moved;
  }

  GameState _apply(GameState state, Effects effects) {
    if (identical(effects, Effects.none)) return state;
    final traits = {...state.traits};
    for (final e in effects.traits.entries) {
      traits[e.key] = ((traits[e.key] ?? 0) + e.value).clamp(0, traitMax);
    }
    final flags = {...state.flags, ...effects.setFlags}..removeAll(effects.clearFlags);
    return state.copyWith(traits: traits, flags: flags);
  }

  String _label(String verseId) => BibleRef.tryParse(verseId)?.label ?? verseId;
}
