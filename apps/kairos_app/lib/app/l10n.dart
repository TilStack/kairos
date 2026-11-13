import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n_en.dart';
import 'l10n_fr.dart';
import 'providers.dart';

/// Langues de l'application.
const supportedLanguages = ['fr', 'en'];

const _languageSetting = 'language';

/// Langue de l'appareil, ramenee a une langue geree (francais par defaut).
/// Les tests la remplacent pour rester en francais.
final deviceLanguageProvider = Provider<String>((ref) {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return supportedLanguages.contains(code) ? code : 'fr';
});

/// Langue choisie par le joueur : conservee sur l'appareil. Tant qu'il n'a
/// rien choisi, on suit la langue de l'appareil.
class LanguageController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final saved = await ref.watch(repositoryProvider).getSetting(_languageSetting);
    return supportedLanguages.contains(saved) ? saved! : ref.read(deviceLanguageProvider);
  }

  Future<void> set(String language) async {
    if (!supportedLanguages.contains(language)) return;
    state = AsyncData(language);
    await ref.read(repositoryProvider).setSetting(_languageSetting, language);
  }

  /// Passe de l'une a l'autre des deux langues.
  Future<void> toggle() => set(state.value == 'en' ? 'fr' : 'en');
}

final languageProvider = AsyncNotifierProvider<LanguageController, String>(LanguageController.new);

/// Langue courante, synchrone (francais le temps du chargement).
final langProvider = Provider<String>((ref) => ref.watch(languageProvider).value ?? ref.watch(deviceLanguageProvider));

/// Texte traduit : `{nom}` est remplace par l'argument correspondant.
/// Une cle absente d'une langue retombe sur le francais, puis sur la cle.
String translate(String lang, String key, [Map<String, Object> args = const {}]) {
  final table = lang == 'en' ? enStrings : frStrings;
  var text = table[key] ?? frStrings[key] ?? key;
  args.forEach((name, value) => text = text.replaceAll('{$name}', '$value'));
  return text;
}

/// Diffuse la langue courante a tout l'arbre : les ecrans se reconstruisent
/// quand elle change.
class L10n extends InheritedWidget {
  const L10n({super.key, required this.lang, required super.child});

  final String lang;

  /// Langue du contexte ; francais hors `L10n` (apercus et tests isoles).
  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<L10n>()?.lang ?? 'fr';

  @override
  bool updateShouldNotify(L10n old) => old.lang != lang;
}

extension Translate on BuildContext {
  String get lang => L10n.of(this);

  String tr(String key, [Map<String, Object> args = const {}]) => translate(lang, key, args);
}
