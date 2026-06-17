/// State for real-time analytics from WebSocket
class AnalyticsState {
  /// Map of date string → amount  e.g. {"2026-04-28": 1500.0}
  final Map<String, double> analysisOverTime;

  /// Map of category name → amount  e.g. {"Food & Drink": 800.0}
  final Map<String, double> categoryAnalysis;

  /// Total amount for the current period
  final double totalAmount;

  /// Whether we have received at least one WebSocket update
  final bool hasData;

  const AnalyticsState({
    this.analysisOverTime = const {},
    this.categoryAnalysis = const {},
    this.totalAmount = 0,
    this.hasData = false,
  });

  AnalyticsState copyWith({
    Map<String, double>? analysisOverTime,
    Map<String, double>? categoryAnalysis,
    double? totalAmount,
    bool? hasData,
  }) {
    return AnalyticsState(
      analysisOverTime: analysisOverTime ?? this.analysisOverTime,
      categoryAnalysis: categoryAnalysis ?? this.categoryAnalysis,
      totalAmount: totalAmount ?? this.totalAmount,
      hasData: hasData ?? this.hasData,
    );
  }
}
