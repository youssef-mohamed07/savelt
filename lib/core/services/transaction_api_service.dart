// Transaction API Service - خدمة المعاملات
// Handles all transaction API calls

import 'api_service.dart';
import '../models/transaction_model.dart';

class TransactionApiService {
  static final TransactionApiService instance = TransactionApiService._internal();
  TransactionApiService._internal();
  factory TransactionApiService() => instance;

  final ApiService _api = ApiService();

  // Create transaction with text
  Future<TransactionApiResult> createWithText({
    required String text,
    required double price,
    List<String>? itemIds,
    String? categoryId,
  }) async {
    final body = <String, dynamic>{
      'text': text,
      'price': price,
    };
    // Send categoryId directly — backend uses it as priority 1
    if (categoryId != null && categoryId.isNotEmpty) {
      body['categoryId'] = categoryId;
    }
    // Send items as plain string IDs: ["id1", "id2"]
    if (itemIds != null && itemIds.isNotEmpty) {
      body['items'] = itemIds;
    }

    final response = await _api.post('/transactions/createWithText', body: body);

    if (response.isSuccess) {
      final data = response.getData<Map<String, dynamic>>('data');
      if (data != null) {
        return TransactionApiResult.success(
          transaction: TransactionModel.fromMap(data),
          message: response.message,
        );
      }
    }

    return TransactionApiResult.failure(message: response.message ?? 'Failed to create transaction');
  }

  // Get my transactions (authenticated)
  Future<TransactionListResult> getMyTransactions({int page = 1, int limit = 50}) async {
    final response = await _api.get('/transactions/my', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': '-createdAt',
    });

    if (response.isSuccess) {
      final dataList = response.getData<List>('data') ?? [];
      final count = response.getData<int>('count') ?? 0;

      final transactions = dataList
          .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
          .toList();

      return TransactionListResult.success(
        transactions: transactions,
        totalCount: count,
        currentPage: page,
        totalPages: (count / limit).ceil().clamp(1, 9999),
      );
    }

    return TransactionListResult.failure(message: response.message ?? 'Failed to get transactions');
  }

  // Get all transactions with pagination
  Future<TransactionListResult> getTransactions({
    int page = 1,
    int limit = 10,
    String sort = '-createdAt',
    String? search,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _api.get('/transactions', queryParams: queryParams);

    if (response.isSuccess) {
      final dataList = response.getData<List>('data') ?? [];
      final meta = response.getData<Map<String, dynamic>>('meta');
      final count = response.getData<int>('count') ?? 0;

      final transactions = dataList
          .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
          .toList();

      return TransactionListResult.success(
        transactions: transactions,
        totalCount: count,
        currentPage: meta?['page'] ?? page,
        totalPages: meta?['totalPages'] ?? 1,
      );
    }

    return TransactionListResult.failure(message: response.message ?? 'Failed to get transactions');
  }

  // Delete transaction
  Future<TransactionApiResult> deleteTransaction(String id) async {
    final response = await _api.delete('/transactions/$id');

    if (response.isSuccess) {
      return TransactionApiResult.success(message: 'Transaction deleted');
    }

    return TransactionApiResult.failure(message: response.message ?? 'Failed to delete transaction');
  }

  // Get transaction by ID
  Future<TransactionApiResult> getTransaction(String id) async {
    final response = await _api.get('/transactions/$id');

    if (response.isSuccess) {
      final data = response.getData<Map<String, dynamic>>('data') ?? response.data;
      if (data != null) {
        return TransactionApiResult.success(
          transaction: TransactionModel.fromMap(data),
        );
      }
    }

    return TransactionApiResult.failure(message: response.message ?? 'Transaction not found');
  }

  // Get transactions by category
  Future<TransactionListResult> getByCategory(String categoryId, {int page = 1, int limit = 10}) async {
    final response = await _api.get('/transactions/category/$categoryId', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    if (response.isSuccess) {
      final dataList = response.getData<List>('data') ?? [];
      final count = response.getData<int>('count') ?? 0;

      final transactions = dataList
          .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
          .toList();

      return TransactionListResult.success(
        transactions: transactions,
        totalCount: count,
        currentPage: page,
        totalPages: (count / limit).ceil(),
      );
    }

    return TransactionListResult.failure(message: response.message ?? 'Failed to get transactions');
  }

  // Get transactions by date range
  Future<TransactionListResult> getByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _api.get('/transactions/date-range', queryParams: {
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'page': page.toString(),
      'limit': limit.toString(),
    });

    if (response.isSuccess) {
      final dataList = response.getData<List>('data') ?? [];
      final count = response.getData<int>('count') ?? 0;

      final transactions = dataList
          .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
          .toList();

      return TransactionListResult.success(
        transactions: transactions,
        totalCount: count,
        currentPage: page,
        totalPages: (count / limit).ceil(),
      );
    }

    return TransactionListResult.failure(message: response.message ?? 'Failed to get transactions');
  }

  // Update transaction
  Future<TransactionApiResult> updateTransaction({
    required String id,
    String? text,
    double? price,
  }) async {
    final body = <String, dynamic>{};
    if (text != null) body['text'] = text;
    if (price != null) body['price'] = price;

    final response = await _api.put('/transactions/$id', body: body);

    if (response.isSuccess) {
      final data = response.getData<Map<String, dynamic>>('data') ?? response.data;
      if (data != null) {
        return TransactionApiResult.success(
          transaction: TransactionModel.fromMap(data),
          message: 'Transaction updated',
        );
      }
    }

    return TransactionApiResult.failure(message: response.message ?? 'Failed to update transaction');
  }
}

// Transaction API Result
class TransactionApiResult {
  final bool isSuccess;
  final TransactionModel? transaction;
  final String? message;

  TransactionApiResult._({
    required this.isSuccess,
    this.transaction,
    this.message,
  });

  factory TransactionApiResult.success({
    TransactionModel? transaction,
    String? message,
  }) {
    return TransactionApiResult._(
      isSuccess: true,
      transaction: transaction,
      message: message,
    );
  }

  factory TransactionApiResult.failure({required String message}) {
    return TransactionApiResult._(
      isSuccess: false,
      message: message,
    );
  }
}

// Transaction List Result
class TransactionListResult {
  final bool isSuccess;
  final List<TransactionModel> transactions;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final String? message;

  TransactionListResult._({
    required this.isSuccess,
    this.transactions = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.message,
  });

  factory TransactionListResult.success({
    required List<TransactionModel> transactions,
    required int totalCount,
    required int currentPage,
    required int totalPages,
  }) {
    return TransactionListResult._(
      isSuccess: true,
      transactions: transactions,
      totalCount: totalCount,
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }

  factory TransactionListResult.failure({required String message}) {
    return TransactionListResult._(
      isSuccess: false,
      message: message,
    );
  }
}
