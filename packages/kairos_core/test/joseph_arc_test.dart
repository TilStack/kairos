import 'dart:io';

import 'package:kairos_core/kairos_core.dart';
import 'package:test/test.dart';

/// L'arc complet livre avec l'application : « La Tunique et le Trone ».
Arc loadJosephArc() => parseArcString(File('../../content/joseph/arc.json').readAsStringSync());

void main() {
  englishArcTests();
  late Arc arc;
  late NarrativeEngine engine;

  setUpAll(() {
    arc = loadJosephArc();
    engine = NarrativeEngine(arc);
  });

  test('l\'arc est valide, sans erreur ni avertissement', () {
    final report = validateArc(arc);
    expect(report.errors, isEmpty);
    expect(report.warnings, isEmpty);
  });

  test('dix chapitres, dans l\'ordre de l\'histoire', () {
    expect(arc.chapters.map((c) => c.id), [
      'ch1-reveur',
      'ch2-citerne',
      'ch3-potiphar',
      'ch4-prison',
      'ch5-songes',
      'ch6-gouverneur',
      'ch7-freres',
      'ch8-coupe',
      'ch9-reconnaissance',
      'ch10-pardon',
    ]);
  });

  test('chaque chapitre a au moins un choix, un discernement, une Porte et un bilan', () {
    for (final c in arc.chapters) {
      final kinds = c.nodes.values.map((n) => n.runtimeType).toSet();
      expect(kinds, containsAll([ChoiceNode, DiscernmentNode, DoorNode, DebriefNode]), reason: c.id);
    }
  });

  test('les quatre types d\'anomalie sont tous travailles', () {
    final used = {
      for (final c in arc.chapters)
        for (final n in c.nodes.values.whereType<DiscernmentNode>()) n.anomaly,
    };
    expect(used, containsAll(AnomalyType.values));
  });

  test('les versets des Portes sont memorisables (8 a 40 mots)', () {
    for (final c in arc.chapters) {
      for (final door in c.nodes.values.whereType<DoorNode>()) {
        final words = arc.verseText(door.verse)!.split(RegExp(r'\s+')).length;
        expect(words, inInclusiveRange(8, 40), reason: '${c.id} / ${door.verse}');
      }
    }
  });

  test('chaque personnage cite dans un noeud est dans la distribution', () {
    final known = arc.characters.keys.toSet();
    for (final c in arc.chapters) {
      for (final n in c.nodes.values) {
        final who = n.character;
        if (who != null) expect(known, contains(who), reason: '${c.id}/${n.id}');
      }
    }
  });

  /// Joue un chapitre jusqu'a la fin avec la strategie donnee.
  GameState play(GameState start, {required bool firstOption}) {
    var s = start;
    for (var i = 0; i < 500; i++) {
      final step = engine.view(s);
      switch (step) {
        case DialogueStep():
        case DebriefStep():
          s = engine.advance(s);
        case ChoiceStep(:final options):
          expect(options, isNotEmpty, reason: 'choix sans option visible : ${s.nodeId}');
          s = engine.choose(s, (firstOption ? options.first : options.last).id);
        case DiscernmentStep(:final node):
          s = engine.answerDiscernment(s, node.anomaly).state;
        case DoorStep():
          s = engine.resolveDoor(s, forged: true);
        case EndStep():
          return s;
      }
    }
    fail('chapitre sans fin : ${s.chapterId}/${s.nodeId}');
  }

  for (final firstOption in [true, false]) {
    test('l\'arc se joue de bout en bout (${firstOption ? 'premieres' : 'dernieres'} options)', () {
      var traits = <Trait, int>{};
      var flags = <String>{};
      var keys = <String>{};
      for (final c in arc.chapters) {
        final end = play(
          engine.start(c.id, traits: traits, flags: flags, keys: keys),
          firstOption: firstOption,
        );
        expect(end.finished, isTrue, reason: c.id);
        traits = end.traits;
        flags = end.flags;
        keys = end.keys;
      }
      // Une Cle par Porte : dix chapitres, dix versets differents au plus.
      expect(keys.length, greaterThanOrEqualTo(9));
    });
  }
}

