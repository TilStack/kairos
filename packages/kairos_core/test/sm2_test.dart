import 'package:kairos_core/kairos_core.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 1, 8);

  KeyMastery fresh() => KeyMastery.fresh('JHN.3.16', t0);

  test('nouvelle cle immediatement due', () {
    expect(fresh().isDue(t0), isTrue);
    expect(fresh().isDue(t0.subtract(const Duration(minutes: 1))), isFalse);
  });

  test('intervalles 1, 6 puis ease croissant sur reussites parfaites', () {
    var m = fresh();
    var now = t0;
    final intervals = <int>[];
    for (var i = 0; i < 4; i++) {
      m = review(m, 5, now).mastery;
      intervals.add(m.intervalDays);
      now = m.due;
    }
    expect(intervals[0], 1);
    expect(intervals[1], 6);
    expect(intervals[2], greaterThan(6));
    expect(intervals[3], greaterThan(intervals[2]));
  });

  test('promotion de niveau sur qualite >= 4, plafonnee a 3', () {
    var m = fresh();
    final r1 = review(m, 5, t0);
    expect(r1.promoted, isTrue);
    expect(r1.mastery.level, 2);
    m = review(r1.mastery, 4, t0).mastery;
    expect(m.level, 3);
    expect(m.forged, isFalse);
    final r3 = review(m, 5, t0);
    expect(r3.promoted, isFalse);
    expect(r3.mastery.level, 3);
    expect(r3.mastery.forged, isTrue);
  });

  test('qualite 3 : pas de promotion, intervalle suit quand meme', () {
    final r = review(fresh(), 3, t0);
    expect(r.promoted, isFalse);
    expect(r.mastery.level, 1);
    expect(r.mastery.intervalDays, 1);
  });

  test('echec : retour a 1 jour, repetitions remises a zero', () {
    var m = review(fresh(), 5, t0).mastery;
    m = review(m, 5, t0).mastery;
    final r = review(m, 1, t0);
    expect(r.mastery.repetitions, 0);
    expect(r.mastery.intervalDays, 1);
    expect(r.mastery.consecutiveFails, 1);
    expect(r.mastery.ease, lessThan(m.ease));
  });

  test('trois echecs consecutifs : repli d un niveau, jamais sous 1', () {
    var m = fresh().copyWith(level: 3);
    var outcome = review(m, 0, t0);
    expect(outcome.fellBack, isFalse);
    outcome = review(outcome.mastery, 0, t0);
    expect(outcome.fellBack, isFalse);
    outcome = review(outcome.mastery, 0, t0);
    expect(outcome.fellBack, isTrue);
    expect(outcome.mastery.level, 2);
    expect(outcome.mastery.consecutiveFails, 0);

    m = fresh();
    for (var i = 0; i < 6; i++) {
      m = review(m, 0, t0).mastery;
    }
    expect(m.level, 1);
  });

  test('une reussite remet le compteur d echecs a zero', () {
    var m = review(fresh(), 0, t0).mastery;
    m = review(m, 0, t0).mastery;
    expect(m.consecutiveFails, 2);
    m = review(m, 4, t0).mastery;
    expect(m.consecutiveFails, 0);
  });

  test('ease ne descend jamais sous 1.3', () {
    var m = fresh();
    for (var i = 0; i < 30; i++) {
      m = review(m, 0, t0).mastery;
    }
    expect(m.ease, greaterThanOrEqualTo(minEase));
  });

  test('qualityFromAttempt', () {
    expect(qualityFromAttempt(correct: true, hintsUsed: 0), 5);
    expect(qualityFromAttempt(correct: true, hintsUsed: 1), 4);
    expect(qualityFromAttempt(correct: true, hintsUsed: 2), 3);
    expect(qualityFromAttempt(correct: false, hintsUsed: 0, accuracy: 0.8), 2);
    expect(qualityFromAttempt(correct: false, hintsUsed: 0, accuracy: 0), 0);
  });

  test('dueKeys trie les plus en retard d abord', () {
    final a = KeyMastery.fresh('A', t0.add(const Duration(days: 2)));
    final b = KeyMastery.fresh('B', t0);
    final c = KeyMastery.fresh('C', t0.add(const Duration(days: 10)));
    final now = t0.add(const Duration(days: 3));
    expect(dueKeys([a, b, c], now).map((k) => k.verseRef), ['B', 'A']);
  });

  test('serialisation aller-retour', () {
    final m = review(fresh(), 5, t0).mastery;
    final copy = KeyMastery.fromJson(m.toJson());
    expect(copy.toJson(), m.toJson());
  });
}
