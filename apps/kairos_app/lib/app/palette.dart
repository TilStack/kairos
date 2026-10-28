import 'dart:ui';

/// Palette commune du jeu. Les couleurs qui portent du texte ou qui servent
/// de fond a un personnage sont ici, en un seul endroit, pour que le test
/// `color_contrast_test.dart` verifie leur lisibilite (norme WCAG).

/// Encre du texte sur parchemin.
const ink = Color(0xFF3A2A1A);
const inkSoft = Color(0xFF5B4630);

/// Panneau de texte en parchemin (haut, bas).
const parchmentTop = Color(0xFFFFF6E0);
const parchmentBottom = Color(0xFFF4E2B8);

/// Reference biblique sous un verset : or fonce, lisible sur parchemin
/// (l'or vif des decors n'atteint que 2:1).
const scriptureRef = Color(0xFF75500F);

/// Contour sombre des personnages : il les detache de tous les decors.
const characterOutline = Color(0xFF2A1F3D);

/// Couleurs dominantes derriere les personnages, par lieu (haut, bas).
const desertSky = [Color(0xFFBFE3EE), Color(0xFFFBE1B0)];
const houseWall = [Color(0xFFEBCB9C), Color(0xFFD9A873)];
const palaceWall = [Color(0xFFF1E4C3), Color(0xFFDDC795)];
const memoryTone = [Color(0xFFEBD9B4), Color(0xFFC9A877)];

const backdropTones = {
  'desert': desertSky,
  'house': houseWall,
  'palace': palaceWall,
  'memory': memoryTone,
};

/// Rapport de contraste WCAG entre deux couleurs opaques (1 a 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
