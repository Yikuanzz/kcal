import 'package:flutter/material.dart';
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

IntakeEntry _entry() => IntakeEntry(
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
    );

Future<void> _pump(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const KcalApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('点开记录改克数，汇总随之更新', (tester) async {
    final db = await tester.runAsync(() => _database('edit-grams'));
    await db!.addIntake(_entry());
    await _pump(tester, db);
    expect(tester.takeException(), isNull);
    expect(find.text('米饭'), findsOneWidget);

    await tester.ensureVisible(find.text('米饭'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('米饭'));
    await tester.pumpAndSettle();
    expect(find.text('保存修改'), findsOneWidget);
    expect(find.text('换一份'), findsOneWidget);
    expect(find.text('记错了，删掉这一笔'), findsOneWidget);

    final gramsField = find.byType(TextField);
    expect(gramsField, findsOneWidget);
    await tester.enterText(gramsField, '1000');
    await tester.pump();
    expect(find.text('这一份约 1250 kcal'), findsOneWidget);

    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();

    expect(find.text('1250 / 2000 kcal'), findsOneWidget);
    expect(find.textContaining('1000 g'), findsOneWidget);
  });

  testWidgets('左滑撤下后可以撤销', (tester) async {
    final db = await tester.runAsync(() => _database('undo-swipe'));
    await db!.addIntake(_entry());
    await _pump(tester, db);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('米饭'));
    await tester.pumpAndSettle();
    final tile = find.byType(Dismissible);
    final gesture = await tester.startGesture(tester.getCenter(tile));
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-320, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(); // 结算手势，开始滑出动画
    await tester.pump(const Duration(milliseconds: 250)); // 滑出完成，开始收起
    await tester.pump(const Duration(milliseconds: 350)); // 收起完成，触发撤下
    await tester.pump(const Duration(milliseconds: 50)); // 列表按空数据重建

    expect(find.text('这一日还未记过食物'), findsOneWidget);
    expect(find.textContaining('已撤下'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300)); // 提示浮升到位
    await tester.tap(find.text('撤销'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('米饭'), findsOneWidget);
    expect(find.text('2500 / 2000 kcal'), findsOneWidget);

    // 让撤销提示自行消失，避免测试结束时残留计时器
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
