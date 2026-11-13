import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';

import '../../adventure/game_page.dart';
import '../../adventure/guidance.dart';
import '../../adventure/stone_button.dart';
import '../../app/controllers.dart';
import '../../app/l10n.dart';
import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../app/secure_screen.dart';
import '../../app/widgets.dart';
import '../../characters/cast.dart';
import '../../characters/character_spec.dart';
import '../../characters/pose.dart';

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
    // Lumo lit un parchemin : le Journal est son carnet comme le tien.
    final lumo = (ref.watch(castProvider)['lumo'] ?? Cast.lumo).withProp(Prop.scroll);
    return SecureScope(
      child: GamePage(
        title: context.tr('journal.title'),
        setting: 'memory',
        character: lumo,
        action: CharacterAction.think,
        mood: Mood.neutral,
        speakerName: 'Lumo',
        panelFraction: 0.68,
        scrollable: false,
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(context.tr('error', {'e': e}))),
          data: (all) {
            final shown = filterEntries(all, type: _filter);
            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(context.tr('journal.all')),
                          selected: _filter == null,
                          onSelected: (_) => setState(() => _filter = null),
                        ),
                      ),
                      for (final t in JournalEntryType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            key: ValueKey('filter-${t.name}'),
                            label: Text(context.tr('jtype.${t.name}')),
                            selected: _filter == t,
                            onSelected: (_) => setState(() => _filter = t),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              context.tr('journal.empty'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: ink, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          itemCount: shown.length,
                          itemBuilder: (_, i) => _EntryCard(entry: shown[i]),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: StoneButton(
                    key: const ValueKey('add-note'),
                    label: context.tr('journal.add'),
                    fontSize: 18,
                    height: 54,
                    leading: const Icon(Icons.edit_note, color: Color(0xFF5B3A1A)),
                    onPressed: _addNote,
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
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final date = context.lang == 'en' ? '$mm/$dd/${local.year}' : '$dd/$mm/${local.year}';
    return StoneCard(
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
                ScriptureBlock(reference: BibleRef.tryParse(r)?.labelIn(context.lang) ?? r, text: arc.verseText(r)),
          ],
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
      title: Text(context.tr('note.title')),
      content: TextField(
        key: const ValueKey('note-field'),
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: context.tr('note.hint')),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
        FilledButton(
          key: const ValueKey('note-save'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}
