import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/nutrition.dart';
import '../data/app_database.dart';
import '../models/daily_target.dart';
import '../models/food.dart';
import '../models/intake_entry.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('数据库尚未就绪');
});

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(
  SelectedDay.new,
);

class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void shift(int days) {
    final today = dateOnly(DateTime.now());
    final next = dateOnly(state.add(Duration(days: days)));
    if (next.isAfter(today)) return;
    state = next;
  }

  void jumpToToday() => state = dateOnly(DateTime.now());
}

final foodsProvider = AsyncNotifierProvider<FoodsNotifier, List<Food>>(
  FoodsNotifier.new,
);

class FoodsNotifier extends AsyncNotifier<List<Food>> {
  @override
  Future<List<Food>> build() => ref.read(databaseProvider).getFoods();

  Future<void> save(Food food) async {
    final database = ref.read(databaseProvider);
    await database.upsertFood(food);
    state = AsyncData(await database.getFoods());
  }

  Future<void> remove(String id) async {
    final database = ref.read(databaseProvider);
    await database.deleteFood(id);
    state = AsyncData(await database.getFoods());
  }
}

final targetProvider = AsyncNotifierProvider<TargetNotifier, DailyTarget>(
  TargetNotifier.new,
);

class TargetNotifier extends AsyncNotifier<DailyTarget> {
  @override
  Future<DailyTarget> build() => ref.read(databaseProvider).getTarget();

  Future<void> save(DailyTarget target) async {
    final database = ref.read(databaseProvider);
    await database.saveTarget(target);
    state = AsyncData(await database.getTarget());
  }
}

final intakesProvider =
    AsyncNotifierProvider<IntakesNotifier, List<IntakeEntry>>(
      IntakesNotifier.new,
    );

class IntakesNotifier extends AsyncNotifier<List<IntakeEntry>> {
  @override
  Future<List<IntakeEntry>> build() {
    final day = ref.watch(selectedDayProvider);
    return ref.read(databaseProvider).getIntakes(dayKey(day));
  }

  Future<void> add(IntakeEntry entry) async {
    final database = ref.read(databaseProvider);
    await database.addIntake(entry);
    state = AsyncData(await _load(database));
  }

  Future<void> remove(String id) async {
    final database = ref.read(databaseProvider);
    await database.deleteIntake(id);
    state = AsyncData(await _load(database));
  }

  Future<List<IntakeEntry>> _load(AppDatabase database) {
    final day = ref.read(selectedDayProvider);
    return database.getIntakes(dayKey(day));
  }
}
