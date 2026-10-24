/// Repetition espacee SM-2 adaptee aux Cles de la Parole.
///
/// Adaptations par rapport a SM-2 : trois niveaux de difficulte (1 a 3),
/// repli automatique d'un niveau apres trois echecs consecutifs (la Porte
/// n'est jamais bloquante) et horloge injectee (aucun appel a `DateTime.now`).
library;

const minEase = 1.3;
const defaultEase = 2.5;
const maxLevel = 3;
const failuresBeforeFallback = 3;

/// Etat de maitrise d'un verset.
class KeyMastery {
  const KeyMastery({
    required this.verseRef,
    required this.due,
    this.level = 1,
    this.ease = defaultEase,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.consecutiveFails = 0,
    this.forged = false,
  });

  factory KeyMastery.fromJson(Map<String, Object?> json) => KeyMastery(
        verseRef: json['verseRef']! as String,
        due: DateTime.parse(json['due']! as String).toUtc(),
        level: json['level']! as int,
        ease: (json['ease']! as num).toDouble(),
        intervalDays: json['intervalDays']! as int,
        repetitions: json['repetitions']! as int,
        consecutiveFails: json['consecutiveFails']! as int,
        forged: json['forged']! as bool,
      );

  /// Nouvelle Cle a travailler, a reviser immediatement.
  factory KeyMastery.fresh(String verseRef, DateTime now) =>
      KeyMastery(verseRef: verseRef, due: now.toUtc());

  final String verseRef;
  final DateTime due;
  final int level;
  final double ease;
  final int intervalDays;
  final int repetitions;
  final int consecutiveFails;

  /// Vrai des qu'une reussite au niveau 3 a eu lieu : la Cle est forgee.
  final bool forged;

  bool isDue(DateTime now) => !now.toUtc().isBefore(due);

  KeyMastery copyWith({
    DateTime? due,
    int? level,
    double? ease,
    int? intervalDays,
    int? repetitions,
    int? consecutiveFails,
    bool? forged,
  }) =>
      KeyMastery(
        verseRef: verseRef,
        due: due ?? this.due,
        level: level ?? this.level,
        ease: ease ?? this.ease,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        consecutiveFails: consecutiveFails ?? this.consecutiveFails,
        forged: forged ?? this.forged,
      );

  Map<String, Object?> toJson() => {
        'verseRef': verseRef,
        'due': due.toUtc().toIso8601String(),
        'level': level,
        'ease': ease,
        'intervalDays': intervalDays,
        'repetitions': repetitions,
        'consecutiveFails': consecutiveFails,
        'forged': forged,
      };
}

/// Resultat d'une revision.
class ReviewOutcome {
  const ReviewOutcome(this.mastery, {this.fellBack = false, this.promoted = false});

  final KeyMastery mastery;

  /// Trois echecs consecutifs : le niveau a ete abaisse.
  final bool fellBack;

  /// Reussite nette : le niveau a ete releve.
  final bool promoted;
}

/// Qualite SM-2 (0 a 5) deduite d'une tentative.
int qualityFromAttempt({
  required bool correct,
  required int hintsUsed,
  double accuracy = 1,
}) {
  if (!correct) return accuracy >= 0.5 ? 2 : (accuracy > 0 ? 1 : 0);
  if (hintsUsed == 0) return 5;
  if (hintsUsed == 1) return 4;
  return 3;
}

/// Applique une revision de qualite [quality] (0 a 5) a [m] a l'instant [now].
ReviewOutcome review(KeyMastery m, int quality, DateTime now) {
  assert(quality >= 0 && quality <= 5, 'quality hors bornes');
  final at = now.toUtc();

  if (quality < 3) {
    final fails = m.consecutiveFails + 1;
    final fallback = fails >= failuresBeforeFallback && m.level > 1;
    final reset = fails >= failuresBeforeFallback;
    return ReviewOutcome(
      m.copyWith(
        repetitions: 0,
        intervalDays: 1,
        ease: _clampEase(m.ease - 0.2),
        consecutiveFails: reset ? 0 : fails,
        level: fallback ? m.level - 1 : m.level,
        due: at.add(const Duration(days: 1)),
      ),
      fellBack: fallback,
    );
  }

  final reps = m.repetitions + 1;
  final interval = reps == 1
      ? 1
      : (reps == 2 ? 6 : (m.intervalDays * m.ease).round());
  final delta = 5 - quality;
  final ease = _clampEase(m.ease + 0.1 - delta * (0.08 + delta * 0.02));
  final promoted = quality >= 4 && m.level < maxLevel;
  return ReviewOutcome(
    m.copyWith(
      repetitions: reps,
      intervalDays: interval,
      ease: ease,
      consecutiveFails: 0,
      level: promoted ? m.level + 1 : m.level,
      forged: m.forged || m.level == maxLevel,
      due: at.add(Duration(days: interval)),
    ),
    promoted: promoted,
  );
}

double _clampEase(double ease) => ease < minEase ? minEase : ease;

/// Cles a reviser a l'instant [now], les plus en retard d'abord.
List<KeyMastery> dueKeys(Iterable<KeyMastery> all, DateTime now) {
  final due = all.where((k) => k.isDue(now)).toList()
    ..sort((a, b) => a.due.compareTo(b.due));
  return due;
}
