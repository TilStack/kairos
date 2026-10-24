import 'package:kairos_core/kairos_core.dart';
import 'package:test/test.dart';

const verse = 'Ta parole est une lampe à mes pieds, Et une lumière sur mon sentier.';
const id = 'PSA.119.105';

DoorChallenge door(int level) =>
    DoorChallenge(verse: verse, verseId: id, level: level, seed: 5);

void main() {
  final now = DateTime.utc(2026, 11, 1);
  final fresh = KeyMastery.fresh(id, now);

  group('niveau 1', () {
    test('ordre correct : Cle forgee du premier coup', () {
      final c = door(1);
      final r = c.submitOrder(verse.split(' '));
      expect(r.correct, isTrue);
      expect(c.status, DoorStatus.forged);
      expect(c.hintsUsed, 0);
    });

    test('melange fourni, different du verset', () {
      expect(door(1).scrambled.join(' '), isNot(verse));
    });
  });

  group('niveau 2', () {
    test('trous : resultat par trou et reussite', () {
      final c = door(2);
      final bad = c.submitGaps(List.filled(c.gaps.answers.length, 'xxxx'));
      expect(bad.correct, isFalse);
      expect(bad.gapResults, everyElement(isFalse));
      final ok = c.submitGaps(c.gaps.answers);
      expect(ok.correct, isTrue);
      expect(c.status, DoorStatus.forged);
    });
  });

  group('niveau 3', () {
    test('verset et reference exacts', () {
      final c = door(3);
      expect(c.submitRecall(verse, 'Psaumes 119:105').correct, isTrue);
    });

    test('bon verset mais mauvaise reference : echec', () {
      final c = door(3);
      final r = c.submitRecall(verse, 'Psaumes 119:106');
      expect(r.correct, isFalse);
      expect(r.wordErrors, isEmpty);
    });

    test('bonne reference mais verset errone : erreurs de mots', () {
      final c = door(3);
      final r = c.submitRecall('Ta parole est une lampe', 'Ps 119.105');
      expect(r.correct, isFalse);
      expect(r.wordErrors, isNotEmpty);
    });

    test('faute de frappe tolerée', () {
      final c = door(3);
      expect(c.submitRecall(verse.replaceFirst('lumière', 'lumiere'), 'psaumes 119:105').correct, isTrue);
    });
  });

  group('essais, indices et non-blocage', () {
    test('indices progressifs apres chaque echec', () {
      final c = door(3);
      final r1 = c.submitRecall('', '');
      expect(r1.hint, progressiveHint(verse, 1));
      expect(r1.attemptsLeft, 2);
      final r2 = c.submitRecall('', '');
      expect(r2.hint, progressiveHint(verse, 2));
      expect(c.status, DoorStatus.inProgress);
    });

    test('trois echecs : epuise, jamais bloquant, plus d essai possible', () {
      final c = door(3);
      c.submitRecall('', '');
      c.submitRecall('', '');
      final r = c.submitRecall('', '');
      expect(r.status, DoorStatus.exhausted);
      expect(r.attemptsLeft, 0);
      expect(() => c.submitRecall(verse, 'Ps 119:105'), throwsStateError);
    });

    test('succes au 2e essai : indice utilise, qualite 4', () {
      final c = door(1);
      c.submitOrder(const ['mal']);
      c.submitOrder(verse.split(' '));
      expect(c.status, DoorStatus.forged);
      expect(c.hintsUsed, 1);
      final out = c.outcome(fresh, now);
      expect(out.mastery.level, 2);
    });
  });

  group('issue sur la maitrise', () {
    test('reussite sans indice : promotion', () {
      final c = door(1)..submitOrder(verse.split(' '));
      final out = c.outcome(fresh, now);
      expect(out.promoted, isTrue);
      expect(out.mastery.level, 2);
    });

    test('reussite au niveau 3 : Cle forgee durablement', () {
      final c = door(3)..submitRecall(verse, 'Psaumes 119:105');
      expect(c.outcome(fresh.copyWith(level: 3), now).mastery.forged, isTrue);
    });

    test('trois essais rates : repli d un niveau, une seule fois', () {
      final c = door(3);
      for (var i = 0; i < 3; i++) {
        c.submitRecall('', '');
      }
      final out = c.outcome(fresh.copyWith(level: 3), now);
      expect(out.fellBack, isTrue);
      expect(out.mastery.level, 2);
      expect(out.mastery.consecutiveFails, 0);
    });

    test('echec au niveau 1 : reste a 1, pas de repli annonce', () {
      final c = door(1);
      for (var i = 0; i < 3; i++) {
        c.submitOrder(const []);
      }
      final out = c.outcome(fresh, now);
      expect(out.mastery.level, 1);
      expect(out.fellBack, isFalse);
    });

    test('outcome refuse tant que le defi est en cours', () {
      expect(() => door(1).outcome(fresh, now), throwsStateError);
    });
  });
}
