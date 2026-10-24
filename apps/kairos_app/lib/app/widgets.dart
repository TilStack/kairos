import 'package:flutter/material.dart';
import 'package:kairos_core/kairos_core.dart';

import 'theme.dart';

/// Libelles francais des traits du coeur.
const traitLabels = {
  Trait.faith: 'Foi',
  Trait.courage: 'Courage',
  Trait.integrity: 'Intégrité',
  Trait.compassion: 'Compassion',
  Trait.humility: 'Humilité',
  Trait.wisdom: 'Sagesse',
};

/// Libelles francais des anomalies de discernement.
const anomalyLabels = {
  AnomalyType.distorted: 'Verset déformé',
  AnomalyType.truncated: 'Verset tronqué',
  AnomalyType.outOfContext: 'Sorti de son contexte',
  AnomalyType.misattributed: 'Faussement attribué',
};

const levelLabels = {
  1: 'Niveau 1 · Reconstitution',
  2: 'Niveau 2 · Mots manquants',
  3: 'Niveau 3 · De mémoire',
};

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
      label: 'Écriture, $reference',
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
              text == null ? 'Texte indisponible dans cette version.' : '« $text »',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reference,
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary),
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
      label: 'Lampe : huile ${lamp.oil} sur $maxOil, série de ${lamp.streak} jours, '
          '${lamp.goldVials} fioles d\'or',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              Text('Huile : ${lamp.oil} / $maxOil', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 16,
                children: [
                  Text('Série : ${lamp.streak} j'),
                  Text('Fioles d\'or : ${lamp.goldVials}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
