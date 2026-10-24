import 'package:flutter/material.dart';
import 'package:kairos_core/kairos_core.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';

/// Graine stable (FNV-1a 32 bits) : `String.hashCode` varie d'une execution a
/// l'autre, or le melange d'une Porte doit rester identique a la reprise.
int stableSeed(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Porte : defi de memorisation d'un verset (niveaux 1 a 3).
/// Jamais bloquante : apres trois essais, le recit continue.
class DoorView extends StatefulWidget {
  const DoorView({
    super.key,
    required this.challenge,
    required this.prompt,
    required this.reference,
    required this.onFinished,
  });

  final DoorChallenge challenge;
  final String prompt;

  /// Libelle de la reference, ex. `Genèse 39:9`.
  final String reference;
  final VoidCallback onFinished;

  @override
  State<DoorView> createState() => _DoorViewState();
}

class _DoorViewState extends State<DoorView> {
  // Niveau 1 : indices (dans `scrambled`) poses dans l'ordre.
  final _placed = <int>[];
  // Niveau 2 : un champ par trou.
  late final List<TextEditingController> _gapFields;
  // Niveau 3.
  final _verseField = TextEditingController();
  final _refField = TextEditingController();

  AttemptResult? _last;

  DoorChallenge get _c => widget.challenge;

  @override
  void initState() {
    super.initState();
    _gapFields = [for (final _ in _c.gaps.gapIndexes) TextEditingController()];
  }

  @override
  void dispose() {
    for (final f in _gapFields) {
      f.dispose();
    }
    _verseField.dispose();
    _refField.dispose();
    super.dispose();
  }

  void _submit() {
    final AttemptResult result;
    switch (_c.level) {
      case 1:
        result = _c.submitOrder([for (final i in _placed) _c.scrambled[i]]);
      case 2:
        result = _c.submitGaps([for (final f in _gapFields) f.text]);
      default:
        result = _c.submitRecall(_verseField.text, _refField.text);
    }
    setState(() {
      _last = result;
      if (!result.correct && _c.level == 1) _placed.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = _c.status != DoorStatus.inProgress;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(widget.prompt, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Chip(label: Text(levelLabels[_c.level]!)),
            const SizedBox(width: 8),
            Flexible(child: Text(widget.reference, style: theme.textTheme.labelLarge)),
          ],
        ),
        const SizedBox(height: 12),
        if (!done) ..._exercise(theme),
        if (_last != null) _feedback(theme),
        const SizedBox(height: 16),
        if (done)
          FilledButton(onPressed: widget.onFinished, child: const Text('Continuer'))
        else
          FilledButton(onPressed: _canSubmit ? _submit : null, child: const Text('Vérifier')),
      ],
    );
  }

  bool get _canSubmit => switch (_c.level) {
        1 => _placed.length == _c.scrambled.length,
        _ => true,
      };

  List<Widget> _exercise(ThemeData theme) {
    switch (_c.level) {
      case 1:
        return [
          const Text('Touche les mots dans le bon ordre.'),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in _placed)
                  InputChip(
                    key: ValueKey('placed-$i'),
                    label: Text(_c.scrambled[i]),
                    onPressed: () => setState(() => _placed.remove(i)),
                    onDeleted: () => setState(() => _placed.remove(i)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _c.scrambled.length; i++)
                if (!_placed.contains(i))
                  ActionChip(
                    key: ValueKey('word-$i'),
                    label: Text(_c.scrambled[i]),
                    onPressed: () => setState(() => _placed.add(i)),
                  ),
            ],
          ),
        ];
      case 2:
        final display = _c.gaps.display;
        var gap = 0;
        return [
          const Text('Complète les mots manquants.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final word in display)
                if (word != null)
                  Text(word, style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'serif'))
                else
                  _gapField(gap++),
            ],
          ),
        ];
      default:
        return [
          const Text('Écris le verset de mémoire, puis sa référence.'),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('recall-verse'),
            controller: _verseField,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Verset', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('recall-ref'),
            controller: _refField,
            decoration: const InputDecoration(
              labelText: 'Référence (ex. Jean 3:16)',
              border: OutlineInputBorder(),
            ),
          ),
        ];
    }
  }

  Widget _gapField(int index) {
    final result = _last?.gapResults;
    final ok = result != null && index < result.length ? result[index] : null;
    return SizedBox(
      width: 110,
      child: TextField(
        key: ValueKey('gap-$index'),
        controller: _gapFields[index],
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: ok == false ? Colors.red : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _feedback(ThemeData theme) {
    final r = _last!;
    if (r.correct) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.vpn_key, color: lampGold),
          title: const Text('La Clé est forgée.'),
          subtitle: Text(_c.hintsUsed == 0 ? 'Sans aucun indice : bravo.' : 'Elle est rangée dans ton coffre.'),
        ),
      );
    }
    if (r.status == DoorStatus.exhausted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('La Porte s\'ouvre malgré tout. La Clé t\'attend : tu y reviendras.'),
          ScriptureBlock(reference: widget.reference, text: _c.verse),
        ],
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pas tout à fait. Il te reste ${r.attemptsLeft} essai${r.attemptsLeft > 1 ? 's' : ''}.'),
            if (r.hint != null) ...[
              const SizedBox(height: 6),
              Text('Indice : ${r.hint}', style: const TextStyle(fontFamily: 'serif')),
            ],
          ],
        ),
      ),
    );
  }
}
