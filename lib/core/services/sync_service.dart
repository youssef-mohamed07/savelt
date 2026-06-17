import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../network/dio_client.dart';
import 'transaction_api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final AppDatabase _database = AppDatabase.instance;
  final DioClient _dioClient = DioClient();
  final TransactionApiService _transactionApi = TransactionApiService.instance;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          _triggerSync();
        }
      },
    );

    // Start periodic sync
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _triggerSync();
    });
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    await syncPendingChanges();
  }

  Future<void> syncPendingChanges() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Process sync queue
      final pendingItems = await _database.getPendingSyncItems();
      
      for (final item in pendingItems) {
        await _processSyncItem(item);
      }

      // Sync unsynced expenses
      await _syncUnsyncedExpenses();
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processSyncItem(SyncQueueData item) async {
    try {
      switch (item.operation) {
        case 'CREATE':
          await _syncCreateOperation(item);
          break;
        case 'UPDATE':
          await _syncUpdateOperation(item);
          break;
        case 'DELETE':
          await _syncDeleteOperation(item);
          break;
      }
      
      // Remove from sync queue on success
      await _database.removeSyncItem(item.id);
    } catch (e) {
      // Increment retry count
      final updatedItem = item.copyWith(
        retryCount: item.retryCount + 1,
        lastAttempt: Value(DateTime.now()),
      );
      
      // Remove if max retries reached
      if (updatedItem.retryCount >= 5) {
        await _database.removeSyncItem(item.id);
      } else {
        await _database.updateSyncItem(updatedItem);
      }
    }
  }

  Future<void> _syncCreateOperation(SyncQueueData item) async {
    final data = jsonDecode(item.data) as Map<String, dynamic>;
    
    if (item.tableNameField == 'expenses') {
      final result = await _transactionApi.createWithText(
        text: data['title'] ?? '',
        price: (data['amount'] as num).toDouble(),
      );
      
      if (result.isSuccess && result.transaction != null) {
        // Mark as synced in local database
        await _database.markExpenseAsSynced(
          item.recordId,
          result.transaction!.id,
        );
      }
    }
  }

  Future<void> _syncUpdateOperation(SyncQueueData item) async {
    final data = jsonDecode(item.data) as Map<String, dynamic>;
    
    if (item.tableNameField == 'expenses') {
      final expense = await _database.getExpenseById(item.recordId);
      if (expense?.syncId != null) {
        await _transactionApi.updateTransaction(
          id: expense!.syncId!,
          text: data['title'],
          price: (data['amount'] as num?)?.toDouble(),
        );
      }
    }
  }

  Future<void> _syncDeleteOperation(SyncQueueData item) async {
    if (item.tableNameField == 'expenses') {
      final data = jsonDecode(item.data) as Map<String, dynamic>;
      final syncId = data['syncId'] as String?;
      
      if (syncId != null) {
        await _transactionApi.deleteTransaction(syncId);
      }
    }
  }

  Future<void> _syncUnsyncedExpenses() async {
    final unsyncedExpenses = await _database.getUnsyncedExpenses();
    
    for (final expense in unsyncedExpenses) {
      try {
        final result = await _transactionApi.createWithText(
          text: expense.title,
          price: expense.amount,
        );
        
        if (result.isSuccess && result.transaction != null) {
          await _database.markExpenseAsSynced(
            expense.id,
            result.transaction!.id,
          );
        }
      } catch (e) {
        // Add to sync queue for retry
        await _database.addToSyncQueue(
          SyncQueueCompanion.insert(
            operation: 'CREATE',
            tableNameField: 'expenses',
            recordId: expense.id,
            data: jsonEncode({
              'title': expense.title,
              'amount': expense.amount,
              'category': expense.category,
              'quantity': expense.quantity,
              'isVoiceInput': expense.isVoiceInput,
              'date': expense.date.toIso8601String(),
            }),
          ),
        );
      }
    }
  }

  Future<void> addExpenseToSyncQueue(String expenseId) async {
    final expense = await _database.getExpenseById(expenseId);
    if (expense == null) return;

    await _database.addToSyncQueue(
      SyncQueueCompanion.insert(
        operation: 'CREATE',
        tableNameField: 'expenses',
        recordId: expense.id,
        data: jsonEncode({
          'title': expense.title,
          'amount': expense.amount,
          'category': expense.category,
          'quantity': expense.quantity,
          'isVoiceInput': expense.isVoiceInput,
          'date': expense.date.toIso8601String(),
        }),
      ),
    );

    // Trigger immediate sync if online
    _triggerSync();
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  // دوال إضافية للاستخدام في الصفحات الأخرى
  Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<void> syncExpenses() async {
    await _syncUnsyncedExpenses();
  }

  Future<void> manualSync() async {
    await syncPendingChanges();
  }

  void startListening() {
    // Already started in initialize()
  }
}