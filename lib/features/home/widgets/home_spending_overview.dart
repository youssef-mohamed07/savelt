import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/chart_placeholder.dart';
import '../../../widgets/spending_line_chart.dart';
import '../../analysis/analysis_page.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_state.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_state.dart';

/// Full spending analytics card for the home screen.
class HomeSpendingOverview extends StatefulWidget {
  const HomeSpendingOverview({super.key});

  @override
  State<HomeSpendingOverview> createState() => _HomeSpendingOverviewState();
}

class _HomeSpendingOverviewState extends State<HomeSpendingOverview> {
  static const _navy = Color(0xFF0D5DB8);

  String? _selectedDayKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsBloc>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, analyticsState) {
        return BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, expenseState) {
            final hasAnalytics = analyticsState.hasData &&
                analyticsState.analysisOverTime.isNotEmpty;
            final hasLocalData = expenseState is ExpenseLoaded &&
                expenseState.expenses.isNotEmpty;

            if (!hasAnalytics && !hasLocalData) {
              return const ChartPlaceholder(
                title: 'Spending chart',
                height: 240,
                type: ChartPlaceholderType.line,
              );
            }

            final expenses =
                expenseState is ExpenseLoaded ? expenseState.expenses : <dynamic>[];
            final chartSource = hasLocalData
                ? _analyticsFromExpenses(expenses)
                : analyticsState.analysisOverTime;
            final total = chartSource.values.fold<double>(0, (a, b) => a + b);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EDF5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D5DB8).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spending graph',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${total.toStringAsFixed(0)} EGP total',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openAnalysis(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View analytics',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _navy,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: _navy),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 245,
                    child: SpendingLineChart(
                      analyticsData: chartSource,
                      onDayTapped: (dateKey) {
                        setState(() {
                          _selectedDayKey = dateKey.isEmpty ? null : dateKey;
                        });
                      },
                    ),
                  ),
                  if (_selectedDayKey != null)
                    _dayDetailCard(
                      _selectedDayKey!,
                      analyticsState,
                      expenseState is ExpenseLoaded ? expenseState.expenses : [],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, double> _analyticsFromExpenses(List<dynamic> expenses) {
    final result = <String, double>{};
    for (final e in expenses) {
      try {
        final date = e.date as DateTime;
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        result[key] = (result[key] ?? 0) + (e.amount as double);
      } catch (_) {}
    }
    return result;
  }

  Widget _dayDetailCard(
    String dateKey,
    AnalyticsState analyticsState,
    List<dynamic> expenses,
  ) {
    final parts = dateKey.split('-');
    var dateLabel = dateKey;
    if (parts.length == 3) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final m = int.tryParse(parts[1]) ?? 1;
      dateLabel =
          '${months[(m - 1).clamp(0, 11)]} ${int.parse(parts[2])}, ${parts[0]}';
    }

    final dayTotal = analyticsState.analysisOverTime[dateKey] ?? 0.0;
    final byCategory = <String, double>{};
    for (final e in expenses) {
      try {
        final d = e.date as DateTime;
        final key =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (key != dateKey) continue;
        final cat = (e.category as String?) ?? 'Other';
        byCategory[cat] = (byCategory[cat] ?? 0) + (e.amount as double);
      } catch (_) {}
    }
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _navy.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: _navy),
              const SizedBox(width: 6),
              Text(
                dateLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const Spacer(),
              Text(
                '${dayTotal.toStringAsFixed(0)} EGP',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedDayKey = null),
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
          if (sorted.isNotEmpty)
            ...sorted.take(4).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(e.key, style: GoogleFonts.inter(fontSize: 12)),
                        ),
                        Text(
                          '${e.value.toStringAsFixed(0)} EGP',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _openAnalysis(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<ExpenseBloc>()),
            BlocProvider.value(value: context.read<AnalyticsBloc>()),
          ],
          child: const AnalysisPage(),
        ),
      ),
    );
  }
}
