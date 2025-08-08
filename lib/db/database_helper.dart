// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<void> resetDatabaseInstance() async {
    _database = null;
  }

  Future<Database> get database async {
    return _database ??= await _initDB('health_habit_tracker.db');
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 3, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // --- 已修改：在所有 CREATE TABLE 语句中加入 IF NOT EXISTS ---
    
    // 创建记录表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime TEXT NOT NULL,
        duration INTEGER NOT NULL,
        didResist INTEGER NOT NULL,
        preEventState INTEGER NOT NULL,
        postEventFeeling INTEGER NOT NULL,
        physicalFatigue INTEGER NOT NULL,
        eventType TEXT NOT NULL,
        reasons TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // 创建事件类型表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        sortOrder INTEGER NOT NULL
      )
    ''');
    
    // 创建原因表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reasons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        sortOrder INTEGER NOT NULL
      )
    ''');
    
    // 检查表是否为空，如果为空才插入默认数据
    var eventTypesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM event_types'));
    if (eventTypesCount == 0) {
        await _insertDefaultOptions(db);
    }
  }
  
  // 插入默认选项的方法
  static Future<void> _insertDefaultOptions(Database db) async {
      final batch = db.batch();
      const List<String> defaultEventTypes = ['独处时', '伴侣在旁', '浏览内容后', '睡前', '晨起', '其他'];
      const List<String> defaultReasons = ['压力', '无聊', '习惯', '情绪低落', '兴奋', '孤独', '焦虑', '失眠', '好奇', '其他'];

      for (int i = 0; i < defaultEventTypes.length; i++) {
          batch.insert('event_types', {'name': defaultEventTypes[i], 'sortOrder': i});
      }
      for (int i = 0; i < defaultReasons.length; i++) {
          batch.insert('reasons', {'name': defaultReasons[i], 'sortOrder': i});
      }
      await batch.commit(noResult: true);
  }

  // --- 选项管理方法 ---

  Future<List<String>> getOptions(String tableName) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName, orderBy: 'sortOrder ASC');
    return List.generate(maps.length, (i) => maps[i]['name'] as String);
  }

  Future<void> updateOptions(String tableName, List<String> options) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete(tableName); // 清空旧数据
      final batch = txn.batch();
      for (int i = 0; i < options.length; i++) {
        batch.insert(tableName, {'name': options[i], 'sortOrder': i});
      }
      await batch.commit(noResult: true);
    });
  }
  
  Future<void> addOption(String tableName, String option) async {
      final db = await instance.database;
      final options = await getOptions(tableName);
      if (option.trim().isEmpty || options.contains(option)) return;
      
      final otherIndex = options.indexOf('其他');
      int sortOrder = options.length;
      if (otherIndex != -1) {
          sortOrder = otherIndex;
          // 更新“其他”以及之后所有项的排序
          for (int i = otherIndex; i < options.length; i++) {
              await db.update(tableName, {'sortOrder': i + 1}, where: 'name = ?', whereArgs: [options[i]]);
          }
      }
      await db.insert(tableName, {'name': option, 'sortOrder': sortOrder}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  
  Future<void> resetDefaultOptions(String tableName) async {
    final db = await instance.database;
    await db.delete(tableName); // 清空
    if (tableName == 'event_types') {
        const List<String> defaultEventTypes = ['独处时', '伴侣在旁', '浏览内容后', '睡前', '晨起', '其他'];
        for (int i = 0; i < defaultEventTypes.length; i++) {
          await db.insert('event_types', {'name': defaultEventTypes[i], 'sortOrder': i});
        }
    } else if (tableName == 'reasons') {
        const List<String> defaultReasons = ['压力', '无聊', '习惯', '情绪低落', '兴奋', '孤独', '焦虑', '失眠', '好奇', '其他'];
        for (int i = 0; i < defaultReasons.length; i++) {
          await db.insert('reasons', {'name': defaultReasons[i], 'sortOrder': i});
        }
    }
  }


  // --- 记录管理方法 ---
  Future<int> insertRecord(Record record) async {
    final db = await instance.database;
    return await db.insert('records', record.toMap());
  }

  Future<List<Record>> getAllRecords() async {
    final db = await instance.database;
    final result = await db.query('records', orderBy: 'startTime DESC');
    return result.map((map) => Record.fromMap(map)).toList();
  }
  
  Future<List<Record>> getAllRecordsAsc() async {
    final db = await instance.database;
    final result = await db.query('records', orderBy: 'startTime ASC');
    return result.map((map) => Record.fromMap(map)).toList();
  }

  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete('records');
  }

  Future close() async {
    final db = DatabaseHelper._database;
    db?.close();
  }
}