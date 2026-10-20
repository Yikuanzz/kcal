import '../models/food.dart';

/// 常见食物的每 100 克参考值，取自公开食物成分的大致区间，可改可删。
List<Food> sampleFoods(int now) {
  return [
    Food(
      id: 'sample-rice',
      name: '米饭',
      kjPer100g: 485,
      carbPer100g: 25.9,
      proteinPer100g: 2.6,
      fatPer100g: 0.3,
      updatedAt: now,
    ),
    Food(
      id: 'sample-egg',
      name: '鸡蛋',
      kjPer100g: 602,
      carbPer100g: 2.8,
      proteinPer100g: 13.3,
      fatPer100g: 8.8,
      updatedAt: now - 1,
    ),
    Food(
      id: 'sample-chicken',
      name: '鸡胸肉',
      kjPer100g: 690,
      carbPer100g: 0,
      proteinPer100g: 31,
      fatPer100g: 3.6,
      updatedAt: now - 2,
    ),
    Food(
      id: 'sample-broccoli',
      name: '西兰花',
      kjPer100g: 142,
      carbPer100g: 6.6,
      proteinPer100g: 2.8,
      fatPer100g: 0.4,
      updatedAt: now - 3,
    ),
    Food(
      id: 'sample-milk',
      name: '牛奶',
      kjPer100g: 268,
      carbPer100g: 4.8,
      proteinPer100g: 3.2,
      fatPer100g: 3.6,
      updatedAt: now - 4,
    ),
  ];
}
