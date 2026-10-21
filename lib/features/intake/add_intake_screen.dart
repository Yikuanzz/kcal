import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/nutrition.dart';
import '../../core/theme.dart';
import '../../models/food.dart';
import '../../models/intake_entry.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/food_pick_tile.dart';
import '../shell/app_shell.dart';

class AddIntakeScreen extends ConsumerStatefulWidget {
  const AddIntakeScreen({super.key});

  @override
  ConsumerState<AddIntakeScreen> createState() => _AddIntakeScreenState();
}

class _AddIntakeScreenState extends ConsumerState<AddIntakeScreen> {
  final _search = TextEditingController();
  final _grams = TextEditingController(text: '100');
  String? _foodId;
  var _saving = false;

  @override
  void dispose() {
    _search.dispose();
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodsProvider);
    final day = ref.watch(selectedDayProvider);
    final title = relativeDayTitle(day, DateTime.now());
    final query = _search.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text('记入$title'),
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: PageFrame(
          child: foods.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Center(child: Text('食物库暂时打不开')),
            data: (all) {
              final visible = all.where((food) {
                if (query.isEmpty) return true;
                return food.name.contains(query);
              }).toList();
              Food? selected;
              for (final food in all) {
                if (food.id == _foodId) selected = food;
              }
              final grams = parseAmount(_grams.text);
              final gramsTooLarge = grams != null && grams > 5000;
              final preview = selected == null || grams == null || grams <= 0 || gramsTooLarge
                  ? null
                  : scaleFood(
                      grams: grams,
                      kjPer100g: selected.kjPer100g,
                      carbPer100g: selected.carbPer100g,
                      proteinPer100g: selected.proteinPer100g,
                      fatPer100g: selected.fatPer100g,
                    );

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: '搜索食物',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (all.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        '食物库还是空的。先到「食物」里添一份，再回来记。',
                        style: TextStyle(color: KcalColors.muted),
                      ),
                    )
                  else if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Text('没有同名的食物', style: TextStyle(color: KcalColors.muted)),
                    )
                  else
                    for (final food in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FoodPickTile(
                          food: food,
                          selected: food.id == _foodId,
                          onTap: () => setState(() => _foodId = food.id),
                        ),
                      ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: '减少 10 克',
                        onPressed: () => _nudge(-10),
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _grams,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,，]')),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: '食用克数',
                            suffixText: 'g',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: '增加 10 克',
                        onPressed: () => _nudge(10),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (gramsTooLarge)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '一次先记到 5000 克以内',
                        style: TextStyle(color: KcalColors.over),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (preview != null)
                    PaperCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '这一份约 ${formatAmount(preview.kcal, 0)} kcal',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '碳水 ${formatAmount(preview.carb, 1)} g · 蛋白质 ${formatAmount(preview.protein, 1)} g · 脂肪 ${formatAmount(preview.fat, 1)} g',
                            style: const TextStyle(color: KcalColors.muted),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _saving || preview == null || selected == null
                        ? null
                        : () => _save(selected!, grams!, preview),
                    child: Text(_saving ? '正在记下…' : '记下这一份'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _nudge(int delta) {
    final current = parseAmount(_grams.text) ?? 0;
    final next = (current + delta).clamp(0, 5000).toDouble();
    _grams.text = formatAmount(next, next == next.roundToDouble() ? 0 : 1);
    setState(() {});
  }

  Future<void> _save(Food food, double grams, MacroSet preview) async {
    setState(() => _saving = true);
    final day = ref.read(selectedDayProvider);
    final entry = IntakeEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      day: dayKey(day),
      foodId: food.id,
      foodName: food.name,
      grams: grams,
      kcal: preview.kcal,
      carb: preview.carb,
      protein: preview.protein,
      fat: preview.fat,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.read(intakesProvider.notifier).add(entry);
    if (!mounted) return;
    context.pop();
  }
}
