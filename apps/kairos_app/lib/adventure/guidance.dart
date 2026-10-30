import 'package:flutter/material.dart';

import '../app/palette.dart';

/// Bandeau de consigne : dit au joueur ce qu'il doit faire, en une phrase.
/// Meme apparence sur tous les ecrans (histoire, defis, lampe).
class InstructionBanner extends StatelessWidget {
  const InstructionBanner({
    super.key,
    required this.text,
    this.title,
    this.icon = Icons.touch_app,
  });

  final String? title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title == null ? text : '$title. $text',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: hintBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hintBorder, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(color: ink, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: hintBackground),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink, height: 1.25),
                        ),
                      Text(
                        text,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte d'information sur parchemin, a la place de la `Card` Material, pour
/// que tous les blocs aient le meme habillage que les boutons de pierre.
class StoneCard extends StatelessWidget {
  const StoneCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder, width: 2),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Titre d'etape numerote (« 1 · Lis le passage »), pour montrer l'ordre a suivre.
class StepHeading extends StatelessWidget {
  const StepHeading({super.key, required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: ink, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(color: hintBackground, fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
          ),
        ],
      ),
    );
  }
}
