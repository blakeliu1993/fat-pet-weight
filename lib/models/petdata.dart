import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PetDataHelper {
  static final PetDataHelper _instance = PetDataHelper._internal();
  factory PetDataHelper() => _instance;
  PetDataHelper._internal();

  static const String _tableName = 'pet_data';

  static Database? _db;

  /// 仅用于测试环境，允许注入自定义数据库实例
  static void setDbForTest(Database db) {
    _db = db;
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentDirectory.path}/$_tableName';
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // 表的内容包含：
  // 1. 宠物ID
  // 2. 宠物名称
  // 3. 宠物头像
  // 4. 宠物注册日期
  // 5. 宠物类型
  // 6. 宠物种类
  // 7. 宠物生日
  // 8. 宠物性别
  // 9. 宠物颜色
  // 10. 宠物体重
  Future _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE pet_data(
id INTEGER PRIMARY KEY AUTOINCREMENT,
name TEXT NOT NULL,
avatar TEXT NOT NULL,
register_date DATETIME NOT NULL,
type TEXT NOT NULL,
species TEXT NOT NULL,
birthday DATETIME NOT NULL,
gender TEXT,
color TEXT,
weight REAL NOT NULL,
)
''');
  }

  Future<void> insertPet(Pet pet) async {
    final db = await this.db;
    await db.insert(_tableName, pet.toMap());
  }

  Future<void> updatePet(Pet pet) async {
    final db = await this.db;
    await db.update(
      _tableName,
      pet.toMap(),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
  }

  Future<void> deletePet(int id) async {
    final db = await this.db;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Pet>> getPets() async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) {
      return Pet.fromMap(maps[i]);
    });
  }
}

// 宠物类
class Pet {
  final String name;
  final String avatar;
  final DateTime registerDate;
  final String type;
  final String species;
  final DateTime birthday;
  final String gender;
  final String color;
  final double weight;
  final int id;

  Pet({
    required this.id,
    required this.name,
    required this.avatar,
    required this.registerDate,
    required this.type,
    required this.species,
    required this.birthday,
    required this.gender,
    required this.color,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'register_date': registerDate.toIso8601String(),
      'type': type,
      'species': species,
      'birthday': birthday.toIso8601String(),
      'gender': gender,
      'color': color,
      'weight': weight,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      name: map['name'],
      avatar: map['avatar'],
      registerDate: DateTime.parse(map['register_date']),
      type: map['type'],
      species: map['species'],
      birthday: DateTime.parse(map['birthday']),
      gender: map['gender'],
      color: map['color'],
      weight: map['weight'],
    );
  }
}
