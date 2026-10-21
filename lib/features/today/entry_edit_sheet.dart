import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nutrition.dart';
import '../../core/theme.dart';
import '../../models/food.dart';
import '../../models/intake_entry.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/food_avatar.dart';
import '../../shared/widgets/food_pick_tile.dart';
import '../shell/app_shell.dart';

/// 一笔记录的编辑面板，以 modal bottom sheet 打开：
/// - 改克数：按原记录折算出每 100 克，再按新克数重算；
/// - 换食物：改用所选食物的每 100 克数值；
/// - 删除：pop 回传原记录，由打开方执行删除并给出撤销提示。
class EntryEditSheet extends ConsumerStatefulWidget {
  const EntryEditSheet({super.key, required this.entry});

  final IntakeEntry entry;

  @override
  ConsumerState<EntryEditSheet> createState() => _EntryEditSheetState();
}

class _EntryEditSheetState extends ConsumerState<EntryEditSheet> {
  late final TextEditingController _grams;
  final TextEditingController _search = TextEditingController();
  late MacroSet _base100;
  late String _foodId;
  late String _foodName;
  var _picking = false;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _grams = TextEditingController(text: formatAmount(entry.grams, 0));
    _base100 = entry.grams > 0
        ? MacroSet(
            kcal: entry.kcal * 100 / entry.grams,
            carb: entry.carb * 100 / entry.grams,
            protein: entry.protein * 100 / entry.grams,
            fat: entry.fat * 100 / entry.grams,
          )
        : MacroSet.zero;
    _foodId = entry.foodId;
    _foodName = entry.foodName;
  }

  @override
  void dispose() {
    _grams.dispose();
    _search.dispose();
    super.dispose();
  }

  double? get _gramsValue => parseAmount(_grams.text);

  bool _gramsOk(double? grams) => grams != null && grams > 0 && grams <= 5000;

  MacroSet _preview(double grams) => MacroSet(
        kcal: _base100.kcal * grams / 100,
        carb: _base100.carb * grams / 100,
        protein: _base100.protein * grams / 100,
        fat: _base100.fat * grams / 100,
      );

  String? _imageOf(AsyncValue<List<Food>> foods) {
    final items = foods.value;
    if (items == null) return null;
    for (final food in items) {
      if (food.id == _foodId) return food.imageBase64;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodsProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: _picking ? _picker(foods) : _editor(_imageOf(foods)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editor(String? imageBase64) {
    final grams = _gramsValue;
    final preview = _gramsOk(grams) ? _preview(grams!) : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _DragHandle()),
        const SizedBox(height: 14),
        Row(
          children: [
            FoodAvatar(imageBase64: imageBase64),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _foodName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _picking = true),
              icon: const Icon(Icons.swap_horiz, size: 20),
              label: const Text('换一份'),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
        if (!_gramsOk(grams) || _error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error ?? '克数请填 0 到 5000',
            style: const TextStyle(color: KcalColors.over),
          ),
        ],
        if (preview != null) ...[
          const SizedBox(height: 14),
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
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '正在保存…' : '保存修改'),
        ),
        TextButton.icon(
          onPressed: _saving
              ? null
              : () => Navigator.pop(context, widget.entry),
          icon: const Icon(Icons.delete_outline, size: 20, color: KcalColors.over),
          label: const Text(
            '记错了，删掉这一笔',
            style: TextStyle(color: KcalColors.over),
          ),
        ),
      ],
    );
  }

  Widget _picker(AsyncValue<List<Food>> foods) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _DragHandle()),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: '回到这笔记录',
              onPressed: () => setState(() => _picking = false),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                '换成库里另一份食物',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: '搜索食物',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: foods.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('食物库暂时打不开'),
            ),
            data: (all) {
              final query = _search.text.trim();
              final visible = all
                  .where((food) => query.isEmpty || food.name.contains(query))
                  .toList();
              if (all.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '食物库还是空的。先到「食物」里添一份。',
                    style: TextStyle(color: KcalColors.muted),
                  ),
                );
              }
              if (visible.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('没有同名的食物', style: TextStyle(color: KcalColors.muted)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final food = visible[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FoodPickTile(
                      food: food,
                      selected: food.id == _foodId,
                      onTap: () => _pickFood(food),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _nudge(int delta) {
    final current = parseAmount(_grams.text) ?? 0;
    final next = (current + delta).clamp(0, 5000).toDouble();
    _grams.text = formatAmount(next, next == next.roundToDouble() ? 0 : 1);
    setState(() {});
  }

  void _pickFood(Food food) {
    setState(() {
      _foodId = food.id;
      _foodName = food.name;
      _base100 = MacroSet(
        kcal: kcalFromKj(food.kjPer100g),
        carb: food.carbPer100g,
        protein: food.proteinPer100g,
        fat: food.fatPer100g,
      );
      _picking = false;
      _search.clear();
    });
  }

  Future<void> _save() async {
    final grams = _gramsValue;
    if (!_gramsOk(grams)) {
      setState(() => _error = '克数请填 0 到 5000');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final preview = _preview(grams!);
    final entry = widget.entry;
    final updated = IntakeEntry(
      id: entry.id,
      day: entry.day,
      foodId: _foodId,
      foodName: _foodName,
      grams: grams,
      kcal: preview.kcal,
      carb: preview.carb,
      protein: preview.protein,
      fat: preview.fat,
      createdAt: entry.createdAt,
    );
    try {
      await ref.read(intakesProvider.notifier).save(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '没保存上，再试一次';
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: KcalColors.line,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
