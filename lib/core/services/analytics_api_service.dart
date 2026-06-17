import 'api_service.dart';

class AnalyticsApiService {
  static final AnalyticsApiService instance = AnalyticsApiService._internal();
  AnalyticsApiService._internal();
  factory AnalyticsApiService() => instance;

  final ApiService _api = ApiService();

  Future<AnalyticsResult> getSpendingAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }
    if (categoryId != null) {
      queryParams['category'] = categoryId;
    }

    final response = await _api.get('/analytics/spending', queryParams: queryParams);

    if (response.isSuccess) {
      return AnalyticsResult.success(data: response.data);
    }

    return AnalyticsResult.failure(message: response.message ?? 'Failed to get analytics');
  }

  Future<AnalyticsResult> getCategoryBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }

    final response = await _api.get('/analytics/category-breakdown', queryParams: queryParams);

    if (response.isSuccess) {
      return AnalyticsResult.success(data: response.data);
    }

    return AnalyticsResult.failure(message: response.message ?? 'Failed to get category breakdown');
  }

  Future<AnalyticsResult> getMonthlyTrends({
    int? months = 12,
  }) async {
    final queryParams = {
      'months': months.toString(),
    };

    final response = await _api.get('/analytics/monthly-trends', queryParams: queryParams);

    if (response.isSuccess) {
      return AnalyticsResult.success(data: response.data);
    }

    return AnalyticsResult.failure(message: response.message ?? 'Failed to get monthly trends');
  }

  Future<AnalyticsResult> getTopItems({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
    };
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }

    final response = await _api.get('/analytics/top-items', queryParams: queryParams);

    if (response.isSuccess) {
      return AnalyticsResult.success(data: response.data);
    }

    return AnalyticsResult.failure(message: response.message ?? 'Failed to get top items');
  }

  Future<AnalyticsResult> getBudgetAnalysis({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }

    final response = await _api.get('/analytics/budget-analysis', queryParams: queryParams);

    if (response.isSuccess) {
      return AnalyticsResult.success(data: response.data);
    }

    return AnalyticsResult.failure(message: response.message ?? 'Failed to get budget analysis');
  }
}

class AnalyticsResult {
  final bool isSuccess;
  final dynamic data;
  final String? message;

  AnalyticsResult._({
    required this.isSuccess,
    this.data,
    this.message,
  });

  factory AnalyticsResult.success({dynamic data}) {
    return AnalyticsResult._(
      isSuccess: true,
      data: data,
    );
  }

  factory AnalyticsResult.failure({required String message}) {
    return AnalyticsResult._(
      isSuccess: false,
      message: message,
    );
  }

  T? getData<T>(String key) {
    if (data is Map) {
      return data[key] as T?;
    }
    return null;
  }
}