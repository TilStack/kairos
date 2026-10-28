import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';

import '../../adventure/game_page.dart';
import '../../adventure/scene_frame.dart';
import '../../adventure/stone_button.dart';
import '../../app/controllers.dart';
import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../characters/cast.dart';
import '../../characters/character_spec.dart';
import '../../characters/pose.dart';
import '../../characters/spec_from_def.dart';
import '../keys/door_view.dart';

/// Lecteur narratif d'un chapitre. Chaque action est persistee avant d'etre
/// affichee : une fermeture brutale reprend exactement au dernier noeud.
/// Chaque noeud est joue dans une scene : decor du lieu, personnage anime,
/// et panneau de texte.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final Map<String, String> _settings;

  @override
  void initState() {
    super.initState();
    final chapter = ref.read(arcProvider).chapter(widget.chapterId);
    _settings = chapter == null ? const {} : resolveSettings(chapter);
    Future.microtask(() => ref.read(readerProvider.notifier).open(widget.chapterId));
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    final reader = ref.watch(readerProvider);
    final title = arc.chapter(widget.chapterId)?.title ?? '';
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _body(reader),
          Positioned(top: 0, left: 0, right: 0, child: GameHeader(title: title)),
        ],
      ),
    );
  }

  /// Personnage d'un noeud : celui qu'il declare, sinon [fallbackId].
  CharacterSpec _cast(Node node, {String fallbackId = 'lumo'}) {
    final cast = ref.read(castProvider);
    return cast[node.character] ?? cast[fallbackId] ?? Cast.lumo;
  }

  SceneFrame _scene(
    Node node, {
    required Widget child,
    CharacterAction defaultAction = CharacterAction.idle,
    Mood defaultMood = Mood.happy,
    bool talking = false,
    String? speakerName,
    bool scrollable = true,
    double panelFraction = 0.55,
    Widget? footer,
  }) {
    final who = _cast(node);
    return SceneFrame(
      setting: _settings[node.id] ?? 'desert',
      character: who,
      action: actionOf(node.action, defaultAction),
      mood: moodOf(node.mood, defaultMood),
      talking: talking,
      speakerName: speakerName,
      animated: ref.watch(animationsProvider),
      scrollable: scrollable,
      panelFraction: panelFraction,
      topInset: MediaQuery.paddingOf(context).top + gameHeaderHeight,
      footer: footer,
      child: child,
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
    if (feedback != null) return _feedbackScene(feedback);

    final engine = ref.read(engineProvider);
    final step = engine.view(game);
    final controller = ref.read(readerProvider.notifier);
    final Widget scene = switch (step) {
      DialogueStep(:final node) => _scene(
          node,
          talking: true,
          speakerName: node.speaker ?? _cast(node).name,
          panelFraction: 0.42,
          footer: _ContinueButton(key: const ValueKey('continue'), onPressed: controller.advance),
          child: Text(node.text, style: _bodyStyle),
        ),
      ChoiceStep(:final node, :final options) => _scene(
          node,
          talking: true,
          defaultAction: CharacterAction.think,
          speakerName: node.character == null ? null : _cast(node).name,
          panelFraction: 0.56,
          child: _ChoiceText(prompt: node.prompt, options: options, onChoose: controller.choose),
        ),
      DiscernmentStep(:final node) => _scene(
          node,
          talking: true,
          defaultAction: CharacterAction.talk,
          defaultMood: Mood.sly,
          speakerName: node.speaker ?? _cast(node, fallbackId: 'murmure').name,
          panelFraction: 0.64,
          child: _DiscernmentText(node: node, onAnswer: controller.answerDiscernment),
        ),
      DoorStep(:final node) => _scene(
          node,
          defaultAction: CharacterAction.point,
          defaultMood: Mood.think,
          scrollable: false,
          panelFraction: 0.64,
          child: _DoorHost(node: node, key: ValueKey('door-${node.id}')),
        ),
      DebriefStep(:final node, :final verses, :final traits) => _scene(
          node,
          defaultAction: CharacterAction.cheer,
          panelFraction: 0.62,
          footer: _ContinueButton(
            key: const ValueKey('debrief-continue'),
            label: 'TERMINER LE CHAPITRE',
            style: StoneStyle.moss,
            onPressed: controller.advance,
          ),
          child: _DebriefText(teaching: node.teaching, verses: verses, traits: traits),
        ),
      EndStep(:final node) => _scene(
          node,
          defaultAction: CharacterAction.cheer,
          panelFraction: 0.36,
          footer: Builder(
            builder: (context) => _ContinueButton(
              key: const ValueKey('end-back'),
              label: 'RETOUR À L\'AVENTURE',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          child: const _EndText(),
        ),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(key: ValueKey('${game.chapterId}/${game.nodeId}'), child: scene),
    );
  }

  /// Explication apres un defi de discernement : Lumo la donne avec bienveillance.
  Widget _feedbackScene(DiscernmentFeedback feedback) {
    return SceneFrame(
      setting: _settings[feedback.node.id] ?? 'desert',
      character: ref.read(castProvider)['lumo'] ?? Cast.lumo,
      action: feedback.correct ? CharacterAction.cheer : CharacterAction.talk,
      mood: feedback.correct ? Mood.happy : Mood.neutral,
      talking: !feedback.correct,
      speakerName: 'Lumo',
      panelFraction: 0.64,
      topInset: MediaQuery.paddingOf(context).top + gameHeaderHeight,
      animated: ref.watch(animationsProvider),
      footer: _ContinueButton(
        key: const ValueKey('feedback-continue'),
        onPressed: ref.read(readerProvider.notifier).dismissFeedback,
      ),
      child: _FeedbackText(feedback: feedback),
    );
  }
}

const _bodyStyle = TextStyle(fontSize: 18, height: 1.5, color: ink, fontWeight: FontWeight.w600);

/// Bouton d'action principale, fixe en bas du panneau.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({super.key, required this.onPressed, this.label = 'CONTINUER', this.style = StoneStyle.sand});

  final VoidCallback onPressed;
  final String label;
  final StoneStyle style;

  @override
  Widget build(BuildContext context) =>
      StoneButton(label: label, fontSize: 20, height: 56, style: style, onPressed: onPressed);
}

class _ChoiceText extends StatelessWidget {
  const _ChoiceText({required this.prompt, required this.options, required this.onChoose});

  final String prompt;
  final List<ChoiceOption> options;
  final void Function(String optionId) onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(prompt, style: _bodyStyle.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        for (final o in options)
          StoneOption(key: ValueKey('option-${o.id}'), text: o.text, onPressed: () => onChoose(o.id)),
      ],
    );
  }
}

