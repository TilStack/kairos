import 'dart:convert';

import 'models.dart';

/// Erreurs de format d'un arc (chemin JSON + message), toutes remontees d'un coup.
class ArcFormatException implements Exception {
  ArcFormatException(this.errors);
  final List<String> errors;

  @override
  String toString() => 'ArcFormatException:\n${errors.map((e) => '  - $e').join('\n')}';
}

/// Lit un arc depuis du texte JSON.
Arc parseArcString(String source) {
  final Object? json;
  try {
    json = jsonDecode(source);
  } on FormatException catch (e) {
    throw ArcFormatException(['JSON invalide : ${e.message}']);
  }
  return parseArc(json);
}

/// Lit un arc depuis un JSON decode. Le format est strict : les cles
/// inconnues sont des erreurs (elles trahissent presque toujours une faute
/// de frappe d'un redacteur).
Arc parseArc(Object? json) {
  final p = _Parser();
  final arc = p.arc(json);
  if (p.errors.isNotEmpty || arc == null) {
    throw ArcFormatException(p.errors.isEmpty ? ['arc illisible'] : p.errors);
  }
  return arc;
}

final _idPattern = RegExp(r'^[a-z0-9][a-z0-9_\-]*$');
final _semver = RegExp(r'^\d+\.\d+\.\d+$');

class _Parser {
  final errors = <String>[];

  void _err(String path, String message) => errors.add('$path : $message');

  /// [allowed] null : toutes les cles sont admises (tables indexees par id).
  Map<String, Object?>? _obj(Object? v, String path, Set<String>? allowed) {
    if (v is! Map<String, Object?>) {
      _err(path, 'objet attendu');
      return null;
    }
    if (allowed != null) {
      for (final key in v.keys) {
        if (!allowed.contains(key)) _err('$path.$key', 'cle inconnue');
      }
    }
    return v;
  }

  String? _str(Map<String, Object?> m, String key, String path,
      {bool required = true}) {
    final v = m[key];
    if (v == null) {
      if (required) _err('$path.$key', 'champ obligatoire');
      return null;
    }
    if (v is! String || v.trim().isEmpty) {
      _err('$path.$key', 'texte non vide attendu');
      return null;
    }
    return v;
  }

  int? _int(Map<String, Object?> m, String key, String path,
      {bool required = true}) {
    final v = m[key];
    if (v == null) {
      if (required) _err('$path.$key', 'champ obligatoire');
      return null;
    }
    if (v is! int) {
      _err('$path.$key', 'entier attendu');
      return null;
    }
    return v;
  }

  List<Object?>? _list(Map<String, Object?> m, String key, String path,
      {bool required = true}) {
    final v = m[key];
    if (v == null) {
      if (required) _err('$path.$key', 'champ obligatoire');
      return null;
    }
    if (v is! List<Object?>) {
      _err('$path.$key', 'liste attendue');
      return null;
    }
    return v;
  }

  List<String> _strList(Map<String, Object?> m, String key, String path) {
    final list = _list(m, key, path, required: false);
    if (list == null) return const [];
    final out = <String>[];
    for (var i = 0; i < list.length; i++) {
      final v = list[i];
      if (v is String && v.isNotEmpty) {
        out.add(v);
      } else {
        _err('$path.$key[$i]', 'texte non vide attendu');
      }
    }
    return out;
  }

  Trait? _trait(String name, String path) {
    for (final t in Trait.values) {
      if (t.name == name) return t;
    }
    _err(path, 'trait inconnu "$name" (attendu : '
        '${Trait.values.map((t) => t.name).join(', ')})');
    return null;
  }

  Condition? _condition(Object? v, String path) {
    final m = _obj(v, path, {'traits', 'keys', 'flags', 'notFlags'});
    if (m == null) return null;
    final traits = <Trait, Range>{};
    final rawTraits = m['traits'];
    if (rawTraits != null) {
      final tm = _obj(rawTraits, '$path.traits', Trait.values.map((t) => t.name).toSet());
      if (tm != null) {
        for (final e in tm.entries) {
          final r = _obj(e.value, '$path.traits.${e.key}', {'min', 'max'});
          final trait = _trait(e.key, '$path.traits.${e.key}');
          if (r == null || trait == null) continue;
          final min = _int(r, 'min', '$path.traits.${e.key}', required: false);
          final max = _int(r, 'max', '$path.traits.${e.key}', required: false);
          if (min == null && max == null) {
            _err('$path.traits.${e.key}', 'min ou max requis');
          } else if (min != null && max != null && min > max) {
            _err('$path.traits.${e.key}', 'min superieur a max');
          }
          traits[trait] = Range(min: min, max: max);
        }
      }
    }
    return Condition(
      traits: traits,
      keys: _strList(m, 'keys', path).toSet(),
      flags: _strList(m, 'flags', path).toSet(),
      notFlags: _strList(m, 'notFlags', path).toSet(),
    );
  }

