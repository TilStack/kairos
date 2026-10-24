/// Normalisation des textes bibliques francais pour comparaison tolerante.
///
/// Dart n'embarque pas de normalisation Unicode (NFD) : les diacritiques
/// francais sont traites par table, et les signes combinants U+0300-U+036F
/// (saisie decomposee) sont supprimes.
library;

const _folding = <String, String>{
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ç': 'c', 'ñ': 'n', 'ÿ': 'y',
  'œ': 'oe', 'æ': 'ae',
};

final _combining = RegExp('[̀-ͯ]');
final _apostrophes = RegExp('[\'’‘`´ʼ]');
final _separators = RegExp(r'[\-–—_/]');
final _noise = RegExp(r'[^a-z0-9\s]');
final _spaces = RegExp(r'\s+');

/// Texte reduit a des mots minuscules sans accents ni ponctuation,
/// separes par un espace. Les apostrophes sont supprimees ("l'Eternel"
/// devient "leternel") et les traits d'union deviennent des espaces.
String normalizeVerse(String input) {
  final lower = input.toLowerCase().replaceAll(_combining, '');
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_folding[char] ?? char);
  }
  return buffer
      .toString()
      .replaceAll(_apostrophes, '')
      .replaceAll(_separators, ' ')
      .replaceAll(_noise, ' ')
      .replaceAll(_spaces, ' ')
      .trim();
}

/// Mots normalises d'un verset.
List<String> verseTokens(String input) {
  final normalized = normalizeVerse(input);
  return normalized.isEmpty ? const [] : normalized.split(' ');
}

/// Distance de Levenshtein entre deux chaines.
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final best = [
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
      current[j] = best;
    }
    previous = current;
  }
  return previous[b.length];
}
