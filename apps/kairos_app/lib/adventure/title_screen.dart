import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart' show maxOil;

import '../app/controllers.dart';
import '../app/music.dart';
import '../app/providers.dart';
import '../characters/cast.dart';
import '../characters/character_widget.dart';
import '../characters/pose.dart';
import '../features/home/home_shell.dart';
import '../features/journal/journal_screen.dart';
import '../features/meditation/meditation_screen.dart';
import 'backdrop.dart';
import 'stone_button.dart';

/// Ecran-titre : decor d'aventure, logo en pierre, mascotte qui salue, et
/// les trois entrees du jeu.
class TitleScreen extends ConsumerWidget {
  const TitleScreen({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lamp = ref.watch(lampProvider).value;
    final music = ref.watch(musicProvider).value ?? true;
    final animated = ref.watch(animationsProvider);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AdventureBackdrop(animated: animated),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                // Petits telephones : on resserre pour garder les 3 boutons visibles.
                final compact = box.maxHeight < 640;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                          children: [
                            SizedBox(height: compact ? 6 : 40),
                            KairosLogo(animated: animated),
                            const Spacer(),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: Column(
                                children: [
                                  StoneButton(
                                    key: const ValueKey('play'),
                                    label: 'JOUER',
                                    fontSize: 30,
                                    height: compact ? 60 : 74,
                                    onPressed: () =>
                                        _open(context, const AdventureScreen()),
                                  ),
                                  const SizedBox(height: 14),
                                  StoneButton(
                                    key: const ValueKey('lamp'),
                                    label: 'MA LAMPE',
                                    subtitle: lamp == null
                                        ? null
                                        : 'Huile ${lamp.oil}/$maxOil · série ${lamp.streak} j',
                                    style: StoneStyle.moss,
                                    height: compact ? 56 : 66,
                                    leading: const Icon(
                                      Icons.local_fire_department,
                                      color: Color(0xFFC0501F),
                                    ),
                                    onPressed: () => _open(
                                      context,
                                      const MeditationScreen(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  StoneButton(
                                    key: const ValueKey('journal'),
                                    label: 'JOURNAL',
                                    style: StoneStyle.slate,
                                    fontSize: 22,
                                    height: compact ? 50 : 58,
                                    onPressed: () =>
                                        _open(context, const JournalScreen()),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 10 : 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StoneIconButton(
                                  key: const ValueKey('music'),
                                  icon: music
                                      ? Icons.music_note
                                      : Icons.music_off,
                                  semanticLabel: music
                                      ? 'Couper la musique'
                                      : 'Activer la musique',
                                  onPressed: () =>
                                      ref.read(musicProvider.notifier).toggle(),
                                ),
                              ],
                            ),
                            SizedBox(height: compact ? 8 : 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo « KAIROS » en lettres de pierre, avec Lumo qui dépasse et salue.
class KairosLogo extends StatelessWidget {
  const KairosLogo({super.key, this.animated = true});

  final bool animated;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'KAIROS, le chemin du disciple',
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Lumo est dessine en premier : le titre cache son corps et il
            // « dépasse » de derriere les lettres, comme dans un menu de jeu.
            Positioned(
              top: 0,
              right: -6,
              child: CharacterWidget(
                spec: Cast.lumo,
                action: CharacterAction.wave,
                mood: Mood.happy,
                height: 150,
                animated: animated,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _StoneTitle('KAIROS'),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Transform.rotate(
                      angle: -0.03,
                      child: const _Plaque('LE CHEMIN DU DISCIPLE'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoneTitle extends StatelessWidget {
  const _StoneTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 70,
      fontWeight: FontWeight.w900,
      letterSpacing: 5,
      height: 1.05,
    );
    Paint stroke(double w, Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeJoin = StrokeJoin.round
      ..color = c;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ombre portee, puis contour sombre, puis arete claire.
        Transform.translate(
          offset: const Offset(0, 7),
          child: Text(
            text,
            style: style.copyWith(
              foreground: stroke(16, const Color(0x55402010)),
            ),
          ),
        ),
        Text(
          text,
          style: style.copyWith(
            foreground: stroke(15, const Color(0xFF4A3322)),
          ),
        ),
        Text(
          text,
          style: style.copyWith(foreground: stroke(7, const Color(0xFFFFF1CF))),
        ),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7DDA0), Color(0xFFD9A857), Color(0xFFB9803E)],
          ).createShader(r),
          child: Text(text, style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}

class _Plaque extends StatelessWidget {
  const _Plaque(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6E9ED), Color(0xFFB9C0CA)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4A3322), width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
            color: Color(0xFF3C4654),
          ),
        ),
      ),
    );
  }
}