class _DiscernmentText extends StatelessWidget {
  const _DiscernmentText({required this.node, required this.onAnswer});

  final DiscernmentNode node;
  final void Function(AnomalyType) onAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x22B03A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x66B03A2E), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.quote, style: _bodyStyle.copyWith(fontStyle: FontStyle.italic)),
                if (node.claimedRef != null) ...[
                  const SizedBox(height: 6),
                  Text('Cité comme : ${node.claimedRef}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF7A2D1F))),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Quelle est l\'anomalie ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF3A2A1A))),
        const SizedBox(height: 8),
        for (final type in AnomalyType.values)
          StoneOption(
            key: ValueKey('anomaly-${type.id}'),
            text: anomalyLabels[type]!,
            onPressed: () => onAnswer(type),
          ),
      ],
    );
  }
}

/// Explication pedagogique apres un defi de discernement : toujours donnee,
/// sans honte en cas d'erreur (CDC §4.4).
class _FeedbackText extends ConsumerWidget {
  const _FeedbackText({required this.feedback});

  final DiscernmentFeedback feedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arc = ref.watch(arcProvider);
    final node = feedback.node;
    final ref0 = node.correctRef;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          feedback.correct ? 'Bien vu !' : 'Pas tout à fait — voici pourquoi.',
          style: _bodyStyle.copyWith(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text('Il s\'agissait d\'un verset : ${anomalyLabels[node.anomaly]!.toLowerCase()}.', style: _bodyStyle),
        const SizedBox(height: 8),
        Text(node.explanation, style: _bodyStyle),
        if (ref0 != null)
          ScriptureBlock(reference: BibleRef.tryParse(ref0)?.label ?? ref0, text: arc.verseText(ref0)),
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

class _DebriefText extends StatelessWidget {
  const _DebriefText({required this.teaching, required this.verses, required this.traits});

  final String teaching;
  final List<VerseText> verses;
  final Map<Trait, int> traits;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('À la lumière de l\'Écriture', style: _bodyStyle.copyWith(fontWeight: FontWeight.w900, fontSize: 22)),
        const SizedBox(height: 8),
        for (final v in verses) ScriptureBlock(reference: v.label, text: v.text),
        const SizedBox(height: 6),
        Text(teaching, style: _bodyStyle),
        const SizedBox(height: 16),
        Text('Ton cœur, révélé par tes choix', style: _bodyStyle.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in Trait.values) Chip(label: Text('${traitLabels[t]} · ${traits[t] ?? 0}')),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Aucun trait n\'est mauvais : l\'Écriture est un miroir, pas un tribunal.', style: TextStyle(color: inkSoft)),
      ],
    );
  }
}

class _EndText extends StatelessWidget {
  const _EndText();

  @override
  Widget build(BuildContext context) =>
      Text('Chapitre terminé', textAlign: TextAlign.center, style: _bodyStyle.copyWith(fontWeight: FontWeight.w900, fontSize: 26));
}
