import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../characters/character_spec.dart';
import '../characters/pose.dart';
import 'scene_frame.dart';
import 'stone_button.dart';

/// Hauteur reservee a l'en-tete (bouton retour + titre), sous la zone sure.
const gameHeaderHeight = 68.0;

/// En-tete commun a tous les ecrans : bouton retour en pierre et plaque de
/// titre. Il flotte au-dessus du decor.
class GameHeader extends StatelessWidget {
  const GameHeader({super.key, required this.title, this.onBack});

  final String title;

  /// Null : retour standard (ferme l'ecran).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            StoneIconButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Retour',
              size: 54,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
            Flexible(child: _TitlePlaque(title)),
          ],
        ),
      ),
    );
  }
}

class _TitlePlaque extends StatelessWidget {
  const _TitlePlaque(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6E9ED), Color(0xFFB9C0CA)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A3322), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x44000000), offset: Offset(0, 3), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          semanticsLabel: text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.5, color: Color(0xFF3C4654)),
        ),
      ),
    );
  }
}

/// Page de jeu complete : decor du lieu, personnage anime, en-tete et
/// panneau de parchemin. Toutes les pages (carte, lampe, journal, scenes)
/// partagent cette composition pour garder le meme design.
class GamePage extends ConsumerWidget {
  const GamePage({
    super.key,
    required this.title,
    required this.setting,
    required this.child,
    this.character,
    this.action = CharacterAction.idle,
    this.mood = Mood.happy,
    this.talking = false,
    this.speakerName,
    this.panelFraction = 0.6,
    this.scrollable = true,
  });

  final String title;
  final String setting;
  final CharacterSpec? character;
  final CharacterAction action;
  final Mood mood;
  final bool talking;
  final String? speakerName;
  final double panelFraction;
  final bool scrollable;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top + gameHeaderHeight;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SceneFrame(
            setting: setting,
            character: character,
            action: action,
            mood: mood,
            talking: talking,
            speakerName: speakerName,
            animated: ref.watch(animationsProvider),
            panelFraction: panelFraction,
            scrollable: scrollable,
            topInset: top,
            child: child,
          ),
          Positioned(top: 0, left: 0, right: 0, child: GameHeader(title: title)),
        ],
      ),
    );
  }
}
