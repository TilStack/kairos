import 'dart:convert';
import 'dart:io';

import 'package:kairos_core/kairos_core.dart';
import 'package:test/test.dart';

Map<String, Object?> baseJson() =>
    jsonDecode(File('../../content/test_arc/arc.json').readAsStringSync())
        as Map<String, Object?>;

List<Map<String, Object?>> nodesOf(Map<String, Object?> arc, int chapter) =>
    (((arc['chapters']! as List<Object?>)[chapter]! as Map<String, Object?>)['nodes']!
            as List<Object?>)
        .cast<Map<String, Object?>>();

Map<String, Object?> node(Map<String, Object?> arc, int chapter, String id) =>
    nodesOf(arc, chapter).firstWhere((n) => n['id'] == id);

ValidationReport validate(Map<String, Object?> json) => validateArc(parseArc(json));

List<String> parseErrors(Map<String, Object?> json) {
  try {
    parseArc(json);
  } on ArcFormatException catch (e) {
    return e.errors;
  }
  return const [];
}

void main() {
  group('arc de test', () {
    test('valide, sans erreur ni avertissement', () {
      final report = validate(baseJson());
      expect(report.issues, isEmpty, reason: report.issues.join('\n'));
      expect(report.ok, isTrue);
    });
  });

  group('format (parseur)', () {
    test('JSON illisible', () {
      expect(() => parseArcString('{ pas du json'), throwsA(isA<ArcFormatException>()));
    });

    test('champ obligatoire manquant localise par chemin', () {
      final json = baseJson()..remove('title');
      expect(parseErrors(json), contains(r'$.title : champ obligatoire'));
    });

    test('cle inconnue refusee (faute de frappe)', () {
      final json = baseJson();
      node(json, 0, 'n1')['txet'] = 'oups';
      expect(parseErrors(json).any((e) => e.contains('txet') && e.contains('cle inconnue')), isTrue);
    });

    test('type de noeud inconnu', () {
      final json = baseJson();
      node(json, 0, 'n1')['type'] = 'monologue';
      expect(parseErrors(json).any((e) => e.contains('type inconnu')), isTrue);
    });

    test('trait inconnu dans les effets', () {
      final json = baseJson();
      (node(json, 0, 'n2')['options']! as List<Object?>).cast<Map<String, Object?>>().first['effects'] =
          {'traits': {'bravoure': 1}};
      expect(parseErrors(json).any((e) => e.contains('trait inconnu "bravoure"')), isTrue);
    });

    test('anomalie inconnue', () {
      final json = baseJson();
      node(json, 0, 'n3')['anomaly'] = 'inventee';
      expect(parseErrors(json).any((e) => e.contains('anomalie inconnue')), isTrue);
    });

    test('identifiant de noeud en double', () {
      final json = baseJson();
      nodesOf(json, 0).add({'id': 'n1', 'type': 'end'});
      expect(parseErrors(json).any((e) => e.contains('en double')), isTrue);
    });

    test('version de schema et de moteur incompatibles', () {
      expect(parseErrors(baseJson()..['schemaVersion'] = 99).any((e) => e.contains('schemaVersion')), isTrue);
      expect(parseErrors(baseJson()..['minEngineVersion'] = engineVersion + 1)
          .any((e) => e.contains('minEngineVersion')), isTrue);
    });

    test('version semantique obligatoire', () {
      expect(parseErrors(baseJson()..['version'] = '1.0').any((e) => e.contains('x.y.z')), isTrue);
    });

    test('plusieurs erreurs remontees d un coup', () {
      final json = baseJson()
        ..remove('title')
        ..['version'] = 'x';
      expect(parseErrors(json).length, greaterThanOrEqualTo(2));
    });
  });

  group('graphe', () {
    test('noeud orphelin detecte', () {
      final json = baseJson();
      nodesOf(json, 0).add({'id': 'orphelin', 'type': 'end'});
      final report = validate(json);
      expect(report.ok, isFalse);
      expect(report.errors.any((i) => i.message.contains('orphelin') && i.location.contains('orphelin')), isTrue);
    });

    test('transition vers un noeud inexistant', () {
      final json = baseJson();
      node(json, 0, 'n1')['next'] = 'fantome';
      expect(validate(json).errors.any((i) => i.message.contains('inexistant')), isTrue);
    });

    test('noeud de depart introuvable', () {
      final json = baseJson();
      ((json['chapters']! as List<Object?>)[0]! as Map<String, Object?>)['start'] = 'nulle-part';
      expect(validate(json).errors.any((i) => i.message.contains('depart')), isTrue);
    });

    test('derniere transition conditionnelle : risque de blocage', () {
      final json = baseJson();
      node(json, 1, 'm1')['next'] = [
        {'to': 'm2', 'if': {'flags': ['warned_joseph']}},
      ];
      expect(validate(json).errors.any((i) => i.message.contains('sans condition')), isTrue);
    });

    test('impasse : cycle sans issue', () {
      final json = baseJson();
      nodesOf(json, 0)
        ..add({'id': 'a', 'type': 'dialogue', 'text': 'a', 'next': 'b'})
        ..add({'id': 'b', 'type': 'dialogue', 'text': 'b', 'next': 'a'});
      node(json, 0, 'n1')['next'] = [
        {'to': 'a', 'if': {'flags': ['defended_joseph']}},
        {'to': 'n2'},
      ];
      final report = validate(json);
      expect(report.errors.any((i) => i.message.contains('impasse')), isTrue);
    });

    test('chapitre sans noeud de fin', () {
      final json = baseJson();
      final nodes = nodesOf(json, 1);
      node(json, 1, 'm4')['next'] = 'm1';
      nodes.removeWhere((n) => n['id'] == 'm5');
      expect(validate(json).errors.any((i) => i.message.contains('fin')), isTrue);
    });

    test('toutes les options conditionnelles : aucune garantie visible', () {
      final json = baseJson();
      final options =
          (node(json, 1, 'm2')['options']! as List<Object?>).cast<Map<String, Object?>>();
      for (final o in options) {
        o['requires'] = {'flags': ['defended_joseph']};
      }
      expect(validate(json).errors.any((i) => i.message.contains('conditionnelles')), isTrue);
    });
  });

  group('references bibliques', () {
    test('verset de porte absent de la table', () {
      final json = baseJson();
      node(json, 0, 'n4')['verse'] = 'JHN.3.16';
      final report = validate(json);
      expect(report.errors.any((i) => i.message.contains('JHN.3.16') && i.message.contains('absent')), isTrue);
    });

    test('identifiant de verset mal forme', () {
      final json = baseJson();
      node(json, 0, 'n4')['verse'] = 'Genese 39:9';
      expect(validate(json).errors.any((i) => i.message.contains('invalide')), isTrue);
    });

    test('verset manquant dans une version declaree', () {
      final json = baseJson();
      (json['bibles']! as Map<String, Object?>)['NEG'] = {'name': 'Nouvelle Edition de Geneve', 'license': 'sous licence'};
      (json['verses']! as Map<String, Object?>)['NEG'] = {'GEN.39.9': 'texte'};
      final report = validate(json);
      expect(report.errors.any((i) => i.message.contains('absent de la version NEG')), isTrue);
    });

    test('version par defaut non declaree', () {
      expect(parseErrors(baseJson()..['defaultBible'] = 'XYZ').any((e) => e.contains('defaultBible')), isTrue);
    });

    test('verset de la table jamais utilise : avertissement non bloquant', () {
      final json = baseJson();
      ((json['verses']! as Map<String, Object?>)['LSG1910']! as Map<String, Object?>)['PSA.119.105'] =
          'Ta parole est une lampe à mes pieds, Et une lumière sur mon sentier.';
      final report = validate(json);
      expect(report.ok, isTrue);
      expect(report.warnings.any((i) => i.location.contains('PSA.119.105')), isTrue);
    });
  });

  group('exigences pedagogiques et coherence', () {
    test('chapitre sans debriefing : erreur (RF-02)', () {
      final json = baseJson();
      final nodes = nodesOf(json, 1);
      node(json, 1, 'm3')['next'] = 'm5';
      nodes.removeWhere((n) => n['id'] == 'm4');
      final report = validate(json);
      expect(report.errors.any((i) => i.message.contains('debriefing')), isTrue);
    });

    test('chapitre sans discernement : avertissement', () {
      final json = baseJson();
      final nodes = nodesOf(json, 1);
      node(json, 1, 'm2b');
      for (final o in (node(json, 1, 'm2')['options']! as List<Object?>).cast<Map<String, Object?>>()) {
        o['next'] = 'm3';
      }
      nodes.removeWhere((n) => n['id'] == 'm2b');
      final report = validate(json);
      expect(report.ok, isTrue);
      expect(report.warnings.any((i) => i.message.contains('discernement')), isTrue);
    });

    test('drapeau lu mais jamais pose : avertissement', () {
      final json = baseJson();
      node(json, 1, 'm1')['next'] = [
        {'to': 'm1b', 'if': {'flags': ['drapeau_fantome']}},
        {'to': 'm2'},
      ];
      final report = validate(json);
      expect(report.warnings.any((i) => i.message.contains('drapeau_fantome')), isTrue);
    });

    test('identifiants d options en double', () {
      final json = baseJson();
      final options = (node(json, 0, 'n2')['options']! as List<Object?>).cast<Map<String, Object?>>();
      options[1]['id'] = options[0]['id'];
      expect(validate(json).errors.any((i) => i.message.contains('en double')), isTrue);
    });
  });
}
