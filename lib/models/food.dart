import '../core/nutrition.dart';

double asDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return 0;
}

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.kjPer100g,
    required this.carbPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.updatedAt,
    this.imageBase64,
  });

  final String id;
  final String name;
  final double kjPer100g;
  final double carbPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final int updatedAt;
  final String? imageBase64;

  double get kcalPer100g => kcalFromKj(kjPer100g);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'kjPer100g': kjPer100g,
      'carbPer100g': carbPer100g,
      'proteinPer100g': proteinPer100g,
      'fatPer100g': fatPer100g,
      'updatedAt': updatedAt,
      if (imageBase64 != null && imageBase64!.isNotEmpty)
        'imageBase64': imageBase64,
    };
  }

  factory Food.fromMap(Map<String, Object?> map) {
    final image = map['imageBase64'];
    return Food(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      kjPer100g: asDouble(map['kjPer100g']),
      carbPer100g: asDouble(map['carbPer100g']),
      proteinPer100g: asDouble(map['proteinPer100g']),
      fatPer100g: asDouble(map['fatPer100g']),
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
      imageBase64: image is String && image.isNotEmpty ? image : null,
    );
  }
}
