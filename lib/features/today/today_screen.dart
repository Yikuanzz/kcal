import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/nutrition.dart';
import '../../core/theme.dart';
import '../../models/intake_entry.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/metric_bar.dart';
import '../shell/app_shell.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final today = dateOnly(DateTime.now());
    final isToday = dateOnly(day) == today;
    final intakes = ref.watch(intakesProvider);
    final target = ref.watch(targetProvider);
    final title = relativeDayTitle(day, DateTime.now());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addIntake),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: SafeArea(
        child: PageFrame(
          child: intakes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const _Message(text: '今日的账还没能展开'),
            data: (entries) {
              return target.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const _Message(text: '指标还没能读出来'),
                data: (goal) {
                  final summary = summarize(entries);
                  final overs = <String>[
                    if (IntakeProgress(consumed: summary.kcal, target: goal.kcal).exceeded)
                      '热量',
                    if (IntakeProgress(consumed: summary.carb, target: goal.carb).exceeded)
                      '碳水',
                    if (IntakeProgress(consumed: summary.protein, target: goal.protein).exceeded)
                      '蛋白质',
                    if (IntakeProgress(consumed: summary.fat, target: goal.fat).exceeded)
                      '脂肪',
                  ];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: '前一日',
                            onPressed: () => ref.read(selectedDayProvider.notifier).shift(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatDayLabel(day),
                                  style: const TextStyle(color: KcalColors.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: '后一日',
                            onPressed: isToday
                                ? null
                                : () => ref.read(selectedDayProvider.notifier).shift(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PaperCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '摄入对照',
                              style: TextStyle(
                                color: KcalColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            MetricBar(
                              label: '热量',
                              consumed: summary.kcal,
                              target: goal.kcal,
                              unit: 'kcal',
                              color: KcalColors.persimmon,
                              digits: 0,
                              emphasize: true,
                            ),
                            const SizedBox(height: 16),
                            MetricBar(
                              label: '碳水',
                              consumed: summary.carb,
                              target: goal.carb,
                              unit: 'g',
                              color: KcalColors.amber,
                            ),
                            const SizedBox(height: 14),
                            MetricBar(
                              label: '蛋白质',
                              consumed: summary.protein,
                              target: goal.protein,
                              unit: 'g',
                              color: KcalColors.sage,
                            ),
                            const SizedBox(height: 14),
                            MetricBar(
                              label: '脂肪',
                              consumed: summary.fat,
                              target: goal.fat,
                              unit: 'g',
                              color: KcalColors.rose,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (overs.isNotEmpty)
                        _StatusBanner(
                          background: KcalColors.overBg,
                          foreground: KcalColors.over,
                          icon: Icons.warning_amber_rounded,
                          text: '$title已超出：${overs.join('、')}',
                        )
                      else if (entries.isNotEmpty)
                        _StatusBanner(
                          background: KcalColors.okBg,
                          foreground: KcalColors.sage,
                          icon: Icons.check_circle_outline,
                          text: '$title尚未超标',
                        ),
                      const SizedBox(height: 18),
                      const Text(
                        '已记',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (entries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: _Message(
                            text: '这一日还未记过食物',
                            detail: '点右下角「记一笔」，从食物库里选一份',
                          ),
                        )
                      else
                        for (final entry in entries) ...[
                          _IntakeTile(entry: entry),
                          const SizedBox(height: 8),
                        ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IntakeTile extends ConsumerWidget {
  const _IntakeTile({required this.entry});

  final IntakeEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) {
        return confirmAction(
          context,
          title: '撤下这笔',
          message: '「${entry.foodName}」${formatAmount(entry.grams, 0)} g 将从这一日除去。',
          confirm: '撤下',
        );
      },
      onDismissed: (_) => ref.read(intakesProvider.notifier).remove(entry.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: KcalColors.overBg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline, color: KcalColors.over),
      ),
      child: PaperCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.foodName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatAmount(entry.grams, 0)} g · 碳 ${formatAmount(entry.carb, 1)} · 蛋 ${formatAmount(entry.protein, 1)} · 脂 ${formatAmount(entry.fat, 1)}',
                    style: const TextStyle(color: KcalColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '${formatAmount(entry.kcal, 0)} kcal',
              style: const TextStyle(fontWeight: FontWeight.w800, color: KcalColors.persimmonDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.text,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.rice_bowl_outlined, size: 40, color: KcalColors.muted),
        const SizedBox(height: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(detail!, style: const TextStyle(color: KcalColors.muted)),
        ],
      ],
    );
  }
}
