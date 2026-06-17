// This file has been replaced by backend API services
// All Firebase functionality has been migrated to:
// - AuthApiService for authentication
// - TransactionApiService for expense management
// - Other API services in the same directory

// This file is kept as a placeholder to prevent import errors
// but all functionality has been moved to backend API services

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();
  factory FirestoreService() => instance;

  // Deprecated - use backend API services instead
  @deprecated
  void showDeprecationWarning() {
    print('⚠️ FirestoreService is deprecated. Use backend API services instead.');
  }
}