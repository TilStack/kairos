import 'dart:ui';

import 'character_spec.dart';

/// Distribution de l'arc « La Tunique et le Trône » et mascotte.
/// Toutes les fiches sont des donnees : ajouter un acteur ne demande aucun
/// nouveau code de dessin.
abstract final class Cast {
  /// Mascotte et guide du joueur : une personne dont la tete est une flamme.
  static const lumo = CharacterSpec(
    id: 'lumo',
    name: 'Lumo',
    skin: Color(0xFFFFC93C),
    outfit: Color(0xFF3B4A9C),
    outfitAccent: Color(0xFFFFC93C),
    flameHead: true,
  );

  static const joseph = CharacterSpec(
    id: 'joseph',
    name: 'Joseph',
    skin: Color(0xFFD9A066),
    outfit: Color(0xFFE8452E),
    stripes: [Color(0xFFE8452E), Color(0xFFF2B632), Color(0xFF3FA86B), Color(0xFF3F8FD9), Color(0xFF8C5BC8)],
    outfitAccent: Color(0xFFF2B632),
    hair: Color(0xFF3A2418),
  );

  static const jacob = CharacterSpec(
    id: 'jacob',
    name: 'Jacob (Israël)',
    skin: Color(0xFFC98E58),
    outfit: Color(0xFF8A6A4F),
    outfitAccent: Color(0xFFD8C7A0),
    hair: Color(0xFFE6E2D6),
    beard: Color(0xFFE6E2D6),
    headwear: Headwear.headband,
    headwearColor: Color(0xFFB04A3A),
    prop: Prop.staff,
  );

  static const potiphar = CharacterSpec(
    id: 'potiphar',
    name: 'Potiphar',
    skin: Color(0xFFA9703F),
    outfit: Color(0xFFF1EBDD),
    outfitAccent: Color(0xFFD9A62E),
    hair: Color(0xFF1F1612),
    headwear: Headwear.turban,
    headwearColor: Color(0xFFF1EBDD),
  );

  static const pharaon = CharacterSpec(
    id: 'pharaon',
    name: 'Pharaon',
    skin: Color(0xFFB87A48),
    outfit: Color(0xFF2E6FBF),
    outfitAccent: Color(0xFFE8B930),
    headwear: Headwear.nemes,
  );

  static const frere = CharacterSpec(
    id: 'frere',
    name: 'Un frère de Joseph',
    skin: Color(0xFFCB9560),
    outfit: Color(0xFF8E7A55),
    outfitAccent: Color(0xFF5E4B32),
    hair: Color(0xFF2B1A12),
    beard: Color(0xFF2B1A12),
    headwear: Headwear.headband,
    headwearColor: Color(0xFFD8C7A0),
    prop: Prop.staff,
  );

  /// « Voix trompeuse » : visage cache sous la capuche, yeux lumineux.
  static const murmure = CharacterSpec(
    id: 'murmure',
    name: 'Le Murmure',
    skin: Color(0xFF120D1E),
    outfit: Color(0xFF3A2D5C),
    outfitAccent: Color(0xFF7D5FD0),
    headwear: Headwear.hood,
    glowingEyes: true,
  );

  static const all = [lumo, joseph, jacob, potiphar, pharaon, frere, murmure];

  static CharacterSpec byId(String id) => all.firstWhere((c) => c.id == id, orElse: () => lumo);
}
