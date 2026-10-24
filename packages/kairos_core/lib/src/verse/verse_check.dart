import 'dart:math';

import 'bible_ref.dart';
import 'normalize.dart';

/// Niveau de tolerance aux fautes de frappe (par mot).
enum Tolerance {
  /// Mot identique apres normalisation.
  strict(0),

  /// 1 faute pour les mots de 4 a 6 lettres, 2 au-dela de 6.
  normal(0),

  /// Comme [normal] avec une faute de plus par palier.
  lenient(1);

  const Tolerance(this._bonus);
  final int _bonus;

  /// Nombre de fautes admises pour un mot de [length] lettres.
  int allowedEdits(int length) {
    if (this == Tolerance.strict || length <= 3) return 0;
    return (length <= 6 ? 1 : 2) + _bonus;
  }
}

/// Deux mots (deja normalises) sont-ils equivalents sous [tolerance] ?
bool tokensMatch(String expected, String given, Tolerance tolerance) {
  if (expected == given) return true;
  final allowed = tolerance.allowedEdits(expected.length);
  if (allowed == 0) return false;
  return levenshtein(expected, given) <= allowed;
}

enum WordErrorType { wrong, missing, extra }

class WordError {
  const WordError(this.type, this.position, {this.expected, this.given});

  final WordErrorType type;

  /// Position dans le verset attendu (ou dans la reponse pour `extra`).
  final int position;
  final String? expected;
  final String? given;

  @override
  String toString() => '$type@$position(expected: $expected, given: $given)';
}

class RecallResult {
  const RecallResult(this.accepted, this.errors, this.accuracy);

  final bool accepted;
  final List<WordError> errors;

  /// Part des mots attendus correctement restitues, entre 0 et 1.
  final double accuracy;
}

/// Compare la saisie [answer] au verset [verse] (niveau 3, de memoire).
///
/// Alignement mot a mot par programmation dynamique : les fautes sont
/// reportees comme mot errone, manquant ou en trop. La reponse est acceptee
/// si elle compte au plus [maxWordErrors] erreurs de mots.
RecallResult checkRecall(
  String verse,
  String answer, {
  Tolerance tolerance = Tolerance.normal,
  int maxWordErrors = 0,
}) {
  final exp = verseTokens(verse);
  final got = verseTokens(answer);
  final rows = exp.length + 1;
  final cols = got.length + 1;
  final cost = List.generate(rows, (_) => List<int>.filled(cols, 0));
  for (var i = 0; i < rows; i++) {
    cost[i][0] = i;
  }
  for (var j = 0; j < cols; j++) {
    cost[0][j] = j;
  }
  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < cols; j++) {
      final sub = tokensMatch(exp[i - 1], got[j - 1], tolerance) ? 0 : 1;
      cost[i][j] = min(
        cost[i - 1][j - 1] + sub,
        min(cost[i - 1][j] + 1, cost[i][j - 1] + 1),
      );
    }
  }

  final errors = <WordError>[];
  var i = exp.length;
  var j = got.length;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      final match = tokensMatch(exp[i - 1], got[j - 1], tolerance);
      if (cost[i][j] == cost[i - 1][j - 1] + (match ? 0 : 1)) {
        if (!match) {
          errors.add(WordError(WordErrorType.wrong, i - 1,
              expected: exp[i - 1], given: got[j - 1]));
        }
        i--;
        j--;
        continue;
      }
    }
    if (i > 0 && cost[i][j] == cost[i - 1][j] + 1) {
      errors.add(WordError(WordErrorType.missing, i - 1, expected: exp[i - 1]));
      i--;
    } else {
      errors.add(WordError(WordErrorType.extra, j - 1, given: got[j - 1]));
      j--;
    }
  }
  errors.sort((a, b) => a.position.compareTo(b.position));

  final missed = errors
      .where((e) => e.type != WordErrorType.extra)
      .length
      .clamp(0, exp.length);
  final accuracy = exp.isEmpty ? 1.0 : (exp.length - missed) / exp.length;
  return RecallResult(errors.length <= maxWordErrors, errors, accuracy);
}

