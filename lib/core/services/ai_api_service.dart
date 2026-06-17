import 'dart:io';
import 'api_service.dart';

class AiApiService {
  static final AiApiService instance = AiApiService._internal();
  AiApiService._internal();
  factory AiApiService() => instance;

  final ApiService _api = ApiService();

  Future<AiAnalysisResult> analyzeText(String text) async {
    final response = await _api.post('/ai/analyze', body: {
      'text': text,
    });

    if (response.isSuccess) {
      return AiAnalysisResult.success(data: response.data);
    }

    return AiAnalysisResult.failure(message: response.message ?? 'Failed to analyze text');
  }

  Future<AiAnalysisResult> analyzeVoice(File voiceFile) async {
    final response = await _api.postMultipart(
      '/ai/voice',
      files: {'voice': voiceFile},
    );

    if (response.isSuccess) {
      return AiAnalysisResult.success(data: response.data);
    }

    return AiAnalysisResult.failure(message: response.message ?? 'Failed to analyze voice');
  }

  Future<AiAnalysisResult> analyzeImage(File imageFile) async {
    final response = await _api.postMultipart(
      '/ai/image',
      files: {'image': imageFile},
    );

    if (response.isSuccess) {
      return AiAnalysisResult.success(data: response.data);
    }

    return AiAnalysisResult.failure(message: response.message ?? 'Failed to analyze image');
  }

  Future<AiAnalysisResult> getSpendingInsights({
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

    final response = await _api.get('/ai/insights', queryParams: queryParams);

    if (response.isSuccess) {
      return AiAnalysisResult.success(data: response.data);
    }

    return AiAnalysisResult.failure(message: response.message ?? 'Failed to get insights');
  }

  Future<AiAnalysisResult> getBudgetRecommendations() async {
    final response = await _api.get('/ai/budget-recommendations');

    if (response.isSuccess) {
      return AiAnalysisResult.success(data: response.data);
    }

    return AiAnalysisResult.failure(message: response.message ?? 'Failed to get recommendations');
  }

  Future<AiAnalysisResult> predictSpending({
    int months = 3,
  }) async {
    final response = await _api.get('/ai/predict-spending', queryParams: {
      'months': months.toString(),
    });

    if (response.isSuccess) {
      return AiAnalysisResult.success(data: response.data);
    }

    return AiAnalysisResult.failure(message: response.message ?? 'Failed to predict spending');
  }
}

class AiAnalysisResult {
  final bool isSuccess;
  final dynamic data;
  final String? message;

  AiAnalysisResult._({
    required this.isSuccess,
    this.data,
    this.message,
  });

  factory AiAnalysisResult.success({dynamic data}) {
    return AiAnalysisResult._(
      isSuccess: true,
      data: data,
    );
  }

  factory AiAnalysisResult.failure({required String message}) {
    return AiAnalysisResult._(
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

  List<Map<String, dynamic>> getTransactions() {
    final transactions = getData<List>('transactions') ?? [];
    return transactions.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> getItems() {
    final items = getData<List>('items') ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> getCategories() {
    final categories = getData<List>('categories') ?? [];
    return categories.cast<Map<String, dynamic>>();
  }
}