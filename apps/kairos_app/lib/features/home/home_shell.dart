import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adventure/game_page.dart';
import '../../adventure/guidance.dart';
import '../../adventure/stone_button.dart';
import '../../app/controllers.dart';
import '../../app/l10n.dart';
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
      title: context.tr('map.title'),
      setting: 'desert',
      character: lumo,
      action: CharacterAction.wave,
      speakerName: 'Lumo',
      panelFraction: 0.62,
      child: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(context.tr('error', {'e': e})),
        data: (p) {
          // Le prochain chapitre a jouer : premier debloque et pas encore termine.
          final next = [
            for (var i = 0; i < arc.chapters.length; i++)
              if (!p.completed.contains(arc.chapters[i].id) &&
                  (i == 0 || p.completed.contains(arc.chapters[i - 1].id)))
                i,
          ].firstOrNull;
          return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              arc.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('map.progress', {
                'done': p.completed.length,
                'total': arc.chapters.length,
                's': p.completed.length > 1 ? 's' : '',
              }),
              style: const TextStyle(fontWeight: FontWeight.w700, color: inkSoft),
            ),
            const SizedBox(height: 12),
            InstructionBanner(
              icon: Icons.flag,
              title: context.tr(next == null ? 'map.done.title' : 'map.next.title'),
              text: next == null
                  ? context.tr('map.done.text')
                  : context.tr('map.next.text', {'n': next + 1}),
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
                  isNext: i == next,
                ),
              ),
          ],
        );
        },
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
    required this.isNext,
  });

  final int index;
  final String title;
  final String? theme;
  final String chapterId;
  final bool done;
  final bool unlocked;
  final bool isNext;

  /// Dit en clair l'etat du chapitre : fait, a jouer, ou ce qui le debloque.
  String? _subtitle(BuildContext context) {
    if (done) {
      return theme == null ? context.tr('ch.done') : context.tr('ch.done_theme', {'theme': theme!});
    }
    if (!unlocked) return context.tr('ch.locked', {'n': index});
    if (!isNext) return theme;
    return theme == null ? context.tr('ch.next') : context.tr('ch.next_theme', {'theme': theme!});
  }

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
      subtitle: _subtitle(context),
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
