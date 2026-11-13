import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../adventure/title_screen.dart';
import 'l10n.dart';
import 'theme.dart';

class KairosApp extends ConsumerWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return MaterialApp(
      title: 'KAIROS',
      locale: Locale(lang),
      // Les ecrans lisent la langue ici : ils se reconstruisent quand elle change.
      builder: (context, child) => L10n(lang: lang, child: child!),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      // Decors et panneaux de parchemin sont peints pour le jour : pas de theme sombre.
      themeMode: ThemeMode.light,
      home: const TitleScreen(),
    );
  }
}

/// Ecran affiche si le demarrage echoue (contenu invalide, base illisible) :
/// jamais d'ecran blanc ni de plantage silencieux.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(translate(PlatformDispatcher.instance.locale.languageCode == 'en' ? 'en' : 'fr', 'startup.error', {'msg': message}), textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
