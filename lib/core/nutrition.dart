/// 1 kcal = 4.184 kJ。食物按千焦录入，千卡由此换算。
const double kjPerKcal = 4.184;

double kcalFromKj(double kj) => kj / kjPerKcal;

double scaleByGrams(double per100g, double grams) => per100g * grams / 100;

class MacroSet {
  const MacroSet({
    required this.kcal,
    required this.carb,
    required this.protein,
    required this.fat,
  });

  final double kcal;
  final double carb;
  final double protein;
  final double fat;

  static const zero = MacroSet(kcal: 0, carb: 0, protein: 0, fat: 0);

  MacroSet operator +(MacroSet other) {
    return MacroSet(
      kcal: kcal + other.kcal,
      carb: carb + other.carb,
      protein: protein + other.protein,
      fat: fat + other.fat,
    );
  }
}

MacroSet scaleFood({
  required double grams,
  required double kjPer100g,
  required double carbPer100g,
  required double proteinPer100g,
  required double fatPer100g,
}) {
  return MacroSet(
    kcal: scaleByGrams(kcalFromKj(kjPer100g), grams),
    carb: scaleByGrams(carbPer100g, grams),
    protein: scaleByGrams(proteinPer100g, grams),
    fat: scaleByGrams(fatPer100g, grams),
  );
}

class IntakeProgress {
  const IntakeProgress({required this.consumed, required this.target});

  final double consumed;
  final double target;

  bool get hasTarget => target > 0;

  bool get exceeded => hasTarget && consumed - target > 0.05;

  bool get met => hasTarget && (consumed - target).abs() <= 0.05;

  double get ratio => hasTarget ? consumed / target : 0;
}

String formatAmount(double value, int digits) {
  if (digits <= 0) return value.round().toString();
  var text = value.toStringAsFixed(digits);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}

String progressCaption(
  IntakeProgress progress, {
  required String unit,
  int digits = 0,
}) {
  if (!progress.hasTarget) return '尚未设置指标';
  if (progress.exceeded) {
    return '超出 ${formatAmount(progress.consumed - progress.target, digits)} $unit';
  }
  if (progress.met) return '刚好达到指标';
  return '尚余 ${formatAmount(progress.target - progress.consumed, digits)} $unit';
}

double? parseAmount(String raw) {
  final text = raw.trim().replaceAll('，', '.').replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

String dayKey(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$y-$m-$dd';
}

String formatDayLabel(DateTime day) {
  const weeks = ['一', '二', '三', '四', '五', '六', '日'];
  final d = DateTime(day.year, day.month, day.day);
  return '${d.month}月${d.day}日 周${weeks[d.weekday - 1]}';
}

String relativeDayTitle(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(day.year, day.month, day.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return '今日';
  if (diff == 1) return '昨日';
  return formatDayLabel(d);
}

DateTime dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);
