import 'dart:convert';
import 'dart:io';

import 'package:kairos_core/kairos_core.dart';

const _usage = 'Usage : dart run kairos_core:kairos_play <arc.json> [chapterId]';

void main(List<String> args) {
  // `main` ne peut pas renvoyer de code de sortie : il faut passer par exitCode.
  exitCode = _run(args);
}

/// Lecture UTF-8 explicite : l'encodage systeme de Windows abime les accents.
String? _line() => stdin.readLineSync(encoding: utf8);

int _run(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(_usage);
    return 2;
  }
  final Arc arc;
  try {
    arc = parseArcString(File(args.first).readAsStringSync());
  } on ArcFormatException catch (e) {
    stderr.writeln(e);
    return 1;
  } on FileSystemException catch (e) {
    stderr.writeln('Lecture impossible : ${e.message}');
    return 2;
  }
  final report = validateArc(arc);
  if (!report.ok) {
    stderr.writeln('Arc invalide, lancez kairos_validate.');
    return 1;
  }

  final engine = NarrativeEngine(arc);
  final chapterIds = args.length > 1 ? [args[1]] : arc.chapters.map((c) => c.id).toList();
  stdout.writeln('=== ${arc.title} ===');

  var keys = <String>{};
  var traits = <Trait, int>{};
  var flags = <String>{};
  final mastery = <String, KeyMastery>{};
  final clock = DateTime.utc(2026, 11, 1);

  for (final id in chapterIds) {
    final chapter = arc.chapter(id);
    if (chapter == null) {
      stderr.writeln('Chapitre inconnu : $id');
      return 2;
    }
    stdout.writeln('\n--- ${chapter.title} ---');
    var state = engine.start(id, keys: keys, traits: traits, flags: flags);
    while (!state.finished) {
      final step = engine.view(state);
      switch (step) {
        case DialogueStep(:final node):
          stdout.writeln('\n${node.speaker == null ? '' : '${node.speaker} : '}${node.text}');
          state = engine.advance(state);
        case ChoiceStep(:final node, :final options):
          stdout.writeln('\n${node.prompt}');
          for (var i = 0; i < options.length; i++) {
            stdout.writeln('  ${i + 1}. ${options[i].text}');
          }
          final pick = _askIndex(options.length);
          if (pick == null) return _eof();
          state = engine.choose(state, options[pick].id);
        case DiscernmentStep(:final node):
          stdout.writeln('\n${node.speaker ?? 'Une voix'} : ${node.quote}');
          if (node.claimedRef != null) stdout.writeln('  (cite : ${node.claimedRef})');
          stdout.writeln('Quelle est l\'anomalie ?');
          const types = AnomalyType.values;
          for (var i = 0; i < types.length; i++) {
            stdout.writeln('  ${i + 1}. ${types[i].id}');
          }
          final pick = _askIndex(types.length);
          if (pick == null) return _eof();
          final result = engine.answerDiscernment(state, types[pick]);
          stdout.writeln(result.correct ? 'Juste.' : 'Pas tout a fait.');
          stdout.writeln(node.explanation);
          state = result.state;
        case DoorStep(:final node):
          stdout.writeln('\n${node.prompt}');
          final verse = arc.verseText(node.verse)!;
          final m = mastery[node.verse] ?? KeyMastery.fresh(node.verse, clock);
          final outcome = _playDoor(verse, node.verse, m, clock);
          if (outcome == null) return _eof();
          mastery[node.verse] = outcome.$1;
          state = engine.resolveDoor(state, forged: outcome.$2);
        case DebriefStep(:final node, :final verses, :final traits):
          stdout.writeln('\n[Debriefing] ${node.teaching}');
          for (final v in verses) {
            stdout.writeln('  « ${v.text} » — ${v.label}');
          }
          stdout.writeln('  Traits : ${traits.entries.map((e) => '${e.key.name}=${e.value}').join(', ')}');
          state = engine.advance(state);
        case EndStep():
          break;
      }
    }
    keys = state.keys;
    traits = state.traits;
    flags = state.flags;
    stdout.writeln('\n[Sauvegarde] ${state.toJson()}');
  }
  return 0;
}

int _eof() {
  stderr.writeln('Fin de saisie.');
  return 3;
}

int? _askIndex(int count) {
  while (true) {
    stdout.write('> ');
    final line = _line();
    if (line == null) return null;
    final n = int.tryParse(line.trim());
    if (n != null && n >= 1 && n <= count) return n - 1;
    stdout.writeln('Entrez un nombre entre 1 et $count.');
  }
}

/// Joue une Porte : 3 essais avec indices, jamais bloquant.
/// Retourne (nouvel etat de maitrise, cle forgee) ou null en fin de saisie.
(KeyMastery, bool)? _playDoor(String verse, String id, KeyMastery m, DateTime now) {
  final ref = BibleRef.tryParse(id)!.label;
  stdout.writeln('Porte : $ref (niveau ${m.level})');
  var hints = 0;
  for (var attempt = 1; attempt <= failuresBeforeFallback; attempt++) {
    final bool ok;
    switch (m.level) {
      case 1:
        final words = scrambleVerse(verse, seed: id.hashCode);
        stdout.writeln('Remettez en ordre : ${words.join(' | ')}');
        final line = _line();
        if (line == null) return null;
        ok = checkOrder(verse, line.trim().split(RegExp(r'\s+')));
      case 2:
        final gaps = makeGaps(verse, seed: id.hashCode);
        stdout.writeln(gaps.display.map((w) => w ?? '____').join(' '));
        final line = _line();
        if (line == null) return null;
        final answers = line.split(',').map((s) => s.trim()).toList();
        ok = checkGaps(gaps, answers).every((b) => b);
      default:
        stdout.writeln('Recitez le verset de memoire :');
        final line = _line();
        if (line == null) return null;
        ok = checkRecall(verse, line).accepted;
    }
    if (ok) {
      stdout.writeln('La Cle est forgee.');
      final out = review(m, qualityFromAttempt(correct: true, hintsUsed: hints), now);
      return (out.mastery, true);
    }
    hints++;
    stdout.writeln('Indice : ${progressiveHint(verse, hints)}');
  }
  stdout.writeln('La Porte s\'ouvre malgre tout : « $verse »');
  final out = review(m, qualityFromAttempt(correct: false, hintsUsed: hints), now);
  return (out.mastery, false);
}
