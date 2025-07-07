import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class UserDataHelper {
  static final UserDataHelper _instance = UserDataHelper._internal();
  factory UserDataHelper() => _instance;
  UserDataHelper._internal();
  static const String _tableName = 'user_data';

  static Database? _db;

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

  Future _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE user_data(
id INTEGER PRIMARY KEY AUTOINCREMENT,
account TEXT NOT NULL,
nickname TEXT NOT NULL,
avatar TEXT NOT NULL,
register_date TEXT NOT NULL,
gender TEXT NOT NULL
)
''');
  }

  // 插入用户信息
  Future<int> insertUser(User user) async {
    final dbClient = await db;
    return await dbClient.insert(_tableName, user.toMap());
  }

  // 查询用户信息（通过 account）
  Future<Map<String, dynamic>?> getUser(String account) async {
    final dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query(
      _tableName,
      where: 'account = ?',
      whereArgs: [account],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // 查询所有用户
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final dbClient = await db;
    return await dbClient.query(_tableName);
  }

  // 更新用户信息
  Future<int> updateUser(User user) async {
    final dbClient = await db;
    return await dbClient.update(
      _tableName,
      user.toMap(),
      where: 'account = ?',
      whereArgs: [user.account],
    );
  }

  // 删除用户信息
  Future<int> deleteUser(String account) async {
    final dbClient = await db;
    return await dbClient.delete(
      _tableName,
      where: 'account = ?',
      whereArgs: [account],
    );
  }

  // 判断用户是否存在
  Future<bool> userExists(String account) async {
    final dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query(
      _tableName,
      where: 'account = ?',
      whereArgs: [account],
    );
    return result.isNotEmpty;
  }
}

class User {
  final String account;
  final String nickname;
  final String avatar;
  final DateTime registerDate;
  final String gender;
  User({
    required this.account,
    required this.nickname,
    required this.avatar,
    required this.registerDate,
    required this.gender,
  });

  Map<String, dynamic> toMap() {
    return {
      'account': account,
      'nickname': nickname,
      'avatar': avatar,
      'register_date': registerDate.toIso8601String(),
      'gender': gender,
    };
  }
}