/// La version anglaise doit avoir exactement la meme structure : c'est ce qui
/// permet de changer de langue sans perdre sa progression.
void englishArcTests() {
  group('arc anglais', () {
    late Arc fr;
    late Arc en;
    late NarrativeEngine engine;

    setUpAll(() {
      fr = loadJosephArc();
      en = parseArcString(File('../../content/joseph/arc.en.json').readAsStringSync());
      engine = NarrativeEngine(en);
    });

    test('valide, sans erreur ni avertissement', () {
      final report = validateArc(en);
      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
    });

    test('meme identifiant, memes chapitres, memes noeuds et memes liens', () {
      expect(en.id, fr.id);
      expect(en.chapters.map((c) => c.id), fr.chapters.map((c) => c.id));
      for (var i = 0; i < fr.chapters.length; i++) {
        final a = fr.chapters[i];
        final b = en.chapters[i];
        expect(b.start, a.start, reason: a.id);
        expect(b.nodes.keys.toList(), a.nodes.keys.toList(), reason: a.id);
        for (final id in a.nodes.keys) {
          final x = a.nodes[id]!;
          final y = b.nodes[id]!;
          expect(y.runtimeType, x.runtimeType, reason: '${a.id}/$id');
          expect(y.character, x.character, reason: '${a.id}/$id');
          if (x is ChoiceNode) {
            final ids = x.options.map((o) => o.id).toList();
            expect((y as ChoiceNode).options.map((o) => o.id).toList(), ids, reason: '${a.id}/$id');
          }
          if (x is DiscernmentNode) {
            expect((y as DiscernmentNode).anomaly, x.anomaly, reason: '${a.id}/$id');
            expect(y.correctRef, x.correctRef, reason: '${a.id}/$id');
          }
          if (x is DoorNode) expect((y as DoorNode).verse, x.verse, reason: '${a.id}/$id');
        }
      }
    });

    test('memes versets et memes meditations (passages)', () {
      expect(en.verses['WEB']!.keys.toSet(), fr.verses['LSG1910']!.keys.toSet());
      expect(en.meditations.map((m) => m.passage), fr.meditations.map((m) => m.passage));
      for (var i = 0; i < fr.meditations.length; i++) {
        expect(en.meditations[i].answerIndex, fr.meditations[i].answerIndex);
        expect(en.meditations[i].options.length, fr.meditations[i].options.length);
      }
    });

    test('les versets des Portes restent memorisables (8 a 40 mots)', () {
      for (final c in en.chapters) {
        for (final door in c.nodes.values.whereType<DoorNode>()) {
          final words = en.verseText(door.verse)!.split(RegExp(r'\s+')).length;
          expect(words, inInclusiveRange(8, 40), reason: '${c.id} / ${door.verse}');
        }
      }
    });

    test('se joue de bout en bout', () {
      var s = engine.start('ch1-reveur');
      for (final c in en.chapters) {
        s = engine.start(c.id, traits: s.traits, flags: s.flags, keys: s.keys);
        for (var i = 0; i < 500; i++) {
          final step = engine.view(s, lang: 'en');
          if (step is EndStep) break;
          switch (step) {
            case DialogueStep() || DebriefStep():
              s = engine.advance(s);
            case ChoiceStep(:final options):
              s = engine.choose(s, options.first.id);
            case DiscernmentStep(:final node):
              s = engine.answerDiscernment(s, node.anomaly).state;
            case DoorStep():
              s = engine.resolveDoor(s, forged: true);
            case EndStep():
              break;
          }
        }
      }
      expect(s.keys.length, greaterThanOrEqualTo(9));
    });
  });
}
