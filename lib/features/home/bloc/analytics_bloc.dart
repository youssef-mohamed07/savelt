import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/local_storage_service.dart';
import 'analytics_state.dart';

/// Listens to WebSocket analytics_update events and exposes them as state.
/// Also fetches initial data from the REST analytics API.
class AnalyticsBloc extends Cubit<AnalyticsState> {
  final ApiService _api = ApiService();
  final LocalStorageService _storage = LocalStorageService();
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  // Static instance for global access
  static AnalyticsBloc? _instance;
  static AnalyticsBloc? get instance => _instance;

  AnalyticsBloc() : super(const AnalyticsState()) {
    _instance = this;
    _subscribeToWebSocket();
    // Delay initial fetch to ensure auth token is loaded
    Future.delayed(const Duration(seconds: 2), _fetchInitial);
  }

  // ── WebSocket subscription ─────────────────────────────────────────────────

  void _subscribeToWebSocket() {
    _wsSub = WebSocketService.instance.analyticsStream.listen((payload) {
      _applyPayload(payload);
    });
  }

  void _applyPayload(Map<String, dynamic> payload) {
    final rawTime = payload['analysis_over_time'];
    final rawCat  = payload['category_analysis'];
    final total   = (payload['total_amount'] as num?)?.toDouble() ?? 0;

    final analysisOverTime = <String, double>{};
    if (rawTime is Map) {
      rawTime.forEach((k, v) {
        analysisOverTime[k.toString()] = (v as num).toDouble();
      });
    }

    final categoryAnalysis = <String, double>{};
    if (rawCat is Map) {
      rawCat.forEach((k, v) {
        categoryAnalysis[k.toString()] = (v as num).toDouble();
      });
    }

    emit(state.copyWith(
      analysisOverTime: analysisOverTime,
      categoryAnalysis: categoryAnalysis,
      totalAmount: total,
      hasData: true,
    ));

    print('📊 [AnalyticsBloc] Updated: ${analysisOverTime.length} time points, total=$total');
  }

  // ── Initial REST fetch ─────────────────────────────────────────────────────

  Future<void> _fetchInitial({int retryCount = 0}) async {
    try {
      // Wait for auth token before fetching
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        if (retryCount < 5) {
          await Future.delayed(const Duration(seconds: 2));
          await _fetchInitial(retryCount: retryCount + 1);
        }
        return;
      }
      // Always fetch daily data for zigzag chart
      final now = DateTime.now();
      final start = DateTime(2020, 1, 1);
      final period = 'daily';

      final response = await _api.get('/analytics/by-date', queryParams: {
        'period': period,
        'startDate': start.toIso8601String().split('T')[0],
        'endDate': now.toIso8601String().split('T')[0],
      });

      if (response.isSuccess) {
        final data = response.getData<Map<String, dynamic>>('data');
        final analytics = data?['analytics'] as List? ?? [];

        final analysisOverTime = <String, double>{};
        for (final item in analytics) {
          final date = item['_id']?.toString() ?? '';
          final amount = (item['totalAmount'] as num?)?.toDouble() ?? 0;
          if (date.isNotEmpty) analysisOverTime[date] = amount;
        }

        // Also fetch category breakdown
        final catResponse = await _api.get('/analytics/by-category');
        final catData = catResponse.getData<Map<String, dynamic>>('data');
        final categories = catData?['categories'] as List? ?? [];

        final categoryAnalysis = <String, double>{};
        for (final cat in categories) {
          final name = cat['categoryName']?.toString() ?? 'Other';
          final amount = (cat['totalAmount'] as num?)?.toDouble() ?? 0;
          categoryAnalysis[name] = amount;
        }

        final grandTotal = (catData?['grandTotal'] as num?)?.toDouble() ?? 0;

        if (analysisOverTime.isNotEmpty || categoryAnalysis.isNotEmpty) {
          emit(state.copyWith(
            analysisOverTime: analysisOverTime,
            categoryAnalysis: categoryAnalysis,
            totalAmount: grandTotal,
            hasData: true,
          ));
          print('📊 [AnalyticsBloc] Initial data loaded: ${analysisOverTime.length} days');
        }
      } else if (retryCount < 3) {
        // Retry after delay if failed
        await Future.delayed(Duration(seconds: 3 * (retryCount + 1)));
        await _fetchInitial(retryCount: retryCount + 1);
      }
    } catch (e) {
      print('⚠️ [AnalyticsBloc] Initial fetch failed (attempt ${retryCount + 1}): $e');
      if (retryCount < 3) {
        await Future.delayed(Duration(seconds: 3 * (retryCount + 1)));
        await _fetchInitial(retryCount: retryCount + 1);
      }
    }
  }

  /// Manually trigger a refresh (e.g. after date filter change)
  Future<void> refresh({DateTime? from, DateTime? to}) async {
    try {
      final now = DateTime.now();
      final start = from ?? DateTime(2020, 1, 1);
      final end = to ?? now;
      final period = 'daily'; // Always daily for zigzag

      final response = await _api.get('/analytics/by-date', queryParams: {
        'period': period,
        'startDate': start.toIso8601String().split('T')[0],
        'endDate': end.toIso8601String().split('T')[0],
      });

      if (response.isSuccess) {
        final data = response.getData<Map<String, dynamic>>('data');
        final analytics = data?['analytics'] as List? ?? [];

        final analysisOverTime = <String, double>{};
        for (final item in analytics) {
          final date = item['_id']?.toString() ?? '';
          final amount = (item['totalAmount'] as num?)?.toDouble() ?? 0;
          if (date.isNotEmpty) analysisOverTime[date] = amount;
        }

        emit(state.copyWith(
          analysisOverTime: analysisOverTime,
          hasData: analysisOverTime.isNotEmpty,
        ));
      }
    } catch (e) {
      print('⚠️ [AnalyticsBloc] Refresh failed: $e');
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
