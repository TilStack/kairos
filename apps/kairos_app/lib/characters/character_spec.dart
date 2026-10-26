import 'dart:ui';

/// Coiffe / couvre-chef.
enum Headwear { none, headband, turban, nemes, hood }

/// Accessoire tenu en main.
enum Prop { none, staff, scroll }

/// Apparence d'un personnage : de la donnee pure, sans logique de dessin.
/// Un nouvel acteur = une nouvelle fiche, pas de nouveau code.
class CharacterSpec {
  const CharacterSpec({
    required this.id,
    required this.name,
    required this.skin,
    required this.outfit,
    this.outfitAccent,
    this.stripes = const [],
    this.hair,
    this.beard,
    this.headwear = Headwear.none,
    this.headwearColor = const Color(0xFFF2E8CF),
    this.prop = Prop.none,
    this.flameHead = false,
    this.glowingEyes = false,
    this.scale = 1,
  });

  final String id;
  final String name;
  final Color skin;

  /// Couleur principale du vetement.
  final Color outfit;
  final Color? outfitAccent;

  /// Bandes de couleur verticales (tunique de Joseph).
  final List<Color> stripes;
  final Color? hair;
  final Color? beard;
  final Headwear headwear;
  final Color headwearColor;
  final Prop prop;

  /// Mascotte : la tete est une flamme.
  final bool flameHead;

  /// Yeux lumineux (« voix trompeuse », visage cache sous la capuche).
  final bool glowingEyes;

  /// Taille relative (enfant < 1, adulte = 1).
  final double scale;
}
