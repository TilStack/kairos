import '../verse/bible_ref.dart';
import 'models.dart';

enum Severity { error, warning }

class Issue {
  const Issue(this.severity, this.location, this.message);
  final Severity severity;
  final String location;
  final String message;

  @override
  String toString() =>
      '${severity == Severity.error ? 'ERREUR' : 'AVERT.'} $location : $message';
}

class ValidationReport {
  const ValidationReport(this.issues);
  final List<Issue> issues;

  Iterable<Issue> get errors => issues.where((i) => i.severity == Severity.error);
  Iterable<Issue> get warnings => issues.where((i) => i.severity == Severity.warning);

  /// Publiable : aucune erreur (les avertissements ne bloquent pas).
  bool get ok => errors.isEmpty;
}

/// Verifie un arc deja lu : integrite du graphe et des references bibliques.
///
/// Exigences du CDC §9.6 / UC-12 : aucun noeud orphelin, graphe complet,
/// references bibliques presentes dans toutes les versions declarees.
ValidationReport validateArc(Arc arc) {
  final issues = <Issue>[];
  void error(String where, String msg) =>
      issues.add(Issue(Severity.error, where, msg));
  void warn(String where, String msg) =>
      issues.add(Issue(Severity.warning, where, msg));

  // ---- verset : format + presence dans chaque version
  final usedVerses = <String>{};
  void checkVerse(String where, String id) {
    usedVerses.add(id);
    if (BibleRef.tryParse(id) == null || !RegExp(r'^[1-3]?[A-Z]{2,3}\.\d+\.\d+(-\d+)?$').hasMatch(id)) {
      error(where, 'identifiant de verset invalide "$id" (attendu : GEN.39.9)');
      return;
    }
    for (final bible in arc.bibles.keys) {
      if (arc.verses[bible]?[id] == null) {
        error(where, 'verset $id absent de la version $bible');
      }
    }
  }

  for (final bible in arc.verses.keys) {
    if (!arc.bibles.containsKey(bible)) {
      error('verses.$bible', 'version non declaree dans "bibles"');
    }
  }
  for (final bible in arc.bibles.keys) {
    if (!arc.verses.containsKey(bible)) {
      error('verses', 'aucun verset fourni pour la version $bible');
    }
  }

  final usedCharacters = <String>{};
  final setFlags = <String>{};
  final readFlags = <String, String>{};

  void collectCondition(String where, Condition? c) {
    if (c == null) return;
    for (final f in {...c.flags, ...c.notFlags}) {
      readFlags.putIfAbsent(f, () => where);
    }
    for (final k in c.keys) {
      checkVerse('$where.keys', k);
    }
  }

  for (final chapter in arc.chapters) {
    final at = 'chapitre ${chapter.id}';
    final nodes = chapter.nodes;

    if (!nodes.containsKey(chapter.start)) {
      error(at, 'noeud de depart "${chapter.start}" introuvable');
    }

    // ---- aretes
    final edges = <String, Set<String>>{};
    for (final node in nodes.values) {
      final where = '$at / ${node.id}';
      setFlags.addAll(node.effects.setFlags);
      for (final r in node.refs) {
        checkVerse('$where.refs', r);
      }
      final who = node.character;
      if (who != null) {
        usedCharacters.add(who);
        if (!arc.characters.containsKey(who)) {
          error(where, 'personnage "$who" absent de "characters"');
        }
      }

      void checkTransitions(String owner, List<Transition> list) {
        for (final t in list) {
          if (!nodes.containsKey(t.to)) {
            error(owner, 'transition vers un noeud inexistant "${t.to}"');
          } else {
            edges.putIfAbsent(node.id, () => {}).add(t.to);
          }
          collectCondition('$owner.if', t.requires);
        }
        if (list.isNotEmpty && list.last.requires != null) {
          error(owner, 'la derniere transition doit etre sans condition '
              '(sinon le joueur peut se retrouver bloque)');
        }
      }

      switch (node) {
        case DialogueNode():
          checkTransitions(where, node.next);
        case DoorNode():
          checkVerse('$where.verse', node.verse);
          checkTransitions(where, node.next);
        case DiscernmentNode():
          if (node.correctRef != null) checkVerse('$where.correctRef', node.correctRef!);
          if (node.claimedRef != null && BibleRef.tryParse(node.claimedRef!) == null) {
            warn(where, 'claimedRef "${node.claimedRef}" n\'est pas une reference reconnue');
          }
          checkTransitions(where, node.next);
        case DebriefNode():
          for (final v in node.verses) {
            checkVerse('$where.verses', v);
          }
          if (node.verses.isEmpty) {
            warn(where, 'debriefing sans verset (RF-02 : texte exact requis)');
          }
          checkTransitions(where, node.next);
        case ChoiceNode():
          final ids = <String>{};
          for (final o in node.options) {
            final ow = '$where/${o.id}';
            if (!ids.add(o.id)) error(ow, 'identifiant d\'option en double');
            setFlags.addAll(o.effects.setFlags);
            collectCondition('$ow.requires', o.requires);
            checkTransitions(ow, o.next);
          }
          if (node.options.isNotEmpty && node.options.every((o) => o.requires != null)) {
            error(where, 'toutes les options sont conditionnelles : '
                'aucune n\'est garantie visible');
          }
          if (node.options.isEmpty) error(where, 'choix sans option');
        case EndNode():
          break;
      }
    }

    // ---- orphelins (atteignabilite depuis le depart)
    final reachable = <String>{};
    final queue = <String>[if (nodes.containsKey(chapter.start)) chapter.start];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (!reachable.add(id)) continue;
      queue.addAll(edges[id] ?? const {});
    }
    for (final id in nodes.keys) {
      if (!reachable.contains(id)) {
        error('$at / $id', 'noeud orphelin : inatteignable depuis "${chapter.start}"');
      }
    }

    // ---- impasses : chaque noeud atteignable doit pouvoir atteindre une fin
    final ends = nodes.values.whereType<EndNode>().map((n) => n.id).toSet();
    if (ends.isEmpty) error(at, 'aucun noeud de fin');
    final canEnd = {...ends};
    var changed = true;
    while (changed) {
      changed = false;
      for (final e in edges.entries) {
        if (!canEnd.contains(e.key) && e.value.any(canEnd.contains)) {
          canEnd.add(e.key);
          changed = true;
        }
      }
    }
    for (final id in reachable) {
      if (!canEnd.contains(id)) {
        error('$at / $id', 'impasse : aucune suite ne mene a une fin de chapitre');
      }
    }

    // ---- exigences pedagogiques
    if (!nodes.values.any((n) => n is DebriefNode)) {
      error(at, 'aucun debriefing biblique (RF-02)');
    }
    if (!nodes.values.any((n) => n is DiscernmentNode)) {
      warn(at, 'aucun defi de discernement (MVP : 1 par chapitre)');
    }
  }

  for (final id in arc.characters.keys) {
    if (!usedCharacters.contains(id)) {
      warn('characters.$id', 'personnage jamais mis en scene');
    }
  }

  for (final med in arc.meditations) {
    checkVerse('meditation ${med.id}.passage', med.passage);
  }
  if (arc.meditations.isEmpty) {
    warn('meditations', 'aucun passage de meditation (UC-04 : Huile)');
  }

  for (final e in readFlags.entries) {
    if (!setFlags.contains(e.key)) {
      warn(e.value, 'drapeau "${e.key}" lu mais jamais pose (faute de frappe ?)');
    }
  }

  for (final bible in arc.verses.entries) {
    for (final id in bible.value.keys) {
      if (!usedVerses.contains(id)) {
        warn('verses.${bible.key}.$id', 'verset jamais utilise par l\'arc');
      }
    }
  }

  return ValidationReport(issues);
}
