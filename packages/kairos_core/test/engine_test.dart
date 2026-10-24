import 'dart:convert';
import 'dart:io';

import 'package:kairos_core/kairos_core.dart';
import 'package:test/test.dart';

Arc loadTestArc() => parseArcString(File('../../content/test_arc/arc.json').readAsStringSync());

void main() {
  late Arc arc;
  late NarrativeEngine engine;

  setUp(() {
    arc = loadTestArc();
    engine = NarrativeEngine(arc);
  });

  /// Joue le chapitre 1 jusqu'a la Porte avec l'option choisie.
  GameState toDoor(String option) {
    var s = engine.start('ch1-potiphar');
    s = engine.advance(s); // n1 -> n2 (choix)
    s = engine.choose(s, option);
    s = engine.answerDiscernment(s, AnomalyType.misattributed).state;
    expect(engine.view(s), isA<DoorStep>());
    return s;
  }

  test('demarre sur le premier noeud et le decrit', () {
    final s = engine.start('ch1-potiphar');
    expect(s.nodeId, 'n1');
    expect(s.finished, isFalse);
    expect(engine.view(s), isA<DialogueStep>());
  });

  test('un choix applique ses effets et se consigne', () {
    var s = engine.start('ch1-potiphar');
    s = engine.advance(s);
    s = engine.choose(s, 'defend');
    expect(s.trait(Trait.integrity), 1);
    expect(s.trait(Trait.courage), 1);
    expect(s.flags, contains('defended_joseph'));
    expect(s.choices.single.optionId, 'defend');
  });

  test('option conditionnelle masquee sans le trait, visible avec', () {
    var s = engine.start('ch1-potiphar');
    s = engine.advance(s);
    var choice = engine.view(s) as ChoiceStep;
    expect(choice.options.map((o) => o.id), ['defend', 'silent']);
    expect(() => engine.choose(s, 'warn'), throwsA(isA<EngineException>()));

    s = engine.start('ch1-potiphar', traits: {Trait.courage: 1});
    s = engine.advance(s);
    choice = engine.view(s) as ChoiceStep;
    expect(choice.options.map((o) => o.id), contains('warn'));
  });

  test('discernement : bonne et mauvaise reponse, toutes deux consignees', () {
    var s = engine.start('ch1-potiphar');
    s = engine.choose(engine.advance(s), 'defend');
    final wrong = engine.answerDiscernment(s, AnomalyType.truncated);
    expect(wrong.correct, isFalse);
    expect(wrong.state.discernments.single.correct, isFalse);
    expect(engine.view(wrong.state), isA<DoorStep>());
    final right = engine.answerDiscernment(s, AnomalyType.misattributed);
    expect(right.correct, isTrue);
  });

  test('Porte : cle forgee ajoutee ; echec ne bloque pas et est consigne', () {
    final forged = engine.resolveDoor(toDoor('defend'), forged: true);
    expect(forged.keys, contains('GEN.39.9'));
    expect(engine.view(forged), isA<DebriefStep>());

    final skipped = engine.resolveDoor(toDoor('defend'), forged: false);
    expect(skipped.keys, isEmpty);
    expect(skipped.flags, contains('door_skipped:GEN.39.9'));
    expect(engine.view(skipped), isA<DebriefStep>());
  });

  test('Porte deja forgee : revision express signalee', () {
    var s = engine.start('ch1-potiphar', keys: {'GEN.39.9'});
    s = engine.choose(engine.advance(s), 'defend');
    s = engine.answerDiscernment(s, AnomalyType.misattributed).state;
    expect((engine.view(s) as DoorStep).alreadyForged, isTrue);
  });

  test('debriefing : texte exact LSG et libelle de reference', () {
    var s = engine.resolveDoor(toDoor('defend'), forged: true);
    final debrief = engine.view(s) as DebriefStep;
    expect(debrief.verses.first.label, 'Genèse 39:9');
    expect(debrief.verses.first.text, arc.verseText('GEN.39.9'));
    s = engine.advance(s);
    expect(s.finished, isTrue);
    expect(engine.view(s), isA<EndStep>());
  });

  test('transition conditionnelle selon un drapeau pose plus tot', () {
    var s = engine.start('ch1-potiphar', traits: {Trait.courage: 1});
    s = engine.choose(engine.advance(s), 'warn');
    s = engine.answerDiscernment(s, AnomalyType.misattributed).state;
    s = engine.resolveDoor(s, forged: true);
    s = engine.advance(s);
    expect(s.finished, isTrue);

    final withFlag = engine.start('ch2-egypte', flags: s.flags, keys: s.keys);
    expect(withFlag.nodeId, 'm1');
    expect(engine.advance(withFlag).nodeId, 'm1b');

    final without = engine.start('ch2-egypte');
    expect(engine.advance(without).nodeId, 'm2');
  });

  test('traits bornes entre 0 et traitMax', () {
    var s = engine.start('ch1-potiphar', traits: {Trait.integrity: traitMax});
    s = engine.choose(engine.advance(s), 'defend');
    expect(s.trait(Trait.integrity), traitMax);
  });

  test('appels incompatibles avec le noeud courant refuses', () {
    final s = engine.start('ch1-potiphar');
    expect(() => engine.choose(s, 'defend'), throwsA(isA<EngineException>()));
    expect(() => engine.resolveDoor(s, forged: true), throwsA(isA<EngineException>()));
    expect(() => engine.answerDiscernment(s, AnomalyType.distorted),
        throwsA(isA<EngineException>()));
    expect(() => engine.start('inconnu'), throwsA(isA<EngineException>()));
  });

  test('l etat est immuable : l ancien etat reste valide (annulation, reprise)', () {
    final s0 = engine.advance(engine.start('ch1-potiphar'));
    final s1 = engine.choose(s0, 'defend');
    expect(s0.nodeId, 'n2');
    expect(s0.trait(Trait.integrity), 0);
    expect(s1.nodeId, isNot('n2'));
  });

  test('sauvegarde : aller-retour JSON et reprise exacte', () {
    final s = engine.choose(engine.advance(engine.start('ch1-potiphar')), 'defend');
    final json = jsonEncode(s.toJson());
    final restored = GameState.fromJson(jsonDecode(json) as Map<String, Object?>);
    expect(jsonEncode(restored.toJson()), json);
    expect(restored.nodeId, s.nodeId);
    // La suite est identique depuis l'etat restaure (RF-01 : reprise au dernier noeud).
    final a = engine.answerDiscernment(s, AnomalyType.misattributed).state;
    final b = engine.answerDiscernment(restored, AnomalyType.misattributed).state;
    expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
  });

  test('determinisme : meme parcours, memes etats', () {
    String run() {
      var s = engine.start('ch1-potiphar');
      s = engine.choose(engine.advance(s), 'silent');
      s = engine.answerDiscernment(s, AnomalyType.misattributed).state;
      s = engine.resolveDoor(s, forged: true);
      return jsonEncode(engine.advance(s).toJson());
    }

    expect(run(), run());
  });

  test('sauvegarde d un autre arc refusee', () {
    final other = GameState(arcId: 'autre', chapterId: 'ch1-potiphar', nodeId: 'n1');
    expect(() => engine.view(other), throwsA(isA<EngineException>()));
  });

  test('contenu modifie : noeud disparu signale clairement', () {
    final stale = GameState(arcId: arc.id, chapterId: 'ch1-potiphar', nodeId: 'disparu');
    expect(() => engine.view(stale), throwsA(isA<EngineException>()));
  });

  test('parcours complet des deux chapitres jusqu a la fin', () {
    var s = engine.start('ch1-potiphar');
    s = engine.choose(engine.advance(s), 'defend');
    s = engine.answerDiscernment(s, AnomalyType.misattributed).state;
    s = engine.advance(engine.resolveDoor(s, forged: true));
    expect(s.finished, isTrue);

    s = engine.start('ch2-egypte', keys: s.keys, traits: s.traits, flags: s.flags);
    s = engine.advance(s);
    s = engine.choose(s, 'forgive');
    s = engine.answerDiscernment(s, AnomalyType.outOfContext).state;
    s = engine.resolveDoor(s, forged: true);
    s = engine.advance(s);
    expect(s.finished, isTrue);
    expect(s.keys, containsAll(['GEN.39.9', 'GEN.50.20']));
  });
}
