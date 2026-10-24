import 'dart:convert';
import 'dart:io';

import 'package:kairos_core/kairos_core.dart';
import 'package:test/test.dart';

const med = Meditation(
  id: 'med-1',
  passage: 'PRO.3.5',
  reflectionPrompt: 'Que changerait la confiance ?',
  question: 'En qui se confier ?',
  options: ['En soi', "En l'Éternel"],
  answerIndex: 1,
);

const good = MeditationAttempt(
  readSeconds: 30,
  answerIndex: 1,
  reflection: 'Je veux me confier en Dieu dans mes examens.',
);

void main() {
  const d0 = 20000;

  group('dayNumber', () {
    test('meme jour quelle que soit l heure', () {
      expect(dayNumber(DateTime(2026, 11, 1, 0, 5)), dayNumber(DateTime(2026, 11, 1, 23, 59)));
      expect(dayNumber(DateTime(2026, 11, 2)) - dayNumber(DateTime(2026, 11, 1)), 1);
    });
  });

  group('meditation et recharge', () {
    test('acceptee : recharge, serie 1', () {
      final r = completeMeditation(const LampState(), med, good, d0);
      expect(r.accepted, isTrue);
      expect(r.lamp.oil, oilPerMeditation);
      expect(r.lamp.streak, 1);
      expect(r.lamp.meditatedOn(d0), isTrue);
    });

    test('lecture trop rapide refusee sans rien changer', () {
      const fast = MeditationAttempt(readSeconds: 3, answerIndex: 1, reflection: 'Une reflexion assez longue.');
      final r = completeMeditation(const LampState(), med, fast, d0);
      expect(r.rejection, MeditationRejection.tooFast);
      expect(r.lamp.oil, 0);
      expect(r.lamp.lastMeditationDay, isNull);
    });

    test('mauvaise reponse de comprehension puis nouvel essai accepte', () {
      const wrong = MeditationAttempt(readSeconds: 30, answerIndex: 0, reflection: 'Une reflexion assez longue.');
      expect(completeMeditation(const LampState(), med, wrong, d0).rejection,
          MeditationRejection.wrongAnswer);
      const none = MeditationAttempt(readSeconds: 30, answerIndex: null, reflection: 'Une reflexion assez longue.');
      expect(completeMeditation(const LampState(), med, none, d0).rejection,
          MeditationRejection.wrongAnswer);
      expect(completeMeditation(const LampState(), med, good, d0).accepted, isTrue);
    });

    test('reflexion trop courte (espaces ignores)', () {
      const short = MeditationAttempt(readSeconds: 30, answerIndex: 1, reflection: '   amen   ');
      expect(completeMeditation(const LampState(), med, short, d0).rejection,
          MeditationRejection.reflectionTooShort);
    });

    test('une seule recharge par jour', () {
      final first = completeMeditation(const LampState(), med, good, d0).lamp;
      final again = completeMeditation(first, med, good, d0);
      expect(again.rejection, MeditationRejection.alreadyDone);
      expect(again.lamp.oil, first.oil);
    });

    test('horloge revenue en arriere : pas de recharge', () {
      final first = completeMeditation(const LampState(), med, good, d0).lamp;
      expect(completeMeditation(first, med, good, d0 - 3).rejection, MeditationRejection.alreadyDone);
    });

    test('huile plafonnee a maxOil', () {
      var lamp = const LampState();
      for (var i = 0; i < 5; i++) {
        lamp = completeMeditation(lamp, med, good, d0 + i).lamp;
      }
      expect(lamp.oil, lessThanOrEqualTo(maxOil));
      expect(lamp.oil, greaterThan(oilPerMeditation));
    });
  });

  group('serie et fiole d or', () {
    test('serie continue sur jours consecutifs, fiole au 7e', () {
      var lamp = const LampState();
      var vials = 0;
      for (var i = 0; i < 7; i++) {
        final r = completeMeditation(lamp, med, good, d0 + i);
        lamp = r.lamp;
        if (r.goldVialEarned) vials++;
      }
      expect(lamp.streak, 7);
      expect(vials, 1);
      expect(lamp.goldVials, 1);
      expect(lamp.bestStreak, 7);
    });

    test('un jour manque est pardonne (jour de grace)', () {
      var lamp = completeMeditation(const LampState(), med, good, d0).lamp;
      lamp = completeMeditation(lamp, med, good, d0 + 2).lamp;
      expect(lamp.streak, 2);
    });

    test('deux jours manques : la serie repart a 1, le meilleur score reste', () {
      var lamp = completeMeditation(const LampState(), med, good, d0).lamp;
      lamp = completeMeditation(lamp, med, good, d0 + 1).lamp;
      lamp = completeMeditation(lamp, med, good, d0 + 4).lamp;
      expect(lamp.streak, 1);
      expect(lamp.bestStreak, 2);
    });
  });

  group('decroissance douce', () {
    test('baisse lente, jamais sous zero', () {
      var lamp = completeMeditation(const LampState(), med, good, d0).lamp;
      lamp = applyDecay(lamp, d0 + 3);
      expect(lamp.oil, oilPerMeditation - 3 * oilDecayPerDay);
      lamp = applyDecay(lamp, d0 + 400);
      expect(lamp.oil, 0);
    });

    test('premier appel : simple initialisation', () {
      final lamp = applyDecay(const LampState(oil: 40), d0);
      expect(lamp.oil, 40);
      expect(lamp.lastUpdateDay, d0);
    });

    test('meme jour ou horloge en arriere : aucun effet', () {
      final lamp = applyDecay(const LampState(oil: 40, lastUpdateDay: d0), d0 - 5);
      expect(lamp.oil, 40);
    });

    test('lampe vide : multiplicateur 1.0, jamais penalisant ; pleine : 1.5', () {
      expect(const LampState().fruitMultiplier, 1.0);
      expect(const LampState(oil: maxOil).fruitMultiplier, 1.5);
    });

    test('la decroissance ne retire pas la serie', () {
      var lamp = completeMeditation(const LampState(), med, good, d0).lamp;
      lamp = applyDecay(lamp, d0 + 30);
      expect(lamp.streak, 1);
    });
  });

  test('serialisation de la lampe', () {
    final lamp = completeMeditation(const LampState(), med, good, d0).lamp;
    expect(LampState.fromJson(lamp.toJson()).toJson(), lamp.toJson());
  });

  group('journal', () {
    final t = DateTime.utc(2026, 11, 1, 8);

    test('entree de meditation : passage, reflexion, arc', () {
      final e = JournalEntry.meditation(
        id: 'e1', at: t, arcId: 'joseph-test', meditation: med, reflection: '  Ma réflexion  ',
      );
      expect(e.type, JournalEntryType.meditation);
      expect(e.body, endsWith('Ma réflexion'));
      expect(e.refs, ['PRO.3.5']);
    });

    test('aller-retour JSON', () {
      final e = JournalEntry.keyForged(
        id: 'e2', at: t, arcId: 'a', verseId: 'GEN.39.9', label: 'Genèse 39:9', text: 'texte',
      );
      final copy = JournalEntry.fromJson(jsonDecode(jsonEncode(e.toJson())) as Map<String, Object?>);
      expect(copy.toJson(), e.toJson());
    });

    test('filtre par type et arc, plus recent d abord', () {
      final a = JournalEntry.note(id: 'a', at: t, text: 'ancienne');
      final b = JournalEntry.note(id: 'b', at: t.add(const Duration(days: 1)), text: 'recente');
      final c = JournalEntry.meditation(
        id: 'c', at: t.add(const Duration(days: 2)), arcId: 'x', meditation: med, reflection: 'abcdefghijk',
      );
      expect(filterEntries([a, b, c]).map((e) => e.id), ['c', 'b', 'a']);
      expect(filterEntries([a, b, c], type: JournalEntryType.note).map((e) => e.id), ['b', 'a']);
      expect(filterEntries([a, b, c], arcId: 'x').map((e) => e.id), ['c']);
    });

    test('entree de discernement archive explication et verset', () {
      final arc = parseArcString(File('../../content/test_arc/arc.json').readAsStringSync());
      final node = arc.chapters.first.nodes['n3']! as DiscernmentNode;
      final e = JournalEntry.discernment(id: 'd', at: t, arcId: arc.id, node: node, correct: false);
      expect(e.title, 'Discernement à relire');
      expect(e.refs, ['PRO.3.5']);
      expect(e.body, contains(node.explanation));
    });
  });

  group('meditations de l arc', () {
    final arc = parseArcString(File('../../content/test_arc/arc.json').readAsStringSync());

    test('passage du jour : ordre deterministe et cyclique', () {
      expect(arc.meditations, hasLength(3));
      expect(meditationForDay(arc, 0)!.id, 'med-1');
      expect(meditationForDay(arc, 1)!.id, 'med-2');
      expect(meditationForDay(arc, 3)!.id, 'med-1');
      expect(meditationForDay(arc, 20000)!.id, meditationForDay(arc, 20000)!.id);
    });

    test('chaque passage existe dans la table de versets', () {
      for (final m in arc.meditations) {
        expect(arc.verseText(m.passage), isNotNull, reason: m.id);
      }
    });

    test('arc sans meditation : aucun passage', () {
      final bare = Arc(
        schemaVersion: 1, id: 'x', title: 't', version: '1.0.0', minEngineVersion: 1,
        defaultBible: 'B', bibles: const {}, verses: const {}, chapters: const [],
      );
      expect(meditationForDay(bare, 5), isNull);
    });

    test('meditation invalide refusee par le parseur', () {
      final json = jsonDecode(File('../../content/test_arc/arc.json').readAsStringSync())
          as Map<String, Object?>;
      final first = (json['meditations']! as List<Object?>).first! as Map<String, Object?>;
      first['answerIndex'] = 9;
      expect(() => parseArc(json), throwsA(isA<ArcFormatException>()));
    });
  });
}
