/// Journal de disciple : entrees privees, chiffrees au repos par la couche
/// de stockage. Le moteur ne produit que des donnees ; rien n'en sort sans
/// action explicite du joueur (CDC §4.4, UC-07).
library;

import '../content/models.dart';

enum JournalEntryType { meditation, key, discernment, note }

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.title,
    required this.body,
    this.arcId,
    this.refs = const [],
  });

  factory JournalEntry.fromJson(Map<String, Object?> json) => JournalEntry(
        id: json['id']! as String,
        type: JournalEntryType.values.byName(json['type']! as String),
        createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
        title: json['title']! as String,
        body: json['body']! as String,
        arcId: json['arcId'] as String?,
        refs: (json['refs']! as List<Object?>).cast<String>(),
      );

  /// Meditation validee : passage lu et reflexion du joueur.
  factory JournalEntry.meditation({
    required String id,
    required DateTime at,
    required String arcId,
    required Meditation meditation,
    required String reflection,
  }) =>
      JournalEntry(
        id: id,
        type: JournalEntryType.meditation,
        createdAt: at.toUtc(),
        title: 'Méditation',
        body: '${meditation.reflectionPrompt}\n\n${reflection.trim()}',
        arcId: arcId,
        refs: [meditation.passage],
      );

  /// Cle de la Parole forgee.
  factory JournalEntry.keyForged({
    required String id,
    required DateTime at,
    required String arcId,
    required String verseId,
    required String label,
    required String text,
  }) =>
      JournalEntry(
        id: id,
        type: JournalEntryType.key,
        createdAt: at.toUtc(),
        title: 'Clé forgée : $label',
        body: text,
        arcId: arcId,
        refs: [verseId],
      );

  /// Explication d'un defi de discernement, archivee pour relecture (UC-03).
  factory JournalEntry.discernment({
    required String id,
    required DateTime at,
    required String arcId,
    required DiscernmentNode node,
    required bool correct,
  }) =>
      JournalEntry(
        id: id,
        type: JournalEntryType.discernment,
        createdAt: at.toUtc(),
        title: correct ? 'Discernement réussi' : 'Discernement à relire',
        body: '« ${node.quote} »\n\n${node.explanation}',
        arcId: arcId,
        refs: [if (node.correctRef != null) node.correctRef!],
      );

  /// Note libre (priere, reconnaissance).
  factory JournalEntry.note({
    required String id,
    required DateTime at,
    required String text,
  }) =>
      JournalEntry(
        id: id,
        type: JournalEntryType.note,
        createdAt: at.toUtc(),
        title: 'Note',
        body: text.trim(),
      );

  final String id;
  final JournalEntryType type;
  final DateTime createdAt;
  final String title;
  final String body;
  final String? arcId;

  /// Identifiants de versets lies a l'entree.
  final List<String> refs;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'title': title,
        'body': body,
        'arcId': arcId,
        'refs': refs,
      };
}

/// Entrees filtrees (type, arc), les plus recentes d'abord.
List<JournalEntry> filterEntries(
  Iterable<JournalEntry> entries, {
  JournalEntryType? type,
  String? arcId,
}) {
  final out = entries
      .where((e) => (type == null || e.type == type) && (arcId == null || e.arcId == arcId))
      .toList()
    ..sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
  return out;
}
