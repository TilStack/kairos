import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:kairos_core/kairos_core.dart';

import '../../adventure/guidance.dart';
import '../../adventure/stone_button.dart';
import '../../app/l10n.dart';
import '../../app/palette.dart';
import '../../app/sfx.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../game/key_forge_game.dart';

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
    this.celebrate = false,
  });

  final DoorChallenge challenge;
  final String prompt;

  /// Libelle de la reference, ex. `Genèse 39:9`.
  final String reference;
  final VoidCallback onFinished;

  /// Joue la scene Flame quand la Cle est forgee.
  final bool celebrate;

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
  late final KeyForgeGame _game = KeyForgeGame();

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
        // Wrap et non Row : sur petit ecran ou police agrandie, la reference
        // passe a la ligne au lieu de deborder.
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(levelLabel(context, _c.level))),
            Text(widget.reference, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        if (!done) ...[
          InstructionBanner(
            icon: Icons.vpn_key,
            title: context.tr('door.forge'),
            text: context.tr('door.instr.${_c.level}'),
          ),
          const SizedBox(height: 10),
          _Attempts(left: _c.attemptsLeft),
          const SizedBox(height: 12),
          ..._exercise(theme),
        ],
        if (_last != null) _feedback(theme),
        const SizedBox(height: 16),
        if (done)
          StoneButton(
            key: const ValueKey('door-continue'),
            label: context.tr('door.continue'),
            fontSize: 20,
            height: 56,
            style: StoneStyle.moss,
            onPressed: widget.onFinished,
          )
        else ...[
          StoneButton(
            key: const ValueKey('door-verify'),
            label: context.tr('door.verify'),
            fontSize: 20,
            height: 56,
            onPressed: _canSubmit ? _check : null,
          ),
          if (!_canSubmit)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr('door.place_all'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, color: inkSoft),
              ),
            ),
        ],
      ],
    );
  }

  /// Verifie la reponse, puis joue le son de reussite ou d'erreur. (Le clic du
  /// bouton est deja joue par le bouton : on ajoute le resultat apres.)
  void _check() {
    _submit();
    playSfx(context, _last!.correct ? Sfx.success : Sfx.error);
  }

  bool get _canSubmit => switch (_c.level) {
        1 => _placed.length == _c.scrambled.length,
        _ => true,
      };

  List<Widget> _exercise(ThemeData theme) {
    switch (_c.level) {
      case 1:
        return [
          Container(
            constraints: const BoxConstraints(minHeight: 72),
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x1A5B3A1A),
              border: Border.all(color: cardBorder, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _placed.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      context.tr('door.slot_empty'),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: inkSoft),
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      for (final i in _placed)
                        PlacedWordTile(
                          key: ValueKey('placed-$i'),
                          label: _c.scrambled[i],
                          onPressed: () => setState(() => _placed.remove(i)),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _c.scrambled.length; i++)
                if (!_placed.contains(i))
                  WordTile(
                    key: ValueKey('word-$i'),
                    label: _c.scrambled[i],
                    onPressed: () => setState(() => _placed.add(i)),
                  ),
            ],
          ),
        ];
      case 2:
        final display = _c.gaps.display;
        var gap = 0;
        return [
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
          TextField(
            key: const ValueKey('recall-verse'),
            controller: _verseField,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: context.tr('door.verse'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('recall-ref'),
            controller: _refField,
            decoration: InputDecoration(
              labelText: context.tr('door.ref'),
              border: const OutlineInputBorder(),
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
      final card = StoneCard(
        child: Row(
          children: [
            const Icon(Icons.vpn_key, color: lampGold, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('door.forged'), style: theme.textTheme.titleMedium),
                  Text(context.tr(_c.hintsUsed == 0 ? 'door.no_hint' : 'door.in_chest')),
                ],
              ),
            ),
          ],
        ),
      );
      if (!widget.celebrate) return card;
      return Column(
        children: [
          SizedBox(
            key: const ValueKey('key-forge-scene'),
            height: 230,
            child: GameWidget(game: _game),
          ),
          card,
        ],
      );
    }
    if (r.status == DoorStatus.exhausted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('door.exhausted')),
          ScriptureBlock(reference: widget.reference, text: _c.verse),
        ],
      );
    }
    return StoneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('door.miss', {'n': r.attemptsLeft, 's': r.attemptsLeft > 1 ? 's' : ''})),
          if (r.hint != null) ...[
            const SizedBox(height: 6),
            Text(context.tr('door.hint', {'h': r.hint!}), style: const TextStyle(fontFamily: 'serif')),
          ],
        ],
      ),
    );
  }
}

/// Essais restants, en pastilles : le joueur voit combien de chances il a.
class _Attempts extends StatelessWidget {
  const _Attempts({required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('door.attempts.semantic', {'n': left, 'total': failuresBeforeFallback}),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Text(context.tr('door.attempts'), style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
            const SizedBox(width: 10),
            for (var i = 0; i < failuresBeforeFallback; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < left ? lampGold : Colors.transparent,
                    border: Border.all(color: ink, width: 2),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                context.tr('door.attempts.hint'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
