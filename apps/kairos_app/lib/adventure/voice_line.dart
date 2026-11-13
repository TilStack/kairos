import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/l10n.dart';
import '../app/palette.dart';
import '../app/voice.dart';

/// Un texte lu a voix haute : le bouton ECOUTER est toujours la, et la
/// lecture demarre toute seule seulement si le joueur l'a activee.
class VoiceLine extends ConsumerStatefulWidget {
  const VoiceLine({super.key, required this.text, required this.child, this.characterId});

  /// Texte prononce (peut differer du texte affiche).
  final String text;
  final String? characterId;
  final Widget child;

  @override
  ConsumerState<VoiceLine> createState() => _VoiceLineState();
}

class _VoiceLineState extends ConsumerState<VoiceLine> {
  // Garde dans initState : `ref` n'est plus utilisable dans dispose().
  late final VoiceService _voice;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(voiceProvider);
    if (ref.read(voiceAutoProvider).value ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _voice.speak(widget.text, characterId: widget.characterId, lang: ref.read(langProvider));
      });
    }
  }

  @override
  void dispose() {
    _voice.stopIfSpeaking(widget.text);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ListenButton(text: widget.text, characterId: widget.characterId),
        ),
        const SizedBox(height: 6),
        widget.child,
      ],
    );
  }
}

/// Petit bouton « Ecouter » / « Arreter » en haut a droite d'une replique.
class ListenButton extends ConsumerWidget {
  const ListenButton({super.key, required this.text, this.characterId});

  final String text;
  final String? characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(voiceProvider);
    return ValueListenableBuilder<String?>(
      valueListenable: voice.speaking,
      builder: (context, current, _) {
        final playing = current == text;
        return Semantics(
          button: true,
          label: playing ? context.tr('stop.semantic') : context.tr('listen.semantic'),
          child: ExcludeSemantics(
            child: Material(
              color: hintBackground,
              shape: StadiumBorder(side: BorderSide(color: hintBorder, width: 2)),
              child: InkWell(
                key: const ValueKey('listen'),
                customBorder: const StadiumBorder(),
                onTap: () => playing
                    ? voice.stop()
                    : voice.speak(text, characterId: characterId, lang: ref.read(langProvider)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(playing ? Icons.stop_circle_outlined : Icons.volume_up, color: ink, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          playing ? context.tr('stop') : context.tr('listen'),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: ink, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
