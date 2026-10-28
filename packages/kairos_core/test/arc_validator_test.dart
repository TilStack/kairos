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
        o['next'] = 'm2d';
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

  group('personnages', () {
    List<Map<String, Object?>> chars(Map<String, Object?> json) =>
        (json['characters']! as List<Object?>).cast<Map<String, Object?>>();

    test('la distribution est lue : neuf acteurs, apparence complete', () {
      final arc = parseArc(baseJson());
      expect(arc.characters.keys, hasLength(9));
      final lumo = arc.characters['lumo']!;
      expect(lumo.glasses, isTrue);
      expect(lumo.prop, 'lamp');
      expect(lumo.flameHead, isFalse);
      expect(arc.characters['joseph']!.stripes, hasLength(5));
      expect(arc.characters['benjamin']!.scale, 0.8);
      expect(arc.characters['murmure']!.glowingEyes, isTrue);
      expect(arc.characters['pharaon']!.headwear, 'nemes');
    });

    test('noeuds : personnage, humeur et action lus', () {
      final arc = parseArc(baseJson());
      final n = arc.chapters.first.nodes['n1']!;
      expect((n.character, n.mood, n.action), ('lumo', 'happy', 'wave'));
    });

    test('personnage mis en scene mais absent de la distribution : erreur', () {
      final json = baseJson();
      node(json, 0, 'n1')['character'] = 'fantome';
      final report = validate(json);
      expect(report.errors.any((i) => i.message.contains('"fantome"')), isTrue);
    });

    test('personnage declare mais jamais utilise : avertissement non bloquant', () {
      final json = baseJson();
      chars(json).add({'id': 'figurant', 'name': 'Figurant', 'skin': '#AA8866', 'outfit': '#445566'});
      final report = validate(json);
      expect(report.ok, isTrue);
      expect(report.warnings.any((i) => i.location.contains('figurant')), isTrue);
    });

    test('couleur invalide refusee avec son chemin', () {
      final json = baseJson();
      chars(json).first['skin'] = 'jaune';
      expect(parseErrors(json).any((e) => e.contains('characters[0].skin') && e.contains('#RRGGBB')), isTrue);
    });

    test('humeur, action, coiffe et accessoire hors liste refuses', () {
      final json = baseJson();
      node(json, 0, 'n1')['mood'] = 'furieux';
      node(json, 0, 'n1b')['action'] = 'voler';
      chars(json)[1]['headwear'] = 'couronne';
      chars(json)[1]['prop'] = 'epee';
      final errors = parseErrors(json);
      expect(errors.where((e) => e.contains('valeur inconnue')).length, 4);
    });

    test('identifiant de personnage en double', () {
      final json = baseJson();
      chars(json)[1]['id'] = 'lumo';
      expect(parseErrors(json).any((e) => e.contains('en double')), isTrue);
    });

    test('echelle hors bornes et booleen invalide', () {
      final json = baseJson();
      chars(json)[0]['scale'] = 4;
      chars(json)[0]['flameHead'] = 'oui';
      final errors = parseErrors(json);
      expect(errors.any((e) => e.contains('scale')), isTrue);
      expect(errors.any((e) => e.contains('flameHead')), isTrue);
    });

    test('cle inconnue dans une fiche de personnage (faute de frappe)', () {
      final json = baseJson();
      chars(json).first['couleurPeau'] = '#000000';
      expect(parseErrors(json).any((e) => e.contains('couleurPeau')), isTrue);
    });

    test('arc sans distribution : toujours valide (personnages optionnels)', () {
      final json = baseJson()..remove('characters');
      for (final c in [0, 1]) {
        for (final n in nodesOf(json, c)) {
          n.remove('character');
        }
      }
      expect(validate(json).ok, isTrue);
    });
  });

  group('lieux des scenes', () {
    test('un noeud sans lieu herite du precedent, y compris apres un choix', () {
      final arc = parseArc(baseJson());
      final ch1 = resolveSettings(arc.chapters[0]);
      expect(ch1['n1'], 'desert');
      expect(ch1['n1b'], 'desert'); // herite
      expect(ch1['n2'], 'desert');
      expect(ch1['n2a'], 'house'); // declare
      expect(ch1['n5'], 'house'); // herite de la maison jusqu'a la fin
      final ch2 = resolveSettings(arc.chapters[1]);
      expect(ch2['m1c'], 'palace');
      expect(ch2['m1e'], 'memory');
      expect(ch2['m2'], 'palace'); // retour au palais declare
      expect(ch2['m3'], 'palace');
    });

    test('aucun lieu declare : repli fourni', () {
      final json = baseJson();
      for (final c in [0, 1]) {
        for (final n in nodesOf(json, c)) {
          n.remove('setting');
        }
      }
      final arc = parseArc(json);
      expect(resolveSettings(arc.chapters[0], fallback: 'house').values.toSet(), {'house'});
    });

    test('lieu inconnu refuse', () {
      final json = baseJson();
      node(json, 0, 'n1')['setting'] = 'lune';
      expect(parseErrors(json).any((e) => e.contains('valeur inconnue') && e.contains('setting')), isTrue);
    });
  });
}
