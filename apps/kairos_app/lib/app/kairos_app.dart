import 'package:flutter/material.dart';

import '../adventure/title_screen.dart';
import 'theme.dart';

class KairosApp extends StatelessWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAIROS',
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
              child: Text('KAIROS ne peut pas démarrer.\n\n$message', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
