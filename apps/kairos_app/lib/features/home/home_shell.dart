import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controllers.dart';
import '../../app/providers.dart';
import '../reader/reader_screen.dart';

/// Carte de l'arc : chapitres a debloquer dans l'ordre.
class AdventureScreen extends ConsumerWidget {
  const AdventureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arc = ref.watch(arcProvider);
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(title: Text(arc.title)),
      body: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (p) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: arc.chapters.length,
          itemBuilder: (context, i) {
            final chapter = arc.chapters[i];
            final done = p.completed.contains(chapter.id);
            final unlocked = i == 0 || p.completed.contains(arc.chapters[i - 1].id);
            return Card(
              child: ListTile(
                key: ValueKey('chapter-${chapter.id}'),
                enabled: unlocked,
                leading: CircleAvatar(
                  child: done ? const Icon(Icons.check) : (unlocked ? Text('${i + 1}') : const Icon(Icons.lock_outline)),
                ),
                title: Text(chapter.title),
                subtitle: Text(chapter.theme ?? ''),
                trailing: unlocked ? const Icon(Icons.chevron_right) : null,
                onTap: unlocked
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => ReaderScreen(chapterId: chapter.id)),
                        )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
