import 'package:flutter/material.dart';
import 'package:kairos_core/kairos_core.dart';

import '../adventure/guidance.dart';
import 'l10n.dart';
import 'palette.dart';
import 'theme.dart';

/// Libelle d'un trait du coeur, dans la langue de l'interface.
String traitLabel(BuildContext context, Trait t) => context.tr('trait.${t.name}');

/// Libelle et explication d'une anomalie de discernement.
String anomalyLabel(BuildContext context, AnomalyType t) => context.tr('anomaly.${t.id}');
String anomalyHint(BuildContext context, AnomalyType t) => context.tr('anomaly.${t.id}.hint');

/// Libelle du niveau d'une Porte (1 a 3).
String levelLabel(BuildContext context, int level) => context.tr('level.$level');

/// Texte de l'Ecriture : typographie dediee (serif, filet dore), toujours
/// distincte de la narration (CDC §9.5). Le texte est cite tel quel.
class ScriptureBlock extends StatelessWidget {
  const ScriptureBlock({super.key, required this.reference, required this.text});

  final String reference;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: context.tr('scripture.semantic', {'ref': reference}),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: const Border(left: BorderSide(color: lampGold, width: 4)),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text == null
                  ? context.tr('scripture.missing')
                  : '${context.tr('quote.open')}$text${context.tr('quote.close')}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reference,
              style: theme.textTheme.labelLarge?.copyWith(color: scriptureRef, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Jauge de la lampe : flamme, huile, serie et fioles d'or.
class LampGauge extends StatelessWidget {
  const LampGauge({super.key, required this.lamp});

  final LampState lamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = lamp.oil / maxOil;
    return Semantics(
      label: context.tr('lamp.semantic', {
        'oil': lamp.oil,
        'max': maxOil,
        'streak': lamp.streak,
        'vials': lamp.goldVials,
      }),
      child: StoneCard(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              AnimatedScale(
                scale: 0.8 + 0.5 * level,
                duration: const Duration(milliseconds: 400),
                child: Icon(
                  Icons.local_fire_department,
                  size: 64,
                  color: Color.lerp(theme.colorScheme.outline, lampGold, level),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: level, minHeight: 10, color: lampGold),
              ),
              const SizedBox(height: 8),
              Text(context.tr('lamp.oil', {'oil': lamp.oil, 'max': maxOil}), style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 16,
                children: [
                  Text(context.tr('lamp.streak', {'n': lamp.streak})),
                  Text(context.tr('lamp.vials', {'n': lamp.goldVials})),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('lamp.hint'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
