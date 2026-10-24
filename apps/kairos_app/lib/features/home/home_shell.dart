import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controllers.dart';
import '../../app/providers.dart';
import '../journal/journal_screen.dart';
import '../meditation/meditation_screen.dart';
import '../reader/reader_screen.dart';

/// Navigation principale : Aventure, Huile (meditation), Journal.
/// Seul l'onglet visible est construit : l'ecran du Journal (captures
/// interdites) n'est donc actif que lorsqu'il est affiche.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = <Widget Function()>[
    AdventureScreen.new,
    MeditationScreen.new,
    JournalScreen.new,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index](),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Aventure'),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Lampe',
          ),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Journal'),
        ],
      ),
    );
  }
}

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
