import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // 新增：公开方法用于重置数据库实例
  Future<void> resetDatabaseInstance() async {
    _database = null;
  }

  Future<Database> get database async {
    return _database ??= await _initDB('records.db');
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime TEXT NOT NULL,
        duration INTEGER NOT NULL,
        didResist INTEGER NOT NULL,
        feeling INTEGER NOT NULL,
        comfort INTEGER NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<int> insertRecord(Record record) async {
    final db = await instance.database;
    return await db.insert('records', record.toMap());
  }

  Future<List<Record>> getAllRecords() async {
    final db = await instance.database;
    final result = await db.query('records', orderBy: 'startTime DESC');
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
