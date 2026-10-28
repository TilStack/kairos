import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adventure/game_page.dart';
import '../../adventure/stone_button.dart';
import '../../app/controllers.dart';
import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../characters/cast.dart';
import '../../characters/pose.dart';
import '../reader/reader_screen.dart';

/// Carte de l'arc : les chapitres se debloquent dans l'ordre. Chaque chapitre
/// est une tablette de pierre : sable (a jouer), mousse (termine), ardoise
/// (verrouille).
class AdventureScreen extends ConsumerWidget {
  const AdventureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arc = ref.watch(arcProvider);
    final progress = ref.watch(progressProvider);
    final lumo = ref.watch(castProvider)['lumo'] ?? Cast.lumo;
    return GamePage(
      title: 'Aventure',
      setting: 'desert',
      character: lumo,
      action: CharacterAction.wave,
      speakerName: 'Lumo',
      panelFraction: 0.62,
      child: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (p) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              arc.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              '${p.completed.length} chapitre${p.completed.length > 1 ? 's' : ''} sur ${arc.chapters.length} terminé${p.completed.length > 1 ? 's' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: inkSoft),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < arc.chapters.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChapterTile(
                  index: i,
                  title: arc.chapters[i].title,
                  theme: arc.chapters[i].theme,
                  chapterId: arc.chapters[i].id,
                  done: p.completed.contains(arc.chapters[i].id),
                  unlocked: i == 0 || p.completed.contains(arc.chapters[i - 1].id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.index,
    required this.title,
    required this.theme,
    required this.chapterId,
    required this.done,
    required this.unlocked,
  });

  final int index;
  final String title;
  final String? theme;
  final String chapterId;
  final bool done;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final style = done ? StoneStyle.moss : (unlocked ? StoneStyle.sand : StoneStyle.slate);
    final Widget medal = done
        ? Icon(Icons.check, color: style.text)
        : (unlocked
            ? Text('${index + 1}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: style.text))
            : Icon(Icons.lock_outline, color: style.text));
    return StoneButton(
      key: ValueKey('chapter-$chapterId'),
      label: title,
      subtitle: theme,
      style: style,
      fontSize: 18,
      height: 76,
      leading: SizedBox(width: 32, child: Center(child: medal)),
      onPressed: unlocked
          ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReaderScreen(chapterId: chapterId)))
          : null,
    );
  }
}
