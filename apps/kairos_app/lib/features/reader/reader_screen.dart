import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';

import '../../app/controllers.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../keys/door_view.dart';

/// Lecteur narratif d'un chapitre. Chaque action est persistee avant d'etre
/// affichee : une fermeture brutale reprend exactement au dernier noeud.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(readerProvider.notifier).open(widget.chapterId));
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    final reader = ref.watch(readerProvider);
    final title = arc.chapter(widget.chapterId)?.title ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: _body(reader)),
    );
  }

  Widget _body(ReaderState reader) {
    if (reader.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ce chapitre ne peut pas être ouvert. Si le contenu a été mis à jour, '
            'recommence le chapitre.\n\n${reader.error}',
          ),
        ),
      );
    }
    final game = reader.game;
    if (game == null || reader.chapterId != widget.chapterId) {
      return const Center(child: CircularProgressIndicator());
    }
    final feedback = reader.feedback;
    if (feedback != null) return _FeedbackView(feedback: feedback);

    final engine = ref.read(engineProvider);
    final step = engine.view(game);
    final controller = ref.read(readerProvider.notifier);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(
        key: ValueKey('${game.chapterId}/${game.nodeId}'),
        child: switch (step) {
          DialogueStep(:final node) => _DialogueView(node: node, onNext: controller.advance),
          ChoiceStep(:final node, :final options) =>
            _ChoiceView(prompt: node.prompt, options: options, onChoose: controller.choose),
          DiscernmentStep(:final node) =>
            _DiscernmentView(node: node, onAnswer: controller.answerDiscernment),
          DoorStep(:final node) => _DoorHost(node: node, key: ValueKey('door-${node.id}')),
          DebriefStep(:final node, :final verses, :final traits) =>
            _DebriefView(teaching: node.teaching, verses: verses, traits: traits, onNext: controller.advance),
          EndStep() => const _EndView(),
        },
      ),
    );
  }
}

class _DialogueView extends StatelessWidget {
  const _DialogueView({required this.node, required this.onNext});

  final DialogueNode node;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (node.speaker != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(node.speaker!, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
          ),
        Text(node.text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
        const SizedBox(height: 24),
        FilledButton(onPressed: onNext, child: const Text('Continuer')),
      ],
    );
  }
}

class _ChoiceView extends StatelessWidget {
  const _ChoiceView({required this.prompt, required this.options, required this.onChoose});

  final String prompt;
  final List<ChoiceOption> options;
  final void Function(String optionId) onChoose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        for (final o in options)
          Card(
            key: ValueKey('option-${o.id}'),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChoose(o.id),
              child: Padding(padding: const EdgeInsets.all(16), child: Text(o.text)),
            ),
          ),
      ],
    );
  }
}

class _DiscernmentView extends StatelessWidget {
  const _DiscernmentView({required this.node, required this.onAnswer});

  final DiscernmentNode node;
  final void Function(AnomalyType) onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(node.speaker ?? 'Une voix', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.quote, style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                if (node.claimedRef != null) ...[
                  const SizedBox(height: 8),
                  Text('Cité comme : ${node.claimedRef}', style: theme.textTheme.labelLarge),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Quelle est l\'anomalie ?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final type in AnomalyType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              key: ValueKey('anomaly-${type.id}'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => onAnswer(type),
              child: Text(anomalyLabels[type]!),
            ),
          ),
      ],
    );
  }
}

/// Explication pedagogique apres un defi de discernement : toujours donnee,
/// sans honte en cas d'erreur (CDC §4.4).
class _FeedbackView extends ConsumerWidget {
  const _FeedbackView({required this.feedback});

  final DiscernmentFeedback feedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arc = ref.watch(arcProvider);
    final node = feedback.node;
    final ref0 = node.correctRef;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          feedback.correct ? 'Bien vu.' : 'Pas tout à fait — voici pourquoi.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('Il s\'agissait d\'un verset : ${anomalyLabels[node.anomaly]!.toLowerCase()}.'),
        const SizedBox(height: 8),
        Text(node.explanation),
        if (ref0 != null)
          ScriptureBlock(
            reference: BibleRef.tryParse(ref0)?.label ?? ref0,
            text: arc.verseText(ref0),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('feedback-continue'),
          onPressed: ref.read(readerProvider.notifier).dismissFeedback,
          child: const Text('Continuer'),
        ),
      ],
    );
  }
}

class _DoorHost extends ConsumerStatefulWidget {
  const _DoorHost({super.key, required this.node});

  final DoorNode node;

  @override
  ConsumerState<_DoorHost> createState() => _DoorHostState();
}

class _DoorHostState extends ConsumerState<_DoorHost> {
  late final Future<KeyMastery> _mastery;
  DoorChallenge? _challenge;

  @override
  void initState() {
    super.initState();
    _mastery = ref.read(readerProvider.notifier).masteryFor(widget.node.verse);
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    return FutureBuilder<KeyMastery>(
      future: _mastery,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final mastery = snap.data!;
        final verse = arc.verseText(widget.node.verse)!;
        final challenge = _challenge ??= DoorChallenge(
          verse: verse,
          verseId: widget.node.verse,
          level: mastery.level,
          seed: stableSeed('${widget.node.verse}/${mastery.repetitions}'),
        );
        return DoorView(
          challenge: challenge,
          prompt: widget.node.prompt,
          reference: BibleRef.tryParse(widget.node.verse)?.label ?? widget.node.verse,
          celebrate: ref.watch(animationsProvider),
          onFinished: () => ref.read(readerProvider.notifier).finishDoor(challenge, mastery),
        );
      },
    );
  }
}

class _DebriefView extends StatelessWidget {
  const _DebriefView({required this.teaching, required this.verses, required this.traits, required this.onNext});

  final String teaching;
  final List<VerseText> verses;
  final Map<Trait, int> traits;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('À la lumière de l\'Écriture', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final v in verses) ScriptureBlock(reference: v.label, text: v.text),
        const SizedBox(height: 8),
        Text(teaching, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
        const SizedBox(height: 16),
        Text('Ton cœur, révélé par tes choix', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in Trait.values) Chip(label: Text('${traitLabels[t]} · ${traits[t] ?? 0}')),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Aucun trait n\'est mauvais : l\'Écriture est un miroir, pas un tribunal.'),
        const SizedBox(height: 24),
        FilledButton(key: const ValueKey('debrief-continue'), onPressed: onNext, child: const Text('Terminer le chapitre')),
      ],
    );
  }
}

class _EndView extends StatelessWidget {
  const _EndView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories, size: 56),
            const SizedBox(height: 12),
            Text('Chapitre terminé', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('end-back'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour à l\'aventure'),
            ),
          ],
        ),
      ),
    );
  }
}
