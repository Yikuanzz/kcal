// Screenshot harness for the README. Runs only with --dart-define=screenshots=true:
//   flutter test test/screenshots_test.dart --dart-define=screenshots=true
// Renders real screens with a seeded in-memory database and writes
// PNGs into screenshots/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kcal/core/nutrition.dart';
import 'package:kcal/core/theme.dart';
import 'package:kcal/data/app_database.dart';
import 'package:kcal/features/foods/foods_screen.dart';
import 'package:kcal/features/intake/add_intake_screen.dart';
import 'package:kcal/features/targets/targets_screen.dart';
import 'package:kcal/features/today/today_screen.dart';
import 'package:kcal/models/intake_entry.dart';
import 'package:kcal/providers/providers.dart';
import 'package:kcal/shared/widgets/food_pick_tile.dart';
import 'package:sembast/sembast_memory.dart';

const _enabled = bool.fromEnvironment('screenshots');

bool _fontsLoaded = false;

Future<void> _ensureFonts() async {
  if (_fontsLoaded) return;
  final sdkRoot = Platform.environment['FLUTTER_ROOT'] ?? 'D:/sdk/flutter';
  final icons = File(
    '$sdkRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytesSync();
  final iconLoader = FontLoader('MaterialIcons');
  iconLoader.addFont(Future.value(ByteData.view(icons.buffer)));
  await iconLoader.load();

  // 主题 fontFamilyFallback 链上的每个 family 名都注册真实字体，
  // 保证任何一环都能命中（否则测试环境会落到 Ahem 方块）。
  const families = [
    'Microsoft YaHei',
    'PingFang SC',
    'Noto Sans SC',
    'Source Han Sans SC',
    'Segoe UI',
    'Roboto',
    'SimHei',
  ];
  final candidates = [
    'C:/Windows/Fonts/msyh.ttc',
    'C:/Windows/Fonts/msyhbd.ttc',
    'C:/Windows/Fonts/simhei.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    try {
      final bytes = file.readAsBytesSync();
      for (final family in families) {
        final loader = FontLoader(family);
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
        await loader.load();
      }
    } catch (_) {
      // 单个字体失败不阻塞其余候选
    }
  }
  _fontsLoaded = true;
}

Future<AppDatabase> _database(String name) async {
  final db = AppDatabase.forTest(
    await databaseFactoryMemory.openDatabase(name),
  );
  await db.init();
  return db;
}

IntakeEntry _entry(
  String id,
  String foodId,
  String name,
  double grams,
  double kj,
  double carb,
  double protein,
  double fat,
  int createdAt,
) {
  final m = scaleFood(
    grams: grams,
    kjPer100g: kj,
    carbPer100g: carb,
    proteinPer100g: protein,
    fatPer100g: fat,
  );
  return IntakeEntry(
    id: id,
    day: dayKey(DateTime.now()),
    foodId: foodId,
    foodName: name,
    grams: grams,
    kcal: m.kcal,
    carb: m.carb,
    protein: m.protein,
    fat: m.fat,
    createdAt: createdAt,
  );
}

Future<void> _pump(
  WidgetTester tester,
  AppDatabase db,
  Widget screen,
  GlobalKey key,
) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: kcalTheme(),
          home: screen,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('screenshots').createSync(recursive: true);
    File('screenshots/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  });
}

Future<void> _seedFullDay(AppDatabase? db) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  await db!.addIntake(
    _entry('a1', 'sample-rice', '米饭', 600, 485, 25.9, 2.6, 0.3, now),
  );
  await db.addIntake(
    _entry('a2', 'sample-chicken', '鸡胸肉', 400, 690, 0, 31, 3.6, now - 1),
  );
  await db.addIntake(
    _entry('a3', 'sample-egg', '鸡蛋', 200, 602, 2.8, 13.3, 8.8, now - 2),
  );
  await db.addIntake(
    _entry('a4', 'sample-milk', '牛奶', 500, 268, 4.8, 3.2, 3.6, now - 3),
  );
  await db.addIntake(
    _entry('a5', 'sample-broccoli', '西兰花', 250, 142, 6.6, 2.8, 0.4, now - 4),
  );
}

void main() {
  testWidgets('今日页', (tester) async {
    await tester.runAsync(() async {
      await _ensureFonts();
    });
    final db = await tester.runAsync(() => _database('shots-today'));
    await tester.runAsync(() => _seedFullDay(db));
    final key = GlobalKey();
    await _pump(tester, db!, const TodayScreen(), key);
    await _shot(tester, key, 'today');
  }, skip: !_enabled);

  testWidgets('记一笔', (tester) async {
    await tester.runAsync(() async {
      await _ensureFonts();
    });
    final db = await tester.runAsync(() => _database('shots-add'));
    final key = GlobalKey();
    await _pump(tester, db!, const AddIntakeScreen(), key);
    await tester.tap(find.widgetWithText(FoodPickTile, '米饭'));
    await tester.pump();
    await _shot(tester, key, 'add-intake');
  }, skip: !_enabled);

  testWidgets('食物库', (tester) async {
    await tester.runAsync(() async {
      await _ensureFonts();
    });
    final db = await tester.runAsync(() => _database('shots-foods'));
    final key = GlobalKey();
    await _pump(tester, db!, const FoodsScreen(), key);
    await _shot(tester, key, 'foods');
  }, skip: !_enabled);

  testWidgets('指标', (tester) async {
    await tester.runAsync(() async {
      await _ensureFonts();
    });
    final db = await tester.runAsync(() => _database('shots-targets'));
    final key = GlobalKey();
    await _pump(tester, db!, const TargetsScreen(), key);
    await _shot(tester, key, 'targets');
  }, skip: !_enabled);

  testWidgets('编辑记录', (tester) async {
    await tester.runAsync(() async {
      await _ensureFonts();
    });
    final db = await tester.runAsync(() => _database('shots-edit'));
    await tester.runAsync(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db!.addIntake(
        _entry('b1', 'sample-rice', '米饭', 300, 485, 25.9, 2.6, 0.3, now),
      );
    });
    final key = GlobalKey();
    await _pump(tester, db!, const TodayScreen(), key);
    await tester.ensureVisible(find.text('米饭'));
    await tester.tap(find.text('米饭'));
    await tester.pumpAndSettle();
    await _shot(tester, key, 'edit-entry');
  }, skip: !_enabled);
}
