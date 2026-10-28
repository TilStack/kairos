import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';

import '../../adventure/game_page.dart';
import '../../adventure/stone_button.dart';
import '../../app/controllers.dart';
import '../../characters/cast.dart';
import '../../characters/pose.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';

/// Messages doux : on invite a recommencer, sans reproche ni honte.
const rejectionMessages = {
  MeditationRejection.tooFast: 'Prends encore un moment pour lire et méditer le passage.',
  MeditationRejection.wrongAnswer: 'Relis le passage : la réponse s\'y trouve.',
  MeditationRejection.reflectionTooShort:
      'Écris quelques mots de plus ($minReflectionChars caractères au moins).',
  MeditationRejection.alreadyDone: 'Tu as déjà médité aujourd\'hui. À demain !',
};

/// Meditation quotidienne : seule facon de recharger l'Huile. Disponible
/// hors ligne, jamais achetable (CDC §4.4).
class MeditationScreen extends ConsumerStatefulWidget {
  const MeditationScreen({super.key});

  @override
  ConsumerState<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends ConsumerState<MeditationScreen> {
  late final DateTime _openedAt;
  final _reflection = TextEditingController();
  int? _answer;
  String? _message;
  MeditationResult? _done;

  @override
  void initState() {
    super.initState();
    _openedAt = ref.read(clockProvider)();
  }

  @override
  void dispose() {
    _reflection.dispose();
    super.dispose();
  }

  Future<void> _submit(Meditation meditation) async {
    final readSeconds = ref.read(clockProvider)().difference(_openedAt).inSeconds;
    final result = await ref.read(lampProvider.notifier).meditate(
          meditation,
          MeditationAttempt(
            readSeconds: readSeconds,
            answerIndex: _answer,
            reflection: _reflection.text,
          ),
        );
    if (!mounted) return;
    setState(() {
      _message = result.rejection == null ? null : rejectionMessages[result.rejection]!;
      if (result.accepted) _done = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    final lampAsync = ref.watch(lampProvider);
    final today = dayNumber(ref.read(clockProvider)());
    final meditation = meditationForDay(arc, today);
    final theme = Theme.of(context);

    final lumo = ref.watch(castProvider)['lumo'] ?? Cast.lumo;
    return GamePage(
      title: 'Ma lampe',
      setting: 'house',
      character: lumo,
      // Lumo se rejouit quand la lampe vient d'etre rechargee.
      action: _done != null ? CharacterAction.cheer : CharacterAction.idle,
      speakerName: 'Lumo',
      panelFraction: 0.7,
      child: lampAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (lamp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LampGauge(lamp: lamp),
            const SizedBox(height: 12),
            if (_done != null) _blessing(theme, _done!)
            else if (meditation == null)
              const Text('Aucun passage de méditation disponible pour cet arc.')
            else if (lamp.meditatedOn(today))
              const Card(child: ListTile(
                leading: Icon(Icons.check_circle),
                title: Text('Tu as médité aujourd\'hui.'),
                subtitle: Text('Ta lampe brille. Reviens demain.'),
              ))
            else
              ..._form(theme, arc, meditation),
          ],
        ),
      ),
    );
  }

  Widget _blessing(ThemeData theme, MeditationResult result) {
    return Card(
      key: const ValueKey('blessing'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ta lampe est rechargée.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (result.goldVialEarned)
              const Text('Sept jours de fidélité : une fiole d\'or t\'est offerte !'),
            const SizedBox(height: 8),
            const ScriptureBlock(
              reference: 'Psaumes 119:105',
              text: 'Ta parole est une lampe à mes pieds, Et une lumière sur mon sentier.',
            ),
            const Text('Ta méditation a été ajoutée à ton Journal.'),
          ],
        ),
      ),
    );
  }

  List<Widget> _form(ThemeData theme, Arc arc, Meditation m) {
    final ref0 = BibleRef.tryParse(m.passage)?.label ?? m.passage;
    return [
      Text('Passage du jour', style: theme.textTheme.titleMedium),
      ScriptureBlock(reference: ref0, text: arc.verseText(m.passage)),
      const SizedBox(height: 8),
      Text(m.question, style: theme.textTheme.titleSmall),
      RadioGroup<int>(
        groupValue: _answer,
        onChanged: (v) => setState(() => _answer = v),
        child: Column(
          children: [
            for (var i = 0; i < m.options.length; i++)
              RadioListTile<int>(
                key: ValueKey('answer-$i'),
                value: i,
                title: Text(m.options[i]),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(m.reflectionPrompt, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      TextField(
        key: const ValueKey('reflection'),
        controller: _reflection,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Ta réflexion reste privée, sur ton téléphone.',
        ),
      ),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(_message!, key: const ValueKey('rejection'), style: TextStyle(color: theme.colorScheme.primary)),
        ),
      const SizedBox(height: 16),
      StoneButton(
        key: const ValueKey('meditate'),
        label: 'RECHARGER MA LAMPE',
        fontSize: 19,
        height: 60,
        style: StoneStyle.moss,
        leading: const Icon(Icons.local_fire_department, color: Color(0xFFC0501F)),
        onPressed: () => _submit(m),
      ),
    ];
  }
}
