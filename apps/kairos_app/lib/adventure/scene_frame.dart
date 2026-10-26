import 'package:flutter/material.dart';

import '../characters/character_spec.dart';
import '../characters/character_widget.dart';
import '../characters/pose.dart';
import 'scene_backdrop.dart';

/// Cadre d'une scene d'aventure : decor et personnage en haut, panneau de
/// parchemin en bas pour le texte et les choix. Meme composition pour les
/// dialogues, les choix, les defis, les Portes et les debriefings.
class SceneFrame extends StatelessWidget {
  const SceneFrame({
    super.key,
    required this.setting,
    required this.child,
    this.character,
    this.action = CharacterAction.idle,
    this.mood = Mood.happy,
    this.talking = false,
    this.speakerName,
    this.animated = true,
    this.scrollable = true,
    this.panelFraction = 0.55,
  });

  final String setting;
  final CharacterSpec? character;
  final CharacterAction action;
  final Mood mood;
  final bool talking;

  /// Nom affiche sur la plaque au-dessus du panneau.
  final String? speakerName;
  final bool animated;

  /// Faux quand [child] gere lui-meme son defilement (ex. une Porte).
  final bool scrollable;

  /// Part de la hauteur occupee par le panneau de texte (le reste : la scene).
  final double panelFraction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final panelH = (h * panelFraction).clamp(260.0, h);
        // Le panneau recouvre un peu les pieds : le personnage « se tient derriere ».
        final stageH = h - panelH + 14;
        return Stack(
          fit: StackFit.expand,
          children: [
            SceneBackdrop(setting: setting, animated: animated),
            if (character != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: stageH,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CharacterWidget(
                    key: ValueKey('stage-${character!.id}'),
                    spec: character!,
                    action: action,
                    mood: mood,
                    talking: talking,
                    height: (stageH - 8).clamp(120.0, 340.0),
                    animated: animated,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: panelH,
              child: _Panel(speakerName: speakerName, scrollable: scrollable, child: child),
            ),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.speakerName, required this.scrollable, required this.child});

  final String? speakerName;
  final bool scrollable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final body = scrollable
        ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 26, 20, 20), child: child)
        : Padding(padding: const EdgeInsets.only(top: 14), child: child);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF6E0), Color(0xFFF4E2B8)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Color(0xFF8A5A2B), width: 4),
                left: BorderSide(color: Color(0xFF8A5A2B), width: 3),
                right: BorderSide(color: Color(0xFF8A5A2B), width: 3),
              ),
              boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, -3))],
            ),
            child: SafeArea(top: false, child: body),
          ),
        ),
        if (speakerName != null)
          Positioned(
            top: -17,
            left: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE6E9ED), Color(0xFFB9C0CA)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4A3322), width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text(
                  speakerName!,
                  key: const ValueKey('speaker-name'),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF3C4654)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
