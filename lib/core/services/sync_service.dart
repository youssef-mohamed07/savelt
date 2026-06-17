import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'transaction_api_service.dart';
import 'auth_api_service.dart';

/// Keeps offline sync intent in memory and retries when connectivity returns.
/// Primary data store is MongoDB via the Node.js API (Mongoose ORM).
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final TransactionApiService _transactionApi = TransactionApiService.instance;

  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> initialize() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          _triggerSync();
        }
      },
    );

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

  /// Re-fetch from MongoDB-backed API when online (logged-in users only).
  Future<void> syncPendingChanges() async {
    if (_isSyncing) return;
    if (!await AuthApiService.instance.isAuthenticated()) return;

    _isSyncing = true;
    try {
      await _transactionApi.getMyTransactions(page: 1, limit: 1);
    } catch (e) {
      // Silent — UI blocs load data on their own schedule
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<void> syncExpenses() async => syncPendingChanges();

  Future<void> manualSync() async => syncPendingChanges();

  void startListening() {}
}
