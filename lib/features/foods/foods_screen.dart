import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/nutrition.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/food_avatar.dart';
import '../shell/app_shell.dart';

class FoodsScreen extends ConsumerWidget {
  const FoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foods = ref.watch(foodsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.foodForm),
        icon: const Icon(Icons.add),
        label: const Text('新食物'),
      ),
      body: SafeArea(
        child: PageFrame(
          child: foods.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Center(child: Text('食物库暂时打不开')),
            data: (items) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 108),
                children: [
                  const Text(
                    '食物',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '按每 100 克记下千焦、碳水、蛋白质和脂肪。千卡会自行换算。照片只留在这台设备上。',
                    style: TextStyle(color: KcalColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('库中还没有食物', style: TextStyle(color: KcalColors.muted)),
                    )
                  else
                    for (final food in items) ...[
                      PaperCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            FoodAvatar(imageBase64: food.imageBase64),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push(AppRoutes.foodForm, extra: food),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${formatAmount(food.kjPer100g, 0)} kJ · ${formatAmount(food.kcalPer100g, 0)} kcal',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        '碳 ${formatAmount(food.carbPer100g, 1)} · 蛋 ${formatAmount(food.proteinPer100g, 1)} · 脂 ${formatAmount(food.fatPer100g, 1)} / 100 g',
                                        style: const TextStyle(
                                          color: KcalColors.muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: '删除',
                              onPressed: () async {
                                final ok = await confirmAction(
                                  context,
                                  title: '删除食物',
                                  message: '「${food.name}」将从食物库中除去。已经记下的摄入仍会保留。',
                                  confirm: '删除',
                                );
                                if (!ok) return;
                                await ref.read(foodsProvider.notifier).remove(food.id);
                              },
                              icon: const Icon(Icons.delete_outline, color: KcalColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
