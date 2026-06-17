import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Tables
class Expenses extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  BoolColumn get isVoiceInput => boolean().withDefault(const Constant(false))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()(); // Backend ID after sync

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()(); // CREATE, UPDATE, DELETE
  TextColumn get tableNameField => text()(); // Changed from tableName to avoid conflict
  TextColumn get recordId => text()();
  TextColumn get data => text()(); // JSON data
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
}

@DriftDatabase(tables: [Expenses, SyncQueue])
class AppDatabase extends _$AppDatabase {
  // Singleton instance
  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  AppDatabase._internal() : super(_openConnection());

  // Keep default constructor for backward compatibility — returns singleton
  factory AppDatabase() => instance;

  @override
  int get schemaVersion => 1;

  // Expense operations
  Future<List<Expense>> getAllExpenses() => select(expenses).get();

  Future<Expense?> getExpenseById(String id) =>
      (select(expenses)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);

  Future<bool> updateExpense(Expense expense) =>
      update(expenses).replace(expense);

  Future<int> deleteExpense(String id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();

  // Sync operations
  Future<List<SyncQueueData>> getPendingSyncItems() =>
      select(syncQueue).get();

  Future<int> addToSyncQueue(SyncQueueCompanion item) =>
      into(syncQueue).insert(item);

  Future<int> removeSyncItem(int id) =>
      (delete(syncQueue)..where((s) => s.id.equals(id))).go();

  Future<bool> updateSyncItem(SyncQueueData item) =>
      update(syncQueue).replace(item);

  // Mark expense as synced
  Future<void> markExpenseAsSynced(String localId, String syncId) async {
    await (update(expenses)..where((e) => e.id.equals(localId))).write(
      ExpensesCompanion(
        isSynced: const Value(true),
        syncId: Value(syncId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Get unsynced expenses
  Future<List<Expense>> getUnsyncedExpenses() =>
      (select(expenses)..where((e) => e.isSynced.equals(false))).get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.db'));
    return NativeDatabase(file);
  });
}