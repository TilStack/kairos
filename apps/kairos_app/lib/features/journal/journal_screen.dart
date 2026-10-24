import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';

import '../../app/controllers.dart';
import '../../app/providers.dart';
import '../../app/secure_screen.dart';
import '../../app/widgets.dart';

const typeLabels = {
  JournalEntryType.meditation: 'Méditations',
  JournalEntryType.key: 'Clés',
  JournalEntryType.discernment: 'Discernement',
  JournalEntryType.note: 'Notes',
};

IconData _icon(JournalEntryType t) => switch (t) {
      JournalEntryType.meditation => Icons.local_fire_department,
      JournalEntryType.key => Icons.vpn_key,
      JournalEntryType.discernment => Icons.visibility,
      JournalEntryType.note => Icons.edit_note,
    };

/// Journal de disciple : prive, chiffre, hors ligne. Captures d'ecran
/// interdites tant qu'il est ouvert.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  JournalEntryType? _filter;

  Future<void> _addNote() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _NoteDialog(),
    );
    if (text != null) await ref.read(journalProvider.notifier).addNote(text);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalProvider);
    return SecureScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Mon journal')),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('add-note'),
          onPressed: _addNote,
          icon: const Icon(Icons.add),
          label: const Text('Note'),
        ),
        body: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (all) {
            final shown = filterEntries(all, type: _filter);
            return Column(
              children: [
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Tout'),
                          selected: _filter == null,
                          onSelected: (_) => setState(() => _filter = null),
                        ),
                      ),
                      for (final t in JournalEntryType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            key: ValueKey('filter-${t.name}'),
                            label: Text(typeLabels[t]!),
                            selected: _filter == t,
                            onSelected: (_) => setState(() => _filter = t),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Ton journal est vide pour l\'instant. Tes méditations, tes Clés et '
                              'tes notes apparaîtront ici. Rien ne quitte ton téléphone.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                          itemCount: shown.length,
                          itemBuilder: (_, i) => _EntryCard(entry: shown[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arc = ref.watch(arcProvider);
    final local = entry.createdAt.toLocal();
    final date = '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon(entry.type), size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.title, style: Theme.of(context).textTheme.titleSmall)),
                Text(date, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.body),
            for (final r in entry.refs)
              if (entry.type != JournalEntryType.key)
                ScriptureBlock(reference: BibleRef.tryParse(r)?.label ?? r, text: arc.verseText(r)),
          ],
        ),
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle note'),
      content: TextField(
        key: const ValueKey('note-field'),
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Prière, reconnaissance…'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          key: const ValueKey('note-save'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
