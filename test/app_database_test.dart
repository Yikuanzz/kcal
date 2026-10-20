import 'package:flutter_test/flutter_test.dart';
import 'package:kcal/core/nutrition.dart';
import 'package:kcal/data/app_database.dart';
import 'package:kcal/models/daily_target.dart';
import 'package:kcal/models/food.dart';
import 'package:kcal/models/intake_entry.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  Future<AppDatabase> open() async {
    final db = AppDatabase.forTest(
      await databaseFactoryMemory.openDatabase(
        'kcal-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await db.init();
    return db;
  }

  test('首次打开写入示例食物和默认指标', () async {
    final db = await open();
    final foods = await db.getFoods();
    expect(foods.map((food) => food.name), containsAll(['米饭', '鸡蛋', '鸡胸肉']));
    final target = await db.getTarget();
    expect(target.kcal, 2000);
    expect(target.carb, 250);
    expect(target.protein, 90);
    expect(target.fat, 60);
  });

  test('摄入按当时营养做快照，事后改食物不改旧账', () async {
    final db = await open();
    final rice = (await db.getFoods()).firstWhere((food) => food.id == 'sample-rice');
    final scaled = scaleFood(
      grams: 200,
      kjPer100g: rice.kjPer100g,
      carbPer100g: rice.carbPer100g,
      proteinPer100g: rice.proteinPer100g,
      fatPer100g: rice.fatPer100g,
    );
    await db.addIntake(
      IntakeEntry(
        id: 'bowl',
        day: '2026-10-20',
        foodId: rice.id,
        foodName: rice.name,
        grams: 200,
        kcal: scaled.kcal,
        carb: scaled.carb,
        protein: scaled.protein,
        fat: scaled.fat,
        createdAt: 1,
      ),
    );
    await db.upsertFood(
      Food(
        id: rice.id,
        name: '米饭',
        kjPer100g: 1000,
        carbPer100g: 50,
        proteinPer100g: 9,
        fatPer100g: 2,
        updatedAt: 2,
      ),
    );

    final day = await db.getIntakes('2026-10-20');
    expect(day.single.kcal, closeTo(scaled.kcal, 0.001));
    expect(day.single.carb, closeTo(51.8, 0.001));
    expect(summarize(day).kcal, closeTo(scaled.kcal, 0.001));

    await db.deleteIntake('bowl');
    expect(await db.getIntakes('2026-10-20'), isEmpty);
  });

  test('可以改掉每日指标', () async {
    final db = await open();
    await db.saveTarget(
      const DailyTarget(kcal: 1800, carb: 180, protein: 120, fat: 50),
    );
    final target = await db.getTarget();
    expect(target.kcal, 1800);
    expect(target.protein, 120);
  });
}