/// Niveau 3 : la reference saisie designe-t-elle la meme reference ?
bool checkReference(String expected, String answer) {
  final a = BibleRef.tryParse(expected);
  final b = BibleRef.tryParse(answer);
  return a != null && a == b;
}

// ---------------------------------------------------------------- niveau 1

/// Mots a remettre en ordre, dans un ordre melange.
List<String> scrambleVerse(String verse, {required int seed}) {
  final words = _displayWords(verse);
  if (words.length < 2) return words;
  final random = Random(seed);
  final original = List<String>.of(words);
  var shuffled = List<String>.of(words)..shuffle(random);
  // Evite de renvoyer l'ordre d'origine (au plus quelques essais).
  for (var attempt = 0; attempt < 10; attempt++) {
    if (!_sameOrder(shuffled, original)) break;
    shuffled = List<String>.of(words)..shuffle(random);
  }
  return shuffled;
}

/// Niveau 1 : l'ordre propose reconstitue-t-il le verset ?
bool checkOrder(String verse, List<String> arranged) {
  return normalizeVerse(arranged.join(' ')) == normalizeVerse(verse);
}

// ---------------------------------------------------------------- niveau 2

class GapExercise {
  const GapExercise(this.words, this.gapIndexes);

  /// Mots du verset tels qu'affiches (ponctuation incluse).
  final List<String> words;

  /// Positions masquees, ordre croissant.
  final List<int> gapIndexes;

  /// Reponses attendues, dans l'ordre des trous.
  List<String> get answers => [for (final i in gapIndexes) words[i]];

  /// Mots affiches ; les trous valent null.
  List<String?> get display =>
      [for (var i = 0; i < words.length; i++) gapIndexes.contains(i) ? null : words[i]];
}

/// Masque des mots-cles (>= 4 lettres) du verset. [ratio] est la part de
/// mots-cles masques (au moins un trou si le verset en contient).
GapExercise makeGaps(String verse, {required int seed, double ratio = 0.3}) {
  final words = _displayWords(verse);
  final candidates = <int>[
    for (var i = 0; i < words.length; i++)
      if (verseTokens(words[i]).join().length >= 4) i,
  ];
  if (candidates.isEmpty) return GapExercise(words, const []);
  final count = max(1, (candidates.length * ratio).round());
  candidates.shuffle(Random(seed));
  final chosen = candidates.take(count).toList()..sort();
  return GapExercise(words, chosen);
}

/// Niveau 2 : verifie chaque trou ; renvoie une valeur par trou.
List<bool> checkGaps(
  GapExercise exercise,
  List<String> answers, {
  Tolerance tolerance = Tolerance.normal,
}) {
  final expected = exercise.answers;
  return [
    for (var i = 0; i < expected.length; i++)
      i < answers.length &&
          tokensMatch(
            verseTokens(expected[i]).join(),
            verseTokens(answers[i]).join(),
            tolerance,
          ),
  ];
}

// ------------------------------------------------------------------ indices

/// Indice progressif (etape 1 : premieres lettres ; etape 2 et plus :
/// premiere moitie du verset en clair puis premieres lettres).
String progressiveHint(String verse, int step) {
  final words = _displayWords(verse);
  if (step <= 0) return '';
  String initials(String w) {
    final runes = w.runes.toList();
    return runes.isEmpty ? w : '${String.fromCharCode(runes.first)}…';
  }

  if (step == 1) return words.map(initials).join(' ');
  final half = (words.length / 2).ceil();
  return [
    ...words.take(half),
    ...words.skip(half).map(initials),
  ].join(' ');
}

List<String> _displayWords(String verse) => [
      for (final w in verse.trim().split(RegExp(r'\s+')))
        if (normalizeVerse(w).isNotEmpty) w,
    ];

bool _sameOrder(List<String> a, List<String> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
