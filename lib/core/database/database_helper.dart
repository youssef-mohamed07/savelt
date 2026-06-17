import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _db;
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), "saveit_app.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT,
            date TEXT NOT NULL,
            description TEXT,
            isSynced INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        """);
      },
    );
  }

  Future<int> addExpense(Map<String, dynamic> expense) async {
    var database = await db;
    return await database.insert("expenses", expense);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    var database = await db;
    return await database.query("expenses", orderBy: "date DESC");
  }

  Future<int> deleteExpense(int id) async {
    var database = await db;
    return await database.delete("expenses", where: "id = ?", whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    var database = await db;
    await database.delete("expenses");
  }

  // جلب المصاريف غير المتزامنة
  Future<List<Map<String, dynamic>>> getUnsyncedExpenses() async {
    var database = await db;
    return await database.query(
      "expenses",
      where: "isSynced = ?",
      whereArgs: [0],
    );
  }

  // تعليم مصروف كمتزامن
  Future<int> markExpenseAsSynced(int id) async {
    var database = await db;
    return await database.update(
      "expenses",
      {"isSynced": 1},
      where: "id = ?",
      whereArgs: [id],
    );
  }
}



