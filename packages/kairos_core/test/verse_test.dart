import 'package:kairos_core/kairos_core.dart';
import 'package:test/test.dart';

const jn316 = 'Car Dieu a tant aimé le monde qu’il a donné son Fils unique, '
    'afin que quiconque croit en lui ne périsse point, mais qu’il ait la vie éternelle.';

void main() {
  group('normalizeVerse', () {
    test('supprime accents, casse et ponctuation', () {
      expect(normalizeVerse('L’Éternel est mon berger, je ne manquerai de rien.'),
          'leternel est mon berger je ne manquerai de rien');
    });

    test('apostrophes droite et typographique equivalentes', () {
      expect(normalizeVerse("qu'il"), normalizeVerse('qu’il'));
    });

    test('ligatures et cedille', () {
      expect(normalizeVerse('cœur façon'), 'coeur facon');
    });

    test('signes combinants (saisie decomposee)', () {
      expect(normalizeVerse('été'), 'ete');
    });

    test('guillemets francais, tirets et espaces multiples', () {
      expect(normalizeVerse('«  c’est-à-dire  »'), 'cest a dire');
    });

    test('entree vide ou ponctuation seule', () {
      expect(normalizeVerse(''), '');
      expect(verseTokens('... —'), isEmpty);
    });
  });

  group('checkRecall (niveau 3)', () {
    test('verset exact accepte', () {
      expect(checkRecall(jn316, jn316).accepted, isTrue);
    });

    test('insensible a la casse, aux accents et a la ponctuation', () {
      final typed = jn316.toLowerCase().replaceAll(RegExp('[,.]'), '');
      expect(checkRecall(jn316, typed).accepted, isTrue);
      expect(checkRecall(jn316, 'car dieu a tant aime le monde quil a donne '
          'son fils unique afin que quiconque croit en lui ne perisse point '
          'mais quil ait la vie eternelle').accepted, isTrue);
    });

    test('faute de frappe tolere en mode normal, refusee en strict', () {
      const verse = 'Ta parole est une lampe à mes pieds';
      const typo = 'Ta parolle est une lampe a mes pieds';
      expect(checkRecall(verse, typo).accepted, isTrue);
      expect(checkRecall(verse, typo, tolerance: Tolerance.strict).accepted,
          isFalse);
    });

    test('mot court errone jamais tolere', () {
      final r = checkRecall('Dieu est amour', 'Dieu es amour');
      expect(r.accepted, isFalse);
      expect(r.errors.single.type, WordErrorType.wrong);
    });

    test('mot manquant detecte avec sa position', () {
      final r = checkRecall('Dieu est amour', 'Dieu amour');
      expect(r.accepted, isFalse);
      expect(r.errors.single.type, WordErrorType.missing);
      expect(r.errors.single.expected, 'est');
      expect(r.errors.single.position, 1);
      expect(r.accuracy, closeTo(2 / 3, 1e-9));
    });

    test('mot en trop detecte', () {
      final r = checkRecall('Dieu est amour', 'Dieu est grand amour');
      expect(r.errors.single.type, WordErrorType.extra);
      expect(r.errors.single.given, 'grand');
    });

    test('maxWordErrors tolere un nombre borne d erreurs', () {
      expect(checkRecall('Dieu est amour', 'Dieu amour', maxWordErrors: 1).accepted,
          isTrue);
    });

    test('reponse vide', () {
      final r = checkRecall('Dieu est amour', '');
      expect(r.accepted, isFalse);
      expect(r.accuracy, 0);
    });

    test('mots permutes refuses', () {
      expect(checkRecall('Dieu est amour', 'amour est Dieu').accepted, isFalse);
    });
  });

  group('BibleRef', () {
    test('formes libres equivalentes', () {
      final a = BibleRef.tryParse('Genèse 37:3');
      expect(a, isNotNull);
      expect(a!.id, 'GEN.37.3');
      expect(BibleRef.tryParse('gen 37.3'), a);
      expect(BibleRef.tryParse('Gn 37:3'), isNull);
      expect(BibleRef.tryParse('GEN.37.3'), a);
    });

    test('livres numerotes et plages', () {
      final r = BibleRef.tryParse('1 Samuel 17:45-47');
      expect(r!.id, '1SA.17.45-47');
      expect(BibleRef.tryParse('1sam 17:45-47'), r);
      expect(r.label, '1 Samuel 17:45-47');
    });

    test('alias et prefixes', () {
      expect(BibleRef.tryParse('Jn 3:16')!.id, 'JHN.3.16');
      expect(BibleRef.tryParse('Jean 3:16')!.id, 'JHN.3.16');
      expect(BibleRef.tryParse('Ps 119:105')!.id, 'PSA.119.105');
    });

    test('invalides', () {
      expect(BibleRef.tryParse('Livre inconnu 1:1'), isNull);
      expect(BibleRef.tryParse('Jean 3'), isNull);
      expect(BibleRef.tryParse('Jean 3:16-2'), isNull);
      expect(BibleRef.tryParse(''), isNull);
    });

    test('checkReference tolere les ecritures equivalentes', () {
      expect(checkReference('Jean 3:16', 'jean 3.16'), isTrue);
      expect(checkReference('Jean 3:16', 'Jean 3:17'), isFalse);
      expect(checkReference('Jean 3:16', 'n’importe quoi'), isFalse);
    });
  });

  group('niveau 1 : reconstitution', () {
    test('melange deterministe et different de l original', () {
      final a = scrambleVerse(jn316, seed: 7);
      final b = scrambleVerse(jn316, seed: 7);
      expect(a, b);
      expect(a.join(' '), isNot(jn316));
      expect(a.length, jn316.split(RegExp(r'\s+')).length);
    });

    test('ordre correct accepte, ordre errone refuse', () {
      final words = jn316.split(' ');
      expect(checkOrder(jn316, words), isTrue);
      expect(checkOrder(jn316, words.reversed.toList()), isFalse);
    });
  });

  group('niveau 2 : mots manquants', () {
    test('trous deterministes sur des mots-cles', () {
      final a = makeGaps(jn316, seed: 3);
      final b = makeGaps(jn316, seed: 3);
      expect(a.gapIndexes, b.gapIndexes);
      expect(a.gapIndexes, isNotEmpty);
      for (final answer in a.answers) {
        expect(verseTokens(answer).join().length, greaterThanOrEqualTo(4));
      }
      expect(a.display.where((w) => w == null).length, a.gapIndexes.length);
    });

    test('verification trou par trou, avec tolerance', () {
      final ex = makeGaps('Ta parole est une lampe à mes pieds', seed: 1, ratio: 0.5);
      final good = checkGaps(ex, ex.answers);
      expect(good.every((e) => e), isTrue);
      final bad = checkGaps(ex, List.filled(ex.answers.length, 'xxxx'));
      expect(bad.any((e) => e), isFalse);
      expect(checkGaps(ex, const []).any((e) => e), isFalse);
    });

    test('verset sans mot-cle : aucun trou', () {
      expect(makeGaps('Il a dit', seed: 1).gapIndexes, isEmpty);
    });
  });

  group('indices progressifs', () {
    test('etape 1 premieres lettres, etape 2 moitie en clair', () {
      const verse = 'Dieu est amour';
      expect(progressiveHint(verse, 0), '');
      expect(progressiveHint(verse, 1), 'D… e… a…');
      expect(progressiveHint(verse, 2), 'Dieu est a…');
    });
  });
}
