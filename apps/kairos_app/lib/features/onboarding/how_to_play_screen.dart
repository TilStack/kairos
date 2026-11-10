import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adventure/game_page.dart';
import '../../adventure/stone_button.dart';
import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../characters/cast.dart';
import '../../characters/pose.dart';

/// Reglage « le guide a deja ete montre ».
const howToSetting = 'howto';

/// Montre le guide au premier lancement. Les tests le coupent.
final showOnboardingProvider = Provider<bool>((ref) => true);

/// Regles du jeu en quatre lignes : ce qu'on fait, ce qu'on gagne.
const howToRules = [
  _Rule(
    Icons.auto_stories,
    'Vis l\'histoire',
    'Lis les dialogues et touche CONTINUER. Quand on te pose un choix, '
        'réponds avec ton cœur : il n\'y a pas de mauvaise réponse.',
  ),
  _Rule(
    Icons.vpn_key,
    'Forge des Clés',
    'Des Portes te demandent de retrouver un verset. Tu as 3 essais, des '
        'indices t\'aident, et rien ne te bloque jamais.',
  ),
  _Rule(
    Icons.local_fire_department,
    'Garde ta lampe allumée',
    'Une fois par jour, médite un passage dans MA LAMPE pour recharger '
        'l\'Huile. Elle baisse doucement quand tu t\'absentes.',
  ),
  _Rule(
    Icons.volume_up,
    'Écoute les répliques',
    'Touche ÉCOUTER pour entendre une réplique. Le haut-parleur de l\'écran-titre '
        'les lit toutes seules ; il est coupé tant que tu ne l\'actives pas.',
  ),
  _Rule(
    Icons.edit_note,
    'Écris ton journal',
    'Tes méditations, tes Clés et tes notes sont gardées dans ton JOURNAL. '
        'Elles restent privées, sur ton téléphone.',
  ),
];

class _Rule {
  const _Rule(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;
}

/// Ecran « Comment jouer ». Montre une fois au premier lancement, puis
/// disponible a tout moment depuis le bouton « ? » de l'ecran-titre.
class HowToPlayScreen extends ConsumerWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lumo = ref.watch(castProvider)['lumo'] ?? Cast.lumo;
    return GamePage(
      title: 'Comment jouer',
      setting: 'desert',
      character: lumo,
      action: CharacterAction.wave,
      speakerName: 'Lumo',
      panelFraction: 0.78,
      footer: StoneButton(
        key: const ValueKey('howto-done'),
        label: 'J\'AI COMPRIS',
        fontSize: 20,
        height: 56,
        style: StoneStyle.moss,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bienvenue ! Voici ce que tu peux faire :',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink, height: 1.3),
          ),
          const SizedBox(height: 10),
          for (final rule in howToRules) _RuleRow(rule: rule),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});

  final _Rule rule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: hintBackground, shape: BoxShape.circle),
            child: Icon(rule.icon, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
                const SizedBox(height: 2),
                Text(
                  rule.text,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
