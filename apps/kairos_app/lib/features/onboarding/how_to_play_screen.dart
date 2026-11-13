import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adventure/game_page.dart';
import '../../adventure/stone_button.dart';
import '../../app/l10n.dart';
import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../characters/cast.dart';
import '../../characters/pose.dart';

/// Reglage « le guide a deja ete montre ».
const howToSetting = 'howto';

/// Montre le guide au premier lancement. Les tests le coupent.
final showOnboardingProvider = Provider<bool>((ref) => true);

/// Regles du jeu : icone et cle de traduction (`howto.rN.title` / `.text`).
const howToRules = [
  _Rule(Icons.auto_stories, 'howto.r1'),
  _Rule(Icons.vpn_key, 'howto.r2'),
  _Rule(Icons.local_fire_department, 'howto.r3'),
  _Rule(Icons.volume_up, 'howto.r4'),
  _Rule(Icons.edit_note, 'howto.r5'),
];

class _Rule {
  const _Rule(this.icon, this.key);
  final IconData icon;
  final String key;
}

/// Ecran « Comment jouer ». Montre une fois au premier lancement, puis
/// disponible a tout moment depuis le bouton « ? » de l'ecran-titre.
class HowToPlayScreen extends ConsumerWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lumo = ref.watch(castProvider)['lumo'] ?? Cast.lumo;
    return GamePage(
      title: context.tr('howto.title'),
      setting: 'desert',
      character: lumo,
      action: CharacterAction.wave,
      speakerName: 'Lumo',
      panelFraction: 0.78,
      footer: StoneButton(
        key: const ValueKey('howto-done'),
        label: context.tr('howto.done'),
        fontSize: 20,
        height: 56,
        style: StoneStyle.moss,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('howto.welcome'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink, height: 1.3),
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
                Text(context.tr('${rule.key}.title'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
                const SizedBox(height: 2),
                Text(
                  context.tr('${rule.key}.text'),
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
