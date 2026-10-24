import 'normalize.dart';

/// Livres de la Bible (codes USFM) avec noms francais de la LSG.
const _books = <(String, String)>[
  ('GEN', 'Genèse'), ('EXO', 'Exode'), ('LEV', 'Lévitique'),
  ('NUM', 'Nombres'), ('DEU', 'Deutéronome'), ('JOS', 'Josué'),
  ('JDG', 'Juges'), ('RUT', 'Ruth'), ('1SA', '1 Samuel'),
  ('2SA', '2 Samuel'), ('1KI', '1 Rois'), ('2KI', '2 Rois'),
  ('1CH', '1 Chroniques'), ('2CH', '2 Chroniques'), ('EZR', 'Esdras'),
  ('NEH', 'Néhémie'), ('EST', 'Esther'), ('JOB', 'Job'),
  ('PSA', 'Psaumes'), ('PRO', 'Proverbes'), ('ECC', 'Ecclésiaste'),
  ('SNG', 'Cantique des Cantiques'), ('ISA', 'Ésaïe'), ('JER', 'Jérémie'),
  ('LAM', 'Lamentations'), ('EZK', 'Ézéchiel'), ('DAN', 'Daniel'),
  ('HOS', 'Osée'), ('JOL', 'Joël'), ('AMO', 'Amos'),
  ('OBA', 'Abdias'), ('JON', 'Jonas'), ('MIC', 'Michée'),
  ('NAM', 'Nahum'), ('HAB', 'Habacuc'), ('ZEP', 'Sophonie'),
  ('HAG', 'Aggée'), ('ZEC', 'Zacharie'), ('MAL', 'Malachie'),
  ('MAT', 'Matthieu'), ('MRK', 'Marc'), ('LUK', 'Luc'),
  ('JHN', 'Jean'), ('ACT', 'Actes'), ('ROM', 'Romains'),
  ('1CO', '1 Corinthiens'), ('2CO', '2 Corinthiens'), ('GAL', 'Galates'),
  ('EPH', 'Éphésiens'), ('PHP', 'Philippiens'), ('COL', 'Colossiens'),
  ('1TH', '1 Thessaloniciens'), ('2TH', '2 Thessaloniciens'),
  ('1TI', '1 Timothée'), ('2TI', '2 Timothée'), ('TIT', 'Tite'),
  ('PHM', 'Philémon'), ('HEB', 'Hébreux'), ('JAS', 'Jacques'),
  ('1PE', '1 Pierre'), ('2PE', '2 Pierre'), ('1JN', '1 Jean'),
  ('2JN', '2 Jean'), ('3JN', '3 Jean'), ('JUD', 'Jude'),
  ('REV', 'Apocalypse'),
];

String _bookKey(String name) => normalizeVerse(name).replaceAll(' ', '');

final _byName = {for (final b in _books) _bookKey(b.$2): b.$1};

/// Alias courants qui ne sont pas des prefixes du nom complet.
const _aliases = <String, String>{
  'ps': 'PSA', 'pr': 'PRO', 'mt': 'MAT', 'mc': 'MRK', 'lc': 'LUK',
  'jn': 'JHN', 'ac': 'ACT', 'rm': 'ROM', 'ap': 'REV', 'es': 'EST',
  'ex': 'EXO', 'dt': 'DEU', 'nb': 'NUM', 'jg': 'JDG', 'ne': 'NEH',
};

/// Resout un nom de livre (nom complet, prefixe >= 3 lettres non ambigu
/// ou alias courant) en code USFM. Retourne null si inconnu ou ambigu.
String? resolveBook(String name) {
  final key = _bookKey(name);
  if (key.isEmpty) return null;
  final exact = _byName[key];
  if (exact != null) return exact;
  final alias = _aliases[key];
  if (alias != null) return alias;
  if (key.length < 3) return null;
  final matches = _byName.entries.where((e) => e.key.startsWith(key));
  final codes = matches.map((e) => e.value).toSet();
  return codes.length == 1 ? codes.first : null;
}

/// Nom francais d'un code USFM, ou null.
String? bookName(String code) {
  for (final b in _books) {
    if (b.$1 == code) return b.$2;
  }
  return null;
}

/// Reference biblique canonique : livre, chapitre, verset(s).
class BibleRef {
  const BibleRef(this.book, this.chapter, this.verseStart, [int? verseEnd])
      : verseEnd = verseEnd ?? verseStart;

  final String book;
  final int chapter;
  final int verseStart;
  final int verseEnd;

  /// Identifiant stable, ex. `GEN.37.3` ou `1SA.17.45-47`.
  String get id => verseStart == verseEnd
      ? '$book.$chapter.$verseStart'
      : '$book.$chapter.$verseStart-$verseEnd';

  /// Libelle francais, ex. `Genèse 37:3`.
  String get label {
    final name = bookName(book) ?? book;
    final verses =
        verseStart == verseEnd ? '$verseStart' : '$verseStart-$verseEnd';
    return '$name $chapter:$verses';
  }

  static final _pattern = RegExp(
    r'^\s*((?:[123]\s*)?[^\d\s:.,][^\d:.,]*?)\s+(\d{1,3})\s*[:.,]\s*(\d{1,3})'
    r'(?:\s*[-–]\s*(\d{1,3}))?\s*$',
  );

  /// Lit une reference libre ("Genèse 37:3", "gen 37.3", "1 Sam 17:45-47")
  /// ou un identifiant canonique ("GEN.37.3"). Retourne null si invalide.
  static BibleRef? tryParse(String input) {
    final canonical = RegExp(r'^([1-3]?[A-Z]{2,3})\.(\d{1,3})\.(\d{1,3})(?:-(\d{1,3}))?$')
        .firstMatch(input.trim());
    if (canonical != null && bookName(canonical.group(1)!) != null) {
      return _build(canonical.group(1)!, canonical.group(2)!,
          canonical.group(3)!, canonical.group(4));
    }
    final match = _pattern.firstMatch(input);
    if (match == null) return null;
    final book = resolveBook(match.group(1)!);
    if (book == null) return null;
    return _build(book, match.group(2)!, match.group(3)!, match.group(4));
  }

  static BibleRef? _build(String book, String ch, String v1, String? v2) {
    final chapter = int.parse(ch);
    final start = int.parse(v1);
    final end = v2 == null ? start : int.parse(v2);
    if (chapter < 1 || start < 1 || end < start) return null;
    return BibleRef(book, chapter, start, end);
  }

  @override
  bool operator ==(Object other) => other is BibleRef && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}
