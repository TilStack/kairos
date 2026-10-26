import 'models.dart';

/// Lieu de chaque noeud d'un chapitre : celui qu'il declare, sinon celui du
/// noeud qui y mene (parcours depuis le depart). Les noeuds sans aucun lieu
/// en amont recoivent [fallback].
///
/// Calcule depuis le graphe plutot que memorise pendant la lecture : une
/// reprise de partie au milieu d'un chapitre retrouve le bon decor.
Map<String, String> resolveSettings(Chapter chapter, {String fallback = 'desert'}) {
  final result = <String, String>{};
  final queue = <(String, String)>[(chapter.start, fallback)];
  while (queue.isNotEmpty) {
    final (id, inherited) = queue.removeAt(0);
    if (result.containsKey(id)) continue;
    final node = chapter.nodes[id];
    if (node == null) continue;
    final here = node.setting ?? inherited;
    result[id] = here;
    for (final t in node.outgoing) {
      queue.add((t.to, here));
    }
  }
  return result;
}
