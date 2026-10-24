import '../content/models.dart';

/// Borne haute d'un trait du coeur (la borne basse est 0).
const traitMax = 100;

class ChoiceRecord {
  const ChoiceRecord(this.nodeId, this.optionId);

  factory ChoiceRecord.fromJson(Map<String, Object?> json) =>
      ChoiceRecord(json['nodeId']! as String, json['optionId']! as String);

  final String nodeId;
  final String optionId;

  Map<String, Object?> toJson() => {'nodeId': nodeId, 'optionId': optionId};
}

class DiscernmentRecord {
  const DiscernmentRecord(this.nodeId, {required this.correct});

  factory DiscernmentRecord.fromJson(Map<String, Object?> json) =>
      DiscernmentRecord(json['nodeId']! as String, correct: json['correct']! as bool);

  final String nodeId;
  final bool correct;

  Map<String, Object?> toJson() => {'nodeId': nodeId, 'correct': correct};
}

/// Etat de partie : immuable, serialisable, sans horloge ni aleatoire.
/// Persiste a chaque noeud (RF-01).
class GameState {
  const GameState({
    required this.arcId,
    required this.chapterId,
    required this.nodeId,
    this.traits = const {},
    this.flags = const {},
    this.keys = const {},
    this.choices = const [],
    this.discernments = const [],
    this.finished = false,
  });

  factory GameState.fromJson(Map<String, Object?> json) => GameState(
        arcId: json['arcId']! as String,
        chapterId: json['chapterId']! as String,
        nodeId: json['nodeId']! as String,
        traits: {
          for (final e in (json['traits']! as Map<String, Object?>).entries)
            Trait.values.byName(e.key): e.value! as int,
        },
        flags: {...(json['flags']! as List<Object?>).cast<String>()},
        keys: {...(json['keys']! as List<Object?>).cast<String>()},
        choices: [
          for (final c in json['choices']! as List<Object?>)
            ChoiceRecord.fromJson(c! as Map<String, Object?>),
        ],
        discernments: [
          for (final d in json['discernments']! as List<Object?>)
            DiscernmentRecord.fromJson(d! as Map<String, Object?>),
        ],
        finished: json['finished']! as bool,
      );

  final String arcId;
  final String chapterId;
  final String nodeId;
  final Map<Trait, int> traits;
  final Set<String> flags;

  /// Verset dont la Cle est forgee.
  final Set<String> keys;
  final List<ChoiceRecord> choices;
  final List<DiscernmentRecord> discernments;
  final bool finished;

  int trait(Trait t) => traits[t] ?? 0;

  GameState copyWith({
    String? nodeId,
    Map<Trait, int>? traits,
    Set<String>? flags,
    Set<String>? keys,
    List<ChoiceRecord>? choices,
    List<DiscernmentRecord>? discernments,
    bool? finished,
  }) =>
      GameState(
        arcId: arcId,
        chapterId: chapterId,
        nodeId: nodeId ?? this.nodeId,
        traits: traits ?? this.traits,
        flags: flags ?? this.flags,
        keys: keys ?? this.keys,
        choices: choices ?? this.choices,
        discernments: discernments ?? this.discernments,
        finished: finished ?? this.finished,
      );

  Map<String, Object?> toJson() => {
        'arcId': arcId,
        'chapterId': chapterId,
        'nodeId': nodeId,
        // Ordre trie : une meme partie donne toujours le meme JSON.
        'traits': {
          for (final t in Trait.values)
            if (traits.containsKey(t)) t.name: traits[t],
        },
        'flags': flags.toList()..sort(),
        'keys': keys.toList()..sort(),
        'choices': [for (final c in choices) c.toJson()],
        'discernments': [for (final d in discernments) d.toJson()],
        'finished': finished,
      };
}