  Effects _effects(Object? v, String path) {
    if (v == null) return Effects.none;
    final m = _obj(v, path, {'traits', 'setFlags', 'clearFlags'});
    if (m == null) return Effects.none;
    final traits = <Trait, int>{};
    final raw = m['traits'];
    if (raw != null) {
      final tm = _obj(raw, '$path.traits', Trait.values.map((t) => t.name).toSet());
      if (tm != null) {
        for (final e in tm.entries) {
          final trait = _trait(e.key, '$path.traits.${e.key}');
          final value = e.value;
          if (value is! int) {
            _err('$path.traits.${e.key}', 'entier attendu');
          } else if (trait != null) {
            traits[trait] = value;
          }
        }
      }
    }
    return Effects(
      traits: traits,
      setFlags: _strList(m, 'setFlags', path).toSet(),
      clearFlags: _strList(m, 'clearFlags', path).toSet(),
    );
  }

  List<Transition> _next(Object? v, String path) {
    if (v == null) {
      _err(path, 'champ obligatoire');
      return const [];
    }
    if (v is String) {
      if (v.isEmpty) _err(path, 'identifiant vide');
      return [Transition(v)];
    }
    if (v is! List<Object?>) {
      _err(path, 'identifiant ou liste de transitions attendu');
      return const [];
    }
    final out = <Transition>[];
    for (var i = 0; i < v.length; i++) {
      final m = _obj(v[i], '$path[$i]', {'to', 'if'});
      if (m == null) continue;
      final to = _str(m, 'to', '$path[$i]');
      final cond = m['if'] == null ? null : _condition(m['if'], '$path[$i].if');
      if (to != null) out.add(Transition(to, cond));
    }
    if (out.isEmpty) _err(path, 'au moins une transition attendue');
    return out;
  }

  static const _commonKeys = {'id', 'type', 'scene', 'refs', 'effects'};

