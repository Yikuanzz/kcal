import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nutrition.dart';
import '../../core/theme.dart';
import '../../models/daily_target.dart';
import '../../providers/providers.dart';
import '../shell/app_shell.dart';

class TargetsScreen extends ConsumerWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(targetProvider);
    return Scaffold(
      body: SafeArea(
        child: PageFrame(
          child: target.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Center(child: Text('指标暂时读不出来')),
            data: (value) => _TargetForm(initial: value),
          ),
        ),
      ),
    );
  }
}

class _TargetForm extends ConsumerStatefulWidget {
  const _TargetForm({required this.initial});

  final DailyTarget initial;

  @override
  ConsumerState<_TargetForm> createState() => _TargetFormState();
}

class _TargetFormState extends ConsumerState<_TargetForm> {
  late final TextEditingController _kcal;
  late final TextEditingController _carb;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final target = widget.initial;
    _kcal = TextEditingController(text: formatAmount(target.kcal, 0));
    _carb = TextEditingController(text: formatAmount(target.carb, 1));
    _protein = TextEditingController(text: formatAmount(target.protein, 1));
    _fat = TextEditingController(text: formatAmount(target.fat, 1));
  }

  @override
  void dispose() {
    _kcal.dispose();
    _carb.dispose();
    _protein.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const Text('指标', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          '给自己定一天的热量、碳水、蛋白质和脂肪。今日页会拿吃进去的分量来对照，超出便会标明。',
          style: TextStyle(color: KcalColors.muted, height: 1.45),
        ),
        const SizedBox(height: 18),
        _field(_kcal, '热量', 'kcal'),
        const SizedBox(height: 12),
        _field(_carb, '碳水', 'g'),
        const SizedBox(height: 12),
        _field(_protein, '蛋白质', 'g'),
        const SizedBox(height: 12),
        _field(_fat, '脂肪', 'g'),
        const SizedBox(height: 8),
        const Text(
          '填 0 表示这一项先不设限。此处只供自己记账，并非膳食处方。',
          style: TextStyle(color: KcalColors.muted, height: 1.4),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: KcalColors.over)),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '正在保存…' : '保存指标'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, String suffix) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,，]'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }

  Future<void> _save() async {
    final kcal = parseAmount(_kcal.text);
    final carb = parseAmount(_carb.text);
    final protein = parseAmount(_protein.text);
    final fat = parseAmount(_fat.text);

    if (kcal == null || carb == null || protein == null || fat == null) {
      setState(() => _error = '四项都要填上数字，不设限可填 0');
      return;
    }
    if (kcal < 0 || kcal > 20000 || carb < 0 || carb > 2000 || protein < 0 || protein > 2000 || fat < 0 || fat > 2000) {
      setState(() => _error = '热量不超过 20000 kcal，其余三项不超过 2000 g');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(targetProvider.notifier).save(
      DailyTarget(kcal: kcal, carb: carb, protein: protein, fat: fat),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('今日的尺子已经改好')),
    );
  }
}
