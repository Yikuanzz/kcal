import 'food.dart';

class DailyTarget {
  const DailyTarget({
    required this.kcal,
    required this.carb,
    required this.protein,
    required this.fat,
  });

  final double kcal;
  final double carb;
  final double protein;
  final double fat;

  /// 初次使用时的起点，可在「指标」里改掉。
  static const standard = DailyTarget(
    kcal: 2000,
    carb: 250,
    protein: 90,
    fat: 60,
  );

  Map<String, Object?> toMap() => {
    'kcal': kcal,
    'carb': carb,
    'protein': protein,
    'fat': fat,
  };

  factory DailyTarget.fromMap(Map<String, Object?> map) {
    return DailyTarget(
      kcal: asDouble(map['kcal']),
      carb: asDouble(map['carb']),
      protein: asDouble(map['protein']),
      fat: asDouble(map['fat']),
    );
  }
}
