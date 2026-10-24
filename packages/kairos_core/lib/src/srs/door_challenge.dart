/// Defi de Porte (UC-02) : un verset a travailler a un niveau donne, avec
/// essais limites, indices progressifs et garantie de non-blocage.
library;

import '../verse/verse_check.dart';
import 'sm2.dart';

enum DoorStatus { inProgress, forged, exhausted }

class AttemptResult {
  const AttemptResult({
    required this.correct,
    required this.status,
    required this.attemptsLeft,
    this.hint,
    this.gapResults,
    this.wordErrors = const [],
  });

  final bool correct;
  final DoorStatus status;
  final int attemptsLeft;

  /// Indice a afficher apres un echec (progressif).
  final String? hint;

  /// Niveau 2 : reussite de chaque trou.
  final List<bool>? gapResults;

  /// Niveau 3 : erreurs de mots relevees.
  final List<WordError> wordErrors;
}

/// Session de travail d'un verset. Pure : ne depend d'aucune horloge.
///
/// La Porte n'est jamais bloquante : apres [failuresBeforeFallback] echecs,
/// le statut devient [DoorStatus.exhausted] et le recit continue ; la
/// maitrise redescend d'un niveau via [outcome].
class DoorChallenge {
  DoorChallenge({
    required this.verse,
    required this.verseId,
    required this.level,
    required this.seed,
    this.tolerance = Tolerance.normal,
  })  : assert(level >= 1 && level <= maxLevel),
        _scramble = scrambleVerse(verse, seed: seed),
        _gaps = makeGaps(verse, seed: seed);

  final String verse;
  final String verseId;
  final int level;
  final int seed;
  final Tolerance tolerance;

  final List<String> _scramble;
  final GapExercise _gaps;

  int _attempts = 0;
  int _hints = 0;
  double _lastAccuracy = 0;
  DoorStatus _status = DoorStatus.inProgress;

  DoorStatus get status => _status;
  int get attempts => _attempts;
  int get hintsUsed => _hints;
  int get attemptsLeft => failuresBeforeFallback - _attempts;

  /// Niveau 1 : mots melanges a remettre en ordre.
  List<String> get scrambled => _scramble;

  /// Niveau 2 : verset a trous.
  GapExercise get gaps => _gaps;

  AttemptResult submitOrder(List<String> arranged) =>
      _record(checkOrder(verse, arranged));

  AttemptResult submitGaps(List<String> answers) {
    final each = checkGaps(_gaps, answers, tolerance: tolerance);
    return _record(each.every((b) => b), gapResults: each);
  }

  /// Niveau 3 : verset ET reference saisis sans aide.
  AttemptResult submitRecall(String text, String reference) {
    final recall = checkRecall(verse, text, tolerance: tolerance);
    final refOk = checkReference(verseId, reference);
    return _record(recall.accepted && refOk, wordErrors: recall.errors, accuracy: recall.accuracy);
  }

  AttemptResult _record(
    bool correct, {
    List<bool>? gapResults,
    List<WordError> wordErrors = const [],
    double? accuracy,
  }) {
    if (_status != DoorStatus.inProgress) {
      throw StateError('defi deja termine');
    }
    _attempts++;
    _lastAccuracy = accuracy ?? (correct ? 1 : 0);
    if (correct) {
      _status = DoorStatus.forged;
    } else {
      _hints++;
      if (_attempts >= failuresBeforeFallback) _status = DoorStatus.exhausted;
    }
    return AttemptResult(
      correct: correct,
      status: _status,
      attemptsLeft: attemptsLeft < 0 ? 0 : attemptsLeft,
      hint: correct ? null : progressiveHint(verse, _hints),
      gapResults: gapResults,
      wordErrors: wordErrors,
    );
  }

  /// Nouvelle maitrise une fois le defi termine.
  ///
  /// Trois essais consecutifs rates (UC-02 4b) font redescendre d'un niveau
  /// (jamais sous 1) : la prochaine Porte sur ce verset sera plus facile.
  /// L'echec ne compte qu'une fois dans SM-2, sans double repli.
  ReviewOutcome outcome(KeyMastery mastery, DateTime now) {
    if (_status == DoorStatus.inProgress) {
      throw StateError('defi non termine');
    }
    final forged = _status == DoorStatus.forged;
    final reviewed = review(
      mastery,
      qualityFromAttempt(correct: forged, hintsUsed: _hints, accuracy: _lastAccuracy),
      now,
    );
    if (forged) return reviewed;
    final lowered = mastery.level > 1 ? mastery.level - 1 : 1;
    return ReviewOutcome(
      reviewed.mastery.copyWith(level: lowered, consecutiveFails: 0),
      fellBack: mastery.level > 1,
    );
  }
}