  Node? _node(Object? v, String path) {
    if (v is! Map<String, Object?>) {
      _err(path, 'objet attendu');
      return null;
    }
    final type = v['type'];
    final specific = switch (type) {
      'dialogue' => {'speaker', 'text', 'next'},
      'choice' => {'prompt', 'options'},
      'door' => {'prompt', 'verse', 'next'},
      'discernment' => {
          'speaker', 'quote', 'claimedRef', 'anomaly', 'correctRef',
          'explanation', 'next',
        },
      'debrief' => {'teaching', 'verses', 'next'},
      'end' => <String>{},
      _ => null,
    };
    if (specific == null) {
      _err('$path.type', 'type inconnu "$type" (dialogue, choice, door, '
          'discernment, debrief, end)');
      return null;
    }
    final m = _obj(v, path, {..._commonKeys, ...specific})!;
    final id = _str(m, 'id', path);
    if (id != null && !_idPattern.hasMatch(id)) {
      _err('$path.id', 'identifiant invalide "$id" (a-z, 0-9, _ et -)');
    }
    final scene = _str(m, 'scene', path, required: false);
    final refs = _strList(m, 'refs', path);
    final effects = _effects(m['effects'], '$path.effects');
    if (id == null) return null;
    final nodePath = '$path($id)';

    switch (type) {
      case 'dialogue':
        final text = _str(m, 'text', nodePath);
        final next = _next(m['next'], '$nodePath.next');
        if (text == null) return null;
        return DialogueNode(
          id: id, text: text, next: next, scene: scene, refs: refs,
          effects: effects, speaker: _str(m, 'speaker', nodePath, required: false),
        );
      case 'choice':
        final prompt = _str(m, 'prompt', nodePath);
        final rawOptions = _list(m, 'options', nodePath);
        final options = <ChoiceOption>[];
        for (var i = 0; i < (rawOptions?.length ?? 0); i++) {
          final op = '$nodePath.options[$i]';
          final om = _obj(rawOptions![i], op, {'id', 'text', 'requires', 'effects', 'next'});
          if (om == null) continue;
          final oid = _str(om, 'id', op);
          final text = _str(om, 'text', op);
          final next = _next(om['next'], '$op.next');
          if (oid == null || text == null) continue;
          options.add(ChoiceOption(
            id: oid, text: text, next: next,
            requires: om['requires'] == null ? null : _condition(om['requires'], '$op.requires'),
            effects: _effects(om['effects'], '$op.effects'),
          ));
        }
        if (prompt == null) return null;
        return ChoiceNode(
          id: id, prompt: prompt, options: options, scene: scene, refs: refs,
          effects: effects,
        );
      case 'door':
        final prompt = _str(m, 'prompt', nodePath);
        final verse = _str(m, 'verse', nodePath);
        final next = _next(m['next'], '$nodePath.next');
        if (prompt == null || verse == null) return null;
        return DoorNode(
          id: id, prompt: prompt, verse: verse, next: next, scene: scene,
          refs: refs, effects: effects,
        );
      case 'discernment':
        final quote = _str(m, 'quote', nodePath);
        final anomalyId = _str(m, 'anomaly', nodePath);
        final explanation = _str(m, 'explanation', nodePath);
        final next = _next(m['next'], '$nodePath.next');
        final anomaly = anomalyId == null ? null : AnomalyType.fromId(anomalyId);
        if (anomalyId != null && anomaly == null) {
          _err('$nodePath.anomaly', 'anomalie inconnue "$anomalyId" (distorted, '
              'truncated, out_of_context, misattributed)');
        }
        if (quote == null || anomaly == null || explanation == null) return null;
        return DiscernmentNode(
          id: id, quote: quote, anomaly: anomaly, explanation: explanation,
          next: next, scene: scene, refs: refs, effects: effects,
          speaker: _str(m, 'speaker', nodePath, required: false),
          claimedRef: _str(m, 'claimedRef', nodePath, required: false),
          correctRef: _str(m, 'correctRef', nodePath, required: false),
        );
      case 'debrief':
        final teaching = _str(m, 'teaching', nodePath);
        final verses = _strList(m, 'verses', nodePath);
        final next = _next(m['next'], '$nodePath.next');
        if (teaching == null) return null;
        return DebriefNode(
          id: id, teaching: teaching, verses: verses, next: next, scene: scene,
          refs: refs, effects: effects,
        );
      default:
        return EndNode(id: id, scene: scene, refs: refs, effects: effects);
    }
  }

  Chapter? _chapter(Object? v, String path) {
    final m = _obj(v, path, {'id', 'title', 'theme', 'start', 'nodes'});
    if (m == null) return null;
    final id = _str(m, 'id', path);
    final title = _str(m, 'title', path);
    final start = _str(m, 'start', path);
    final rawNodes = _list(m, 'nodes', path);
    final nodes = <String, Node>{};
    for (var i = 0; i < (rawNodes?.length ?? 0); i++) {
      final node = _node(rawNodes![i], '$path.nodes[$i]');
      if (node == null) continue;
      if (nodes.containsKey(node.id)) {
        _err('$path.nodes[$i]', 'identifiant de noeud en double "${node.id}"');
      } else {
        nodes[node.id] = node;
      }
    }
    if (id == null || title == null || start == null) return null;
    return Chapter(
      id: id, title: title, start: start, nodes: nodes,
      theme: _str(m, 'theme', path, required: false),
    );
  }

  List<Meditation> _meditations(Map<String, Object?> m, String path) {
    final raw = _list(m, 'meditations', path, required: false);
    final out = <Meditation>[];
    final seen = <String>{};
    for (var i = 0; i < (raw?.length ?? 0); i++) {
      final p = '$path.meditations[$i]';
      final mm = _obj(raw![i], p, {
        'id', 'passage', 'reflectionPrompt', 'question', 'options', 'answerIndex',
      });
      if (mm == null) continue;
      final id = _str(mm, 'id', p);
      final passage = _str(mm, 'passage', p);
      final prompt = _str(mm, 'reflectionPrompt', p);
      final question = _str(mm, 'question', p);
      final answerIndex = _int(mm, 'answerIndex', p);
      final options = _strList(mm, 'options', p);
      if (options.length < 2) _err('$p.options', 'au moins deux options attendues');
      if (answerIndex != null && (answerIndex < 0 || answerIndex >= options.length)) {
        _err('$p.answerIndex', 'indice hors des options');
      }
      if (id != null && !seen.add(id)) _err(p, 'identifiant de meditation en double "$id"');
      if (id == null || passage == null || prompt == null || question == null ||
          answerIndex == null) {
        continue;
      }
      out.add(Meditation(
        id: id, passage: passage, reflectionPrompt: prompt, question: question,
        options: options, answerIndex: answerIndex,
      ));
    }
    return out;
  }

