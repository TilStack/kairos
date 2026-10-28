import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/palette.dart';
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
    this.topInset = 0,
    this.footer,
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

  /// Espace libre en haut (sous l'en-tete flottant) : le personnage ne le recouvre pas.
  final double topInset;

  /// Action principale, fixee en bas du panneau : toujours visible, meme quand
  /// le texte est long ou la police agrandie.
  final Widget? footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        // `clamp(260, h)` leve une erreur quand h < 260 (paysage, clavier ouvert) :
        // min/max ne plante jamais.
        final panelH = math.min(h, math.max(260.0, h * panelFraction));
        // Le panneau recouvre un peu les pieds : le personnage « se tient derriere ».
        final stageH = math.max(0.0, h - panelH + 14);
        final stageTop = math.min(topInset, stageH);
        final stageFree = math.max(0.0, stageH - stageTop);
        return Stack(
          fit: StackFit.expand,
          children: [
            SceneBackdrop(setting: setting, animated: animated),
            if (character != null)
              Positioned(
                left: 0,
                right: 0,
                top: stageTop,
                height: stageFree,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CharacterWidget(
                    key: ValueKey('stage-${character!.id}'),
                    spec: character!,
                    action: action,
                    mood: mood,
                    talking: talking,
                    height: math.max(60.0, math.min(340.0, stageFree - 8)),
                    animated: animated,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: panelH,
              child: _Panel(speakerName: speakerName, scrollable: scrollable, footer: footer, child: child),
            ),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.speakerName, required this.scrollable, required this.footer, required this.child});

  final String? speakerName;
  final bool scrollable;
  final Widget? footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final body = scrollable
        ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 26, 20, 20), child: child)
        : Padding(padding: const EdgeInsets.only(top: 14), child: child);
    final content = footer == null
        ? body
        : Column(
            children: [
              Expanded(child: body),
              Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 14), child: footer),
            ],
          );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [parchmentTop, parchmentBottom],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Color(0xFF8A5A2B), width: 4),
                left: BorderSide(color: Color(0xFF8A5A2B), width: 3),
                right: BorderSide(color: Color(0xFF8A5A2B), width: 3),
              ),
              boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, -3))],
            ),
            child: SafeArea(top: false, child: content),
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
