import 'dart:ui';

import 'package:kairos_core/kairos_core.dart';

import 'character_spec.dart';
import 'pose.dart';

Color _color(String hex) => Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
Color? _maybe(String? hex) => hex == null ? null : _color(hex);

/// Fiche de contenu (`CharacterDef`, du JSON de l'arc) -> fiche de dessin.
/// Les noms de coiffes et d'accessoires sont deja valides par le moteur.
CharacterSpec specFromDef(CharacterDef d) => CharacterSpec(
      id: d.id,
      name: d.name,
      skin: _color(d.skin),
      outfit: _color(d.outfit),
      outfitAccent: _maybe(d.outfitAccent),
      stripes: [for (final s in d.stripes) _color(s)],
      hair: _maybe(d.hair),
      beard: _maybe(d.beard),
      headwear: Headwear.values.byName(d.headwear),
      headwearColor: _maybe(d.headwearColor) ?? const Color(0xFFF2E8CF),
      prop: Prop.values.byName(d.prop),
      flameHead: d.flameHead,
      glowingEyes: d.glowingEyes,
      scale: d.scale,
    );

/// Humeur / action d'un noeud, avec repli si le contenu est plus recent que
/// l'application (un nom inconnu ne doit jamais faire planter une scene).
Mood moodOf(String? name, Mood fallback) {
  for (final m in Mood.values) {
    if (m.name == name) return m;
  }
  return fallback;
}

CharacterAction actionOf(String? name, CharacterAction fallback) {
  for (final a in CharacterAction.values) {
    if (a.name == name) return a;
  }
  return fallback;
}
