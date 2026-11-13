import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';

import '../../adventure/game_page.dart';
import '../../adventure/guidance.dart';
import '../../adventure/stone_button.dart';
import '../../app/controllers.dart';
import '../../app/l10n.dart';
import '../../characters/cast.dart';
import '../../characters/pose.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';

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
  MeditationRejection? _rejection;
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
      _rejection = result.rejection;
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
      title: context.tr('med.title'),
      setting: 'house',
      character: lumo,
      // Lumo se rejouit quand la lampe vient d'etre rechargee.
      action: _done != null ? CharacterAction.cheer : CharacterAction.idle,
      speakerName: 'Lumo',
      panelFraction: 0.7,
      child: lampAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(context.tr('error', {'e': e})),
        data: (lamp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LampGauge(lamp: lamp),
            const SizedBox(height: 12),
            if (_done != null) _blessing(theme, _done!)
            else if (meditation == null)
              Text(context.tr('med.none'))
            else if (lamp.meditatedOn(today))
              StoneCard(
                child: ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: Text(context.tr('med.done.title')),
                  subtitle: Text(context.tr('med.done.sub')),
                ),
              )
            else
              ..._form(theme, arc, meditation),
          ],
        ),
      ),
    );
  }

  Widget _blessing(ThemeData theme, MeditationResult result) {
    return StoneCard(
      key: const ValueKey('blessing'),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('med.blessing'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (result.goldVialEarned)
              Text(context.tr('med.vial')),
            const SizedBox(height: 8),
            ScriptureBlock(
              reference: context.tr('med.psalm.ref'),
              text: context.tr('med.psalm.text'),
            ),
            Text(context.tr('med.journal_added')),
          ],
        ),
      ),
    );
  }

  List<Widget> _form(ThemeData theme, Arc arc, Meditation m) {
    final ref0 = BibleRef.tryParse(m.passage)?.labelIn(context.lang) ?? m.passage;
    return [
      InstructionBanner(
        icon: Icons.local_fire_department,
        title: context.tr('med.banner.title'),
        text: context.tr('med.banner.text'),
      ),
      StepHeading(number: 1, text: context.tr('med.step1')),
      ScriptureBlock(reference: ref0, text: arc.verseText(m.passage)),
      StepHeading(number: 2, text: context.tr('med.step2')),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(m.question, style: theme.textTheme.titleSmall),
      ),
      for (var i = 0; i < m.options.length; i++)
        StoneOption(
          key: ValueKey('answer-$i'),
          text: m.options[i],
          selected: _answer == i,
          onPressed: () => setState(() => _answer = i),
        ),
      StepHeading(number: 3, text: context.tr('med.step3')),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(m.reflectionPrompt, style: theme.textTheme.titleSmall),
      ),
      TextField(
        key: const ValueKey('reflection'),
        controller: _reflection,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: context.tr('med.hint'),
        ),
      ),
      if (_rejection != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: InstructionBanner(
            icon: Icons.info_outline,
            text: context.tr('med.reject.${_rejection!.name}', {'n': minReflectionChars}),
          ),
        ),
      const SizedBox(height: 16),
      StoneButton(
        key: const ValueKey('meditate'),
        label: context.tr('med.button'),
        fontSize: 19,
        height: 60,
        style: StoneStyle.moss,
        leading: const Icon(Icons.local_fire_department, color: Color(0xFFC0501F)),
        onPressed: () => _submit(m),
      ),
    ];
  }
}