  Arc? arc(Object? json) {
    const path = r'$';
    final m = _obj(json, path, {
      'schemaVersion', 'id', 'title', 'version', 'minEngineVersion',
      'defaultBible', 'bibles', 'verses', 'chapters', 'meditations',
    });
    if (m == null) return null;

    final schemaVersion = _int(m, 'schemaVersion', path);
    if (schemaVersion != null && schemaVersion != supportedSchemaVersion) {
      _err('$path.schemaVersion',
          'version $schemaVersion non prise en charge (attendu $supportedSchemaVersion)');
    }
    final id = _str(m, 'id', path);
    if (id != null && !_idPattern.hasMatch(id)) {
      _err('$path.id', 'identifiant invalide "$id"');
    }
    final title = _str(m, 'title', path);
    final version = _str(m, 'version', path);
    if (version != null && !_semver.hasMatch(version)) {
      _err('$path.version', 'version semantique attendue (x.y.z)');
    }
    final minEngine = _int(m, 'minEngineVersion', path);
    if (minEngine != null && minEngine > engineVersion) {
      _err('$path.minEngineVersion',
          'arc exigeant le moteur $minEngine (moteur actuel : $engineVersion)');
    }
    final defaultBible = _str(m, 'defaultBible', path);

    final bibles = <String, BibleVersionInfo>{};
    final rawBibles = _obj(m['bibles'], '$path.bibles', null);
    if (rawBibles != null) {
      for (final e in rawBibles.entries) {
        final bp = '$path.bibles.${e.key}';
        final bm = _obj(e.value, bp, {'name', 'license', 'attribution'});
        if (bm == null) continue;
        final name = _str(bm, 'name', bp);
        final license = _str(bm, 'license', bp);
        if (name != null && license != null) {
          bibles[e.key] = BibleVersionInfo(
            name: name, license: license,
            attribution: _str(bm, 'attribution', bp, required: false),
          );
        }
      }
      if (rawBibles.isEmpty) _err('$path.bibles', 'au moins une version biblique attendue');
    }
    if (defaultBible != null && rawBibles != null && !bibles.containsKey(defaultBible)) {
      _err('$path.defaultBible', 'version "$defaultBible" absente de "bibles"');
    }

    final verses = <String, Map<String, String>>{};
    final rawVerses = m['verses'];
    if (rawVerses == null) {
      _err('$path.verses', 'champ obligatoire');
    } else if (rawVerses is! Map<String, Object?>) {
      _err('$path.verses', 'objet attendu');
    } else {
      for (final e in rawVerses.entries) {
        final vm = e.value;
        if (vm is! Map<String, Object?>) {
          _err('$path.verses.${e.key}', 'objet attendu (identifiant de verset -> texte)');
          continue;
        }
        final table = <String, String>{};
        for (final ve in vm.entries) {
          final text = ve.value;
          if (text is String && text.trim().isNotEmpty) {
            table[ve.key] = text;
          } else {
            _err('$path.verses.${e.key}.${ve.key}', 'texte non vide attendu');
          }
        }
        verses[e.key] = table;
      }
    }

    final rawChapters = _list(m, 'chapters', path);
    final chapters = <Chapter>[];
    final seen = <String>{};
    for (var i = 0; i < (rawChapters?.length ?? 0); i++) {
      final c = _chapter(rawChapters![i], '$path.chapters[$i]');
      if (c == null) continue;
      if (!seen.add(c.id)) _err('$path.chapters[$i]', 'identifiant de chapitre en double "${c.id}"');
      chapters.add(c);
    }
    if (rawChapters != null && rawChapters.isEmpty) {
      _err('$path.chapters', 'au moins un chapitre attendu');
    }

    if (schemaVersion == null || id == null || title == null || version == null ||
        minEngine == null || defaultBible == null) {
      return null;
    }
    return Arc(
      schemaVersion: schemaVersion, id: id, title: title, version: version,
      minEngineVersion: minEngine, defaultBible: defaultBible, bibles: bibles,
      verses: verses, chapters: chapters, meditations: _meditations(m, path),
    );
  }
}
