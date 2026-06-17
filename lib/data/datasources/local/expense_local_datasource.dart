import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/expense_model.dart';

/// Local data source for expense operations using SQLite
class ExpenseLocalDataSource {
  static Database? _database;
  static final ExpenseLocalDataSource instance =
      ExpenseLocalDataSource._internal();

  ExpenseLocalDataSource._internal();
  factory ExpenseLocalDataSource() => instance;

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), AppConstants.databaseName);
    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
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
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute(
      'CREATE INDEX idx_expenses_category ON expenses(category)',
    );
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
    if (oldVersion < 2) {
      // Migration for version 2
    }
  }

  /// Insert expense
  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap());
  }

  /// Get all expenses
  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  /// Get expenses by date range
  Future<List<ExpenseModel>> getExpensesByDateRange(
    String fromDate,
    String toDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [fromDate, toDate],
      orderBy: 'date DESC',
    );
    return result.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  /// Get expenses by category
  Future<List<ExpenseModel>> getExpensesByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return result.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  /// Get unsynced expenses
  Future<List<ExpenseModel>> getUnsyncedExpenses() async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return result.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  /// Update expense
  Future<int> updateExpense(ExpenseModel expense) async {
    final db = await database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// Delete expense
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Mark expense as synced
  Future<int> markAsSynced(int id) async {
    final db = await database;
    return db.update(
      'expenses',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all expenses
  Future<int> clearAll() async {
    final db = await database;
    return db.delete('expenses');
  }

  /// Get totals by category
  Future<List<Map<String, dynamic>>> getTotalsByCategory() async {
    final db = await database;
    return db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      GROUP BY category
      ORDER BY total DESC
    ''');
  }

  /// Get total by date range
  Future<double> getTotalByDateRange(String fromDate, String toDate) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM expenses
      WHERE date >= ? AND date <= ?
    ''',
      [fromDate, toDate],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get expense count
  Future<int> getExpenseCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM expenses');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}


