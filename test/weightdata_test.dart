import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pet_fat_weight/models/weightdata.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late WeightDataHelper weightDataHelper;
  late Database testDb;

  setUp(() async {
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE weight_data(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pet_id INTEGER NOT NULL,
  weight REAL NOT NULL,
  date TEXT NOT NULL
)
''');
      },
    );
    WeightDataHelper.setDbForTest(testDb);
    weightDataHelper = WeightDataHelper();
  });

  tearDown(() async {
    await testDb.close();
  });

  test('插入体重记录', () async {
    final weight = Weight(petId: 1, weight: 5.5, date: DateTime(2024, 6, 1));
    await weightDataHelper.insertWeight(weight);
    final weights = await weightDataHelper.getWeights(1);
    expect(weights.length, 1);
    expect(weights.first.weight, 5.5);
    expect(weights.first.date, DateTime(2024, 6, 1));
  });

  test('更新体重记录', () async {
    final weight = Weight(petId: 2, weight: 3.2, date: DateTime(2024, 6, 2));
    await weightDataHelper.insertWeight(weight);
    final updated = Weight(petId: 2, weight: 4.0, date: DateTime(2024, 6, 3));
    await weightDataHelper.updateWeight(updated);
    final weights = await weightDataHelper.getWeights(2);
    expect(weights.length, 1);
    expect(weights.first.weight, 4.0);
    expect(weights.first.date, DateTime(2024, 6, 3));
  });

  test('删除体重记录', () async {
    final weight = Weight(petId: 3, weight: 2.5, date: DateTime(2024, 6, 4));
    await weightDataHelper.insertWeight(weight);
    await weightDataHelper.deletePetWeight(3);
    final weights = await weightDataHelper.getWeights(3);
    expect(weights.isEmpty, true);
  });

  test('获取多条体重记录', () async {
    final w1 = Weight(petId: 4, weight: 1.1, date: DateTime(2024, 6, 5));
    final w2 = Weight(petId: 4, weight: 1.2, date: DateTime(2024, 6, 6));
    await weightDataHelper.insertWeight(w1);
    await weightDataHelper.insertWeight(w2);
    final weights = await weightDataHelper.getWeights(4);
    expect(weights.length, 2);
    expect(weights[0].weight, 1.1);
    expect(weights[1].weight, 1.2);
  });
}
