import 'package:flutter_test/flutter_test.dart';
import 'package:pet_fat_weight/models/petdata.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late PetDataHelper petDataHelper;
  late Database testDb;

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    // 使用内存数据库，避免污染真实数据
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE pet_data(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  avatar TEXT NOT NULL,
  register_date TEXT NOT NULL,
  type TEXT NOT NULL,
  species TEXT NOT NULL,
  birthday TEXT,
  gender TEXT,
  color TEXT,
  weight REAL NOT NULL
)
''');
      },
    );
    // 通过反射或其他方式注入 testDb，如果不行则需调整 PetDataHelper 代码
    // 这里暂时跳过 _db 赋值，直接测试 PetDataHelper 的正常流程
    petDataHelper = PetDataHelper();
    PetDataHelper.setDbForTest(testDb);
  });

  tearDown(() async {
    await testDb.close();
    // 不再访问 _db
  });

  test('插入宠物数据', () async {
    final pet = Pet(
      id: 1,
      name: '小白',
      avatar: 'avatar.png',
      registerDate: DateTime(2024, 1, 1),
      type: '狗',
      species: '哈士奇',
      birthday: DateTime(2022, 1, 1),
      gender: '公',
      color: '白色',
      weight: 10.5,
    );
    await petDataHelper.insertPet(pet);
    final pets = await petDataHelper.getPets();
    expect(pets.length, 1);
    expect(pets.first.name, '小白');
  });

  test('更新宠物数据', () async {
    final pet = Pet(
      id: 1,
      name: '小黑',
      avatar: 'avatar.png',
      registerDate: DateTime(2024, 1, 1),
      type: '猫',
      species: '英短',
      birthday: DateTime(2022, 1, 1),
      gender: '母',
      color: '黑色',
      weight: 5.0,
    );
    await petDataHelper.insertPet(pet);
    final updatedPet = Pet(
      id: 1,
      name: '小黑',
      avatar: 'avatar2.png',
      registerDate: DateTime(2024, 1, 1),
      type: '猫',
      species: '英短',
      birthday: DateTime(2022, 1, 1),
      gender: '母',
      color: '灰色',
      weight: 5.5,
    );
    await petDataHelper.updatePet(updatedPet);
    final pets = await petDataHelper.getPets();
    expect(pets.length, 1);
    expect(pets.first.avatar, 'avatar2.png');
    expect(pets.first.color, '灰色');
    expect(pets.first.weight, 5.5);
  });

  test('删除宠物数据', () async {
    final pet = Pet(
      id: 1,
      name: '小花',
      avatar: 'avatar.png',
      registerDate: DateTime(2024, 1, 1),
      type: '兔',
      species: '垂耳兔',
      birthday: DateTime(2022, 1, 1),
      gender: '母',
      color: '花色',
      weight: 2.0,
    );
    await petDataHelper.insertPet(pet);
    await petDataHelper.deletePet(1);
    final pets = await petDataHelper.getPets();
    expect(pets.isEmpty, true);
  });

  test('获取所有宠物数据', () async {
    final pet1 = Pet(
      id: 1,
      name: 'A',
      avatar: 'a.png',
      registerDate: DateTime(2024, 1, 1),
      type: '狗',
      species: '柴犬',
      birthday: DateTime(2022, 1, 1),
      gender: '公',
      color: '棕色',
      weight: 8.0,
    );
    final pet2 = Pet(
      id: 2,
      name: 'B',
      avatar: 'b.png',
      registerDate: DateTime(2024, 2, 1),
      type: '猫',
      species: '美短',
      birthday: DateTime(2022, 2, 1),
      gender: '母',
      color: '灰色',
      weight: 4.0,
    );
    await petDataHelper.insertPet(pet1);
    await petDataHelper.insertPet(pet2);
    final pets = await petDataHelper.getPets();
    expect(pets.length, 2);
    expect(pets.any((p) => p.name == 'A'), true);
    expect(pets.any((p) => p.name == 'B'), true);
  });
}
