import 'dart:io';

import 'package:kairos_core/kairos_core.dart';

const _usage = '''
Validateur d'arcs KAIROS.

Usage : dart run kairos_core:kairos_validate [--strict] <arc.json | dossier> [...]

  --strict   les avertissements font echouer la validation
  -h         aide

Codes de sortie : 0 valide, 1 arc invalide, 2 erreur d'usage.
''';

void main(List<String> args) {
  // `main` ne peut pas renvoyer de code de sortie : il faut passer par exitCode.
  exitCode = _run(args);
}

int _run(List<String> args) {
  final strict = args.contains('--strict');
  final paths = args.where((a) => !a.startsWith('-')).toList();
  if (args.contains('-h') || args.contains('--help')) {
    stdout.write(_usage);
    return 0;
  }
  if (paths.isEmpty) {
    stderr.write(_usage);
    return 2;
  }

  var failed = false;
  for (final input in paths) {
    final file = FileSystemEntity.isDirectorySync(input)
        ? File('$input${Platform.pathSeparator}arc.json')
        : File(input);
    stdout.writeln('== ${file.path}');
    if (!file.existsSync()) {
      stderr.writeln('  fichier introuvable');
      failed = true;
      continue;
    }

    final Arc arc;
    try {
      arc = parseArcString(file.readAsStringSync());
    } on ArcFormatException catch (e) {
      for (final err in e.errors) {
        stdout.writeln('  ERREUR $err');
      }
      stdout.writeln('  -> format invalide (${e.errors.length} erreur(s))');
      failed = true;
      continue;
    }

    final report = validateArc(arc);
    for (final issue in report.issues) {
      stdout.writeln('  $issue');
    }
    final errors = report.errors.length;
    final warnings = report.warnings.length;
    final blocked = errors > 0 || (strict && warnings > 0);
    stdout.writeln('  -> ${blocked ? 'INVALIDE' : 'valide'} : '
        '${arc.chapters.length} chapitre(s), $errors erreur(s), $warnings avertissement(s)');
    failed = failed || blocked;
  }
  return failed ? 1 : 0;
}
