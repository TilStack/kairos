import 'package:flutter/material.dart';

/// Or de la lampe : couleur d'accent de l'application.
const lampGold = Color(0xFFC8962E);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2B3A67),
    secondary: lampGold,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: brightness == Brightness.light ? const Color(0xFFFBF1DA) : null,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
  );
}
