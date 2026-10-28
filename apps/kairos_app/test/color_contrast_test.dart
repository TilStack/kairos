import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/adventure/stone_button.dart';
import 'package:kairos_app/app/palette.dart';
import 'package:kairos_app/characters/cast.dart';

/// Garde-fou de lisibilite (norme WCAG 2) : une couleur mal assortie fait
/// echouer le test au lieu de se decouvrir sur un telephone.
///
/// Seuils : 4,5 pour du texte courant, 3 pour un gros texte (>= 18 px gras)
/// ou un element d'interface.
void main() {
  const normalText = 4.5;
  const largeText = 3.0;

  double worst(Color fg, List<Color> backgrounds) =>
      backgrounds.map((b) => contrastRatio(fg, b)).reduce((a, b) => a < b ? a : b);

  group('texte sur parchemin', () {
    const parchment = [parchmentTop, parchmentBottom];

    test('texte courant', () => expect(worst(ink, parchment), greaterThanOrEqualTo(normalText)));
    test('note discrete', () => expect(worst(inkSoft, parchment), greaterThanOrEqualTo(normalText)));
    test('reference biblique (l or vif des decors ne passerait pas)', () {
      expect(worst(scriptureRef, parchment), greaterThanOrEqualTo(normalText));
      expect(worst(const Color(0xFFC8962E), parchment), lessThan(normalText), reason: 'garde la raison d etre du test');
    });
  });

  group('boutons de pierre', () {
    for (final style in StoneStyle.values) {
      test('${style.name} : libelle (gros texte) et sous-titre (petit texte)', () {
        final faces = [style.top, style.bottom];
        expect(worst(style.text, faces), greaterThanOrEqualTo(largeText), reason: 'libelle');
        // Le sous-titre est affiche en petit uniquement sur les boutons mousse.
        if (style == StoneStyle.moss || style == StoneStyle.sand) {
          expect(worst(style.text, faces), greaterThanOrEqualTo(normalText), reason: 'sous-titre / option de choix');
        }
      });
    }
  });

  group('personnages sur les decors', () {
    // Le contour sombre est ce qui detache un personnage de son decor : il
    // doit contraster avec tous les lieux, y compris pour les tenues claires.
    for (final entry in backdropTones.entries) {
      test('contour visible sur le decor « ${entry.key} »', () {
        expect(worst(characterOutline, entry.value), greaterThanOrEqualTo(largeText));
      });
    }

    test('aucun personnage sombre ne disparait sur un decor sombre', () {
      for (final c in Cast.all) {
        // Habit ET contour sombres sur un decor sombre = silhouette perdue.
        for (final entry in backdropTones.entries) {
          final bgDark = worst(const Color(0xFFFFFFFF), entry.value) > 4.5;
          final outfitDark = contrastRatio(c.outfit, const Color(0xFF000000)) < 3;
          expect(bgDark && outfitDark, isFalse, reason: '${c.name} sur ${entry.key}');
        }
      }
    });

    test('les habits colores se distinguent de chaque decor (rapport >= 1,5)', () {
      // Les tenues blanches (Lumo, Potiphar) sont exclues : elles ne se
      // distinguent des decors clairs que grace a leur contour, verifie plus haut.
      for (final c in Cast.all.where((c) => c.outfit.computeLuminance() < 0.6)) {
        for (final entry in backdropTones.entries) {
          expect(worst(c.outfit, entry.value), greaterThanOrEqualTo(1.5), reason: '${c.name} sur ${entry.key}');
        }
      }
    });
  });

  test('contrastRatio : valeurs de reference WCAG', () {
    expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21, 0.01));
    expect(contrastRatio(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)), closeTo(1, 0.001));
  });
}
