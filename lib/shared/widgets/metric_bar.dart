import 'package:flutter/material.dart';

import '../../core/nutrition.dart';
import '../../core/theme.dart';

class MetricBar extends StatelessWidget {
  const MetricBar({
    super.key,
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
    this.digits = 1,
    this.emphasize = false,
  });

  final String label;
  final double consumed;
  final double target;
  final String unit;
  final Color color;
  final int digits;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final progress = IntakeProgress(consumed: consumed, target: target);
    final barColor = progress.exceeded ? KcalColors.over : color;
    final value = progress.hasTarget ? progress.ratio.clamp(0, 1).toDouble() : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: emphasize ? 15 : 13,
                fontWeight: FontWeight.w700,
                color: KcalColors.ink,
              ),
            ),
            const Spacer(),
            Text(
              '${formatAmount(consumed, digits)} / ${formatAmount(target, digits)} $unit',
              style: TextStyle(
                fontSize: emphasize ? 15 : 13,
                fontWeight: FontWeight.w600,
                color: progress.exceeded ? KcalColors.over : KcalColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value,
            minHeight: emphasize ? 12 : 8,
            backgroundColor: KcalColors.line,
            color: barColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          progressCaption(progress, unit: unit, digits: digits),
          style: TextStyle(
            fontSize: 12,
            color: progress.exceeded ? KcalColors.over : KcalColors.muted,
            fontWeight: progress.exceeded ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
