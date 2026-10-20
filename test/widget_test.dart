import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal/app.dart';
import 'package:kcal/core/nutrition.dart';
import 'package:kcal/data/app_database.dart';
import 'package:kcal/models/intake_entry.dart';
import 'package:kcal/providers/providers.dart';
import 'package:sembast/sembast_memory.dart';

Future<AppDatabase> _database(String name) async {
  final db = AppDatabase.forTest(
    await databaseFactoryMemory.openDatabase(name),
  );
  await db.init();
  return db;
}

void main() {
  testWidgets('空的一日对照默认指标', (tester) async {
    final db = await tester.runAsync(() => _database('widget-empty'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db!)],
        child: const KcalApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('今日'), findsWidgets);
    expect(find.text('0 / 2000 kcal'), findsOneWidget);
    expect(find.text('这一日还未记过食物'), findsOneWidget);
    expect(find.textContaining('已超出'), findsNothing);
  });

  testWidgets('热量超过指标时标明超出', (tester) async {
    final db = await tester.runAsync(() async {
      final database = await _database('widget-over');
      await database.addIntake(
        IntakeEntry(
          id: 'big',
          day: dayKey(DateTime.now()),
          foodId: 'sample-rice',
          foodName: '米饭',
          grams: 2000,
          kcal: 2500,
          carb: 40,
          protein: 20,
          fat: 8,
          createdAt: 1,
        ),
      );
      return database;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db!)],
        child: const KcalApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('今日已超出：热量'), findsOneWidget);
    expect(find.text('2500 / 2000 kcal'), findsOneWidget);
    expect(find.text('米饭'), findsOneWidget);
  });
}
