import '../core/nutrition.dart';
import 'food.dart';

class IntakeEntry {
  const IntakeEntry({
    required this.id,
    required this.day,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.kcal,
    required this.carb,
    required this.protein,
    required this.fat,
    required this.createdAt,
  });

  final String id;
  final String day;
  final String foodId;
  final String foodName;
  final double grams;
  final double kcal;
  final double carb;
  final double protein;
  final double fat;
  final int createdAt;

  MacroSet get macros =>
      MacroSet(kcal: kcal, carb: carb, protein: protein, fat: fat);

  Map<String, Object?> toMap() => {
    'id': id,
    'day': day,
    'foodId': foodId,
    'foodName': foodName,
    'grams': grams,
    'kcal': kcal,
    'carb': carb,
    'protein': protein,
    'fat': fat,
    'createdAt': createdAt,
  };

  factory IntakeEntry.fromMap(Map<String, Object?> map) {
    return IntakeEntry(
      id: map['id'] as String,
      day: map['day'] as String? ?? '',
      foodId: map['foodId'] as String? ?? '',
      foodName: map['foodName'] as String? ?? '',
      grams: asDouble(map['grams']),
      kcal: asDouble(map['kcal']),
      carb: asDouble(map['carb']),
      protein: asDouble(map['protein']),
      fat: asDouble(map['fat']),
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    );
  }
}

MacroSet summarize(Iterable<IntakeEntry> entries) {
  return entries.fold(MacroSet.zero, (sum, entry) => sum + entry.macros);
}
