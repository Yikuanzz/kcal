import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/nutrition.dart';
import '../../core/theme.dart';
import '../../models/food.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/food_avatar.dart';

class FoodFormScreen extends ConsumerStatefulWidget {
  const FoodFormScreen({super.key, this.existing});

  final Food? existing;

  @override
  ConsumerState<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends ConsumerState<FoodFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _kj;
  late final TextEditingController _carb;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  String? _imageBase64;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final food = widget.existing;
    _name = TextEditingController(text: food?.name ?? '');
    _kj = TextEditingController(
      text: food == null ? '' : formatAmount(food.kjPer100g, 1),
    );
    _carb = TextEditingController(
      text: food == null ? '' : formatAmount(food.carbPer100g, 1),
    );
    _protein = TextEditingController(
      text: food == null ? '' : formatAmount(food.proteinPer100g, 1),
    );
    _fat = TextEditingController(
      text: food == null ? '' : formatAmount(food.fatPer100g, 1),
    );
    _imageBase64 = food?.imageBase64;
  }

  @override
  void dispose() {
    _name.dispose();
    _kj.dispose();
    _carb.dispose();
    _protein.dispose();
    _fat.dispose();
    super.dispose();
  }

  double? get _kjValue => parseAmount(_kj.text);

  @override
  Widget build(BuildContext context) {
    final kj = _kjValue;
    final kcalText = kj == null || kj < 0
        ? '填写千焦后，这里会换算成千卡'
        : '约 ${formatAmount(kcalFromKj(kj), 1)} kcal / 100 g';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? '新食物' : '改食物'),
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Row(
                  children: [
                    FoodAvatar(imageBase64: _imageBase64, size: 84),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _pick(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('拍照'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _pick(ImageSource.gallery),
                            icon: const Icon(Icons.photo_outlined),
                            label: const Text('相册'),
                          ),
                          if (_imageBase64 != null)
                            TextButton(
                              onPressed: () => setState(() => _imageBase64 = null),
                              child: const Text('去掉照片'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                const SizedBox(height: 18),
                const Text(
                  '每 100 克',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _kj,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,，]')),
                  ],
                  decoration: InputDecoration(
                    labelText: '热量',
                    suffixText: 'kJ',
                    helperText: kcalText,
                  ),
                ),
                const SizedBox(height: 12),
                _macroField(_carb, '碳水', 'g'),
                const SizedBox(height: 12),
                _macroField(_protein, '蛋白质', 'g'),
                const SizedBox(height: 12),
                _macroField(_fat, '脂肪', 'g'),
                const SizedBox(height: 8),
                const Text(
                  '换算按 1 kcal = 4.184 kJ。照片存在本机，不会上传。',
                  style: TextStyle(color: KcalColors.muted, height: 1.4),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: KcalColors.over)),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '正在保存…' : '保存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _macroField(TextEditingController controller, String label, String suffix) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,，]'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 78,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBase64 = base64Encode(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未能取得照片，可改从相册选择')),
      );
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final kj = parseAmount(_kj.text);
    final carb = parseAmount(_carb.text);
    final protein = parseAmount(_protein.text);
    final fat = parseAmount(_fat.text);

    if (name.isEmpty) {
      setState(() => _error = '请写上食物的名字');
      return;
    }
    if (kj == null || kj < 0 || kj > 9000) {
      setState(() => _error = '热量请填 0 到 9000 千焦');
      return;
    }
    if (carb == null ||
        protein == null ||
        fat == null ||
        carb < 0 ||
        protein < 0 ||
        fat < 0 ||
        carb > 100 ||
        protein > 100 ||
        fat > 100) {
      setState(() => _error = '碳水、蛋白质、脂肪请填 0 到 100 克');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final existing = widget.existing;
    final food = Food(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      kjPer100g: kj,
      carbPer100g: carb,
      proteinPer100g: protein,
      fatPer100g: fat,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      imageBase64: _imageBase64,
    );
    await ref.read(foodsProvider.notifier).save(food);
    if (!mounted) return;
    context.pop();
  }
}
