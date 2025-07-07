import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class WeightDataHelper {
  static final WeightDataHelper _instance = WeightDataHelper._internal();
  factory WeightDataHelper() => _instance;
  WeightDataHelper._internal();
  static const String _tableName = 'weight_data';

  static Database? _db;

  /// 仅用于测试环境，允许注入自定义数据库实例
  static void setDbForTest(Database db) {
    _db = db;
  }

  Future<Database> _initDb() async {
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentDirectory.path}/$_tableName';
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE weight_data(
id INTEGER PRIMARY KEY AUTOINCREMENT,
pet_id INTEGER NOT NULL,
weight REAL NOT NULL,
date TEXT NOT NULL,
FOREIGN KEY (pet_id) REFERENCES pets(id),
)
''');
  }

  Future<void> insertWeight(Weight weight) async {
    final db = await this.db;
    await db.insert(_tableName, weight.toMap());
  }

  Future<void> updateWeight(Weight weight) async {
    final db = await this.db;
    await db.update(
      _tableName,
      weight.toMap(),
      where: 'pet_id = ?',
      whereArgs: [weight.petId],
    );
  }

  Future<void> deletePetWeight(int petId) async {
    final db = await this.db;
    await db.delete(_tableName, where: 'pet_id = ?', whereArgs: [petId]);
  }

  Future<List<Weight>> getWeights(int petId) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'pet_id = ?',
      whereArgs: [petId],
    );
    return List.generate(maps.length, (i) {
      return Weight.fromMap(maps[i]);
    });
  }
}

class Weight {
  final int petId;
  final double weight;
  final DateTime date;

  Weight({required this.petId, required this.weight, required this.date});

  Map<String, dynamic> toMap() {
    return {'pet_id': petId, 'weight': weight, 'date': date.toIso8601String()};
  }

  factory Weight.fromMap(Map<String, dynamic> map) {
    return Weight(
      petId: map['pet_id'],
      weight: map['weight'],
      date: DateTime.parse(map['date']),
    );
  }
}
