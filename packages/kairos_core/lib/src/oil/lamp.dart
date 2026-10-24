/// L'Huile (Matthieu 25:1-13) : energie spirituelle rechargee uniquement par
/// la meditation quotidienne reelle (CDC §4.4, UC-04).
///
/// Regles : jamais achetable, jamais punitive (l'Huile ne reduit que les
/// bonus), anti-triche doux (duree minimale de lecture + comprehension).
/// Aucune horloge : le jour courant est fourni par l'appelant.
library;

import '../content/models.dart';

const maxOil = 100;
const oilPerMeditation = 50;
const oilDecayPerDay = 5;

/// Jours manques tolerables sans casser la serie (jour de grace).
const streakGraceDays = 1;

/// Une fiole d'or est offerte tous les 7 jours de serie.
const goldVialEvery = 7;

/// Duree minimale de lecture avant de pouvoir valider.
const minReadSeconds = 15;

/// Longueur minimale de la reflexion personnelle (hors espaces de bord).
const minReflectionChars = 10;

/// Numero de jour (jours depuis 1970) pour la date calendaire de [local].
///
/// On passe la date *locale* du joueur : le calcul retire l'heure et le
/// fuseau pour qu'un jour = une date, quelle que soit l'heure de la journee.
int dayNumber(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

class LampState {
  const LampState({
    this.oil = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.goldVials = 0,
    this.lastMeditationDay,
    this.lastUpdateDay,
  });

  factory LampState.fromJson(Map<String, Object?> json) => LampState(
        oil: json['oil']! as int,
        streak: json['streak']! as int,
        bestStreak: json['bestStreak']! as int,
        goldVials: json['goldVials']! as int,
        lastMeditationDay: json['lastMeditationDay'] as int?,
        lastUpdateDay: json['lastUpdateDay'] as int?,
      );

  final int oil;
  final int streak;
  final int bestStreak;
  final int goldVials;
  final int? lastMeditationDay;
  final int? lastUpdateDay;

  /// Multiplicateur de fruits : 1.0 (lampe vide) a 1.5 (lampe pleine).
  /// Jamais inferieur a 1 : la lampe vide ne penalise pas.
  double get fruitMultiplier => 1 + 0.5 * oil / maxOil;

  bool meditatedOn(int day) => lastMeditationDay == day;

  LampState copyWith({
    int? oil,
    int? streak,
    int? bestStreak,
    int? goldVials,
    int? lastMeditationDay,
    int? lastUpdateDay,
  }) =>
      LampState(
        oil: oil ?? this.oil,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        goldVials: goldVials ?? this.goldVials,
        lastMeditationDay: lastMeditationDay ?? this.lastMeditationDay,
        lastUpdateDay: lastUpdateDay ?? this.lastUpdateDay,
      );

  Map<String, Object?> toJson() => {
        'oil': oil,
        'streak': streak,
        'bestStreak': bestStreak,
        'goldVials': goldVials,
        'lastMeditationDay': lastMeditationDay,
        'lastUpdateDay': lastUpdateDay,
      };
}

/// Decroissance lente de l'Huile selon les jours ecoules, sans jamais passer
/// sous 0. Un retour en arriere de l'horloge ne change rien.
LampState applyDecay(LampState lamp, int today) {
  final last = lamp.lastUpdateDay;
  if (last == null) return lamp.copyWith(lastUpdateDay: today);
  final elapsed = today - last;
  if (elapsed <= 0) return lamp;
  final oil = lamp.oil - elapsed * oilDecayPerDay;
  return lamp.copyWith(oil: oil < 0 ? 0 : oil, lastUpdateDay: today);
}

class MeditationAttempt {
  const MeditationAttempt({
    required this.readSeconds,
    required this.answerIndex,
    required this.reflection,
  });

  final int readSeconds;

  /// Option choisie a la question de comprehension (null : aucune).
  final int? answerIndex;
  final String reflection;
}

enum MeditationRejection {
  /// Lecture trop rapide : inviter a relire, sans reproche.
  tooFast,

  /// Mauvaise reponse de comprehension : relire le passage et reessayer.
  wrongAnswer,

  /// Reflexion trop courte.
  reflectionTooShort,

  /// Deja medite aujourd'hui (ou horloge revenue en arriere).
  alreadyDone,
}

class MeditationResult {
  const MeditationResult(
    this.lamp, {
    this.rejection,
    this.goldVialEarned = false,
  });

  final LampState lamp;
  final MeditationRejection? rejection;
  final bool goldVialEarned;

  bool get accepted => rejection == null;
}

/// Valide une meditation pour [meditation] au jour [today].
///
/// L'Huile est rechargee, la serie mise a jour (un jour de grace est
/// tolere) et une fiole d'or offerte a chaque palier de [goldVialEvery].
/// L'appelant ecrit l'entree au Journal quand le resultat est accepte.
MeditationResult completeMeditation(
  LampState lamp,
  Meditation meditation,
  MeditationAttempt attempt,
  int today,
) {
  final last = lamp.lastMeditationDay;
  if (last != null && today <= last) {
    return MeditationResult(lamp, rejection: MeditationRejection.alreadyDone);
  }
  if (attempt.readSeconds < minReadSeconds) {
    return MeditationResult(lamp, rejection: MeditationRejection.tooFast);
  }
  if (attempt.answerIndex != meditation.answerIndex) {
    return MeditationResult(lamp, rejection: MeditationRejection.wrongAnswer);
  }
  if (attempt.reflection.trim().length < minReflectionChars) {
    return MeditationResult(lamp, rejection: MeditationRejection.reflectionTooShort);
  }

  final decayed = applyDecay(lamp, today);
  final keepsStreak = last != null && today - last <= 1 + streakGraceDays;
  final streak = keepsStreak ? decayed.streak + 1 : 1;
  final vial = streak % goldVialEvery == 0;
  final oil = decayed.oil + oilPerMeditation;
  return MeditationResult(
    decayed.copyWith(
      oil: oil > maxOil ? maxOil : oil,
      streak: streak,
      bestStreak: streak > decayed.bestStreak ? streak : decayed.bestStreak,
      goldVials: decayed.goldVials + (vial ? 1 : 0),
      lastMeditationDay: today,
      lastUpdateDay: today,
    ),
    goldVialEarned: vial,
  );
}

/// Passage du jour : parcourt les meditations de l'arc dans l'ordre,
/// de facon deterministe. Null si l'arc n'en definit aucune.
Meditation? meditationForDay(Arc arc, int day) {
  if (arc.meditations.isEmpty) return null;
  return arc.meditations[day % arc.meditations.length];
}
