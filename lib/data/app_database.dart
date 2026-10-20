import 'package:sembast/sembast.dart';

import '../models/daily_target.dart';
import '../models/food.dart';
import '../models/intake_entry.dart';
import 'db_opener.dart';
import 'sample_foods.dart';

class AppDatabase {
  AppDatabase();

  AppDatabase.forTest(Database database) : _db = database;

  final _foods = stringMapStoreFactory.store('foods');
  final _intakes = stringMapStoreFactory.store('intakes');
  final _meta = stringMapStoreFactory.store('meta');

  Database? _db;
  bool _ready = false;

  Database get _database {
    final current = _db;
    if (current == null) {
      throw StateError('数据库尚未打开');
    }
    return current;
  }

  Future<void> init({bool seed = true}) async {
    if (_ready) return;
    _db ??= await openAppDatabase();
    if (seed) {
      await _ensureTarget();
      await _seedFoodsIfEmpty();
    }
    _ready = true;
  }

  Future<List<Food>> getFoods() async {
    final records = await _foods.find(
      _database,
      finder: Finder(sortOrders: [SortOrder('updatedAt', false)]),
    );
    return records.map((record) => Food.fromMap(record.value)).toList();
  }

  Future<void> upsertFood(Food food) {
    return _foods.record(food.id).put(_database, food.toMap());
  }

  Future<void> deleteFood(String id) {
    return _foods.record(id).delete(_database);
  }

  Future<DailyTarget> getTarget() async {
    final map = await _meta.record('target').get(_database);
    if (map == null) return DailyTarget.standard;
    return DailyTarget.fromMap(map);
  }

  Future<void> saveTarget(DailyTarget target) {
    return _meta.record('target').put(_database, target.toMap());
  }

  Future<List<IntakeEntry>> getIntakes(String day) async {
    final records = await _intakes.find(
      _database,
      finder: Finder(
        filter: Filter.equals('day', day),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    );
    return records.map((record) => IntakeEntry.fromMap(record.value)).toList();
  }

  Future<void> addIntake(IntakeEntry entry) {
    return _intakes.record(entry.id).put(_database, entry.toMap());
  }

  Future<void> deleteIntake(String id) {
    return _intakes.record(id).delete(_database);
  }

  Future<void> _ensureTarget() async {
    final existing = await _meta.record('target').get(_database);
    if (existing != null) return;
    await saveTarget(DailyTarget.standard);
  }

  Future<void> _seedFoodsIfEmpty() async {
    final count = await _foods.count(_database);
    if (count > 0) return;
    final samples = sampleFoods(DateTime.now().millisecondsSinceEpoch);
    await _database.transaction((txn) async {
      for (final food in samples) {
        await _foods.record(food.id).put(txn, food.toMap());
      }
    });
  }
}
