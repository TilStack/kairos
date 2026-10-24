import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('app.kairos/secure');

/// Interdit captures d'ecran et apercu dans les applications recentes
/// tant que cet ecran est affiche (Android : FLAG_SECURE). Utilise pour le
/// Journal, qui contient des prieres personnelles.
class SecureScope extends StatefulWidget {
  const SecureScope({super.key, required this.child});

  final Widget child;

  @override
  State<SecureScope> createState() => _SecureScopeState();
}

class _SecureScopeState extends State<SecureScope> {
  @override
  void initState() {
    super.initState();
    _set(true);
  }

  @override
  void dispose() {
    _set(false);
    super.dispose();
  }

  /// Hors Android (tests, bureau) le canal n'existe pas : sans effet.
  static Future<void> _set(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on MissingPluginException {
      // Plateforme sans prise en charge.
    } on PlatformException {
      // Echec non bloquant : l'ecran reste utilisable.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
