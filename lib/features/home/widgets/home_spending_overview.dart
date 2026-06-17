import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/app_date_picker.dart';
import '../../../widgets/chart_placeholder.dart';
import '../../../widgets/spending_line_chart.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_state.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_state.dart';

/// Spending chart with date filter — extracted from home_page.
class HomeSpendingOverview extends StatefulWidget {
  const HomeSpendingOverview({super.key});

  @override
  State<HomeSpendingOverview> createState() => _HomeSpendingOverviewState();
}

class _HomeSpendingOverviewState extends State<HomeSpendingOverview> {
  static const _navy = Color(0xFF0D5DB8);

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedDayKey;

  bool get _hasDateFilter => _fromDate != null || _toDate != null;

  @override
  void initState() {
    super.initState();
    // Ensure chart loads full history (not a single-day slice).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasDateFilter) return;
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
                title: 'Your Spending Overview',
                height: 160,
                type: ChartPlaceholderType.bar,
              );
            }

            final expenses =
                expenseState is ExpenseLoaded ? expenseState.expenses : <dynamic>[];

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spending Overview',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (analyticsState.totalAmount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${analyticsState.totalAmount.toStringAsFixed(0)} EGP',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0D5DB8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _dateField(
                          label: 'From',
                          date: _fromDate,
                          onTap: () => _pickDate(context, isFrom: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _dateField(
                          label: 'To',
                          date: _toDate,
                          onTap: () => _pickDate(context, isFrom: false),
                        ),
                      ),
                    ],
                  ),
                  if (_hasDateFilter) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _fromDate = null;
                          _toDate = null;
                          _selectedDayKey = null;
                        });
                        context.read<AnalyticsBloc>().refresh();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.close_rounded,
                                size: 16, color: Color(0xFFEF4444)),
                            const SizedBox(width: 6),
                            Text(
                              'Clear filter — show all',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 240,
                    child: SpendingLineChart(
                      analyticsData: hasAnalytics
                          ? analyticsState.analysisOverTime
                          : _analyticsFromExpenses(expenses),
                      fromDate: _fromDate,
                      toDate: _toDate,
                      onDayTapped: (dateKey) {
                        setState(() {
                          _selectedDayKey =
                              _selectedDayKey == dateKey ? null : dateKey;
                        });
                      },
                    ),
                  ),
                  if (_selectedDayKey != null)
                    _dayDetailCard(
                      _selectedDayKey!,
                      analyticsState,
                      expenseState is ExpenseLoaded
                          ? expenseState.expenses
                          : [],
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D5DB8).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded,
                            size: 16, color: Color(0xFF0D5DB8)),
                        const SizedBox(width: 6),
                        Text(
                          'Tap a point to see details',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF0D5DB8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final display = formatDisplayDate(date);
    final todaySelected = isToday(date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: todaySelected
                ? _navy.withValues(alpha: 0.06)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: date != null
                  ? (todaySelected
                      ? _navy.withValues(alpha: 0.35)
                      : _navy.withValues(alpha: 0.2))
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: _navy,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      display,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _navy.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final today = dateOnly(DateTime.now());
    final picked = await showAppDatePicker(
      context: context,
      title: isFrom ? 'From date' : 'To date',
      initialDate: isFrom
          ? (_fromDate ?? today)
          : (_toDate ?? _fromDate ?? today),
      firstDate: isFrom ? DateTime(2020) : (_fromDate ?? DateTime(2020)),
      lastDate: today,
    );
    if (picked == null || !context.mounted) return;

    setState(() {
      if (isFrom) {
        _fromDate = dateOnly(picked);
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = null;
        }
      } else {
        _toDate = dateOnly(picked);
      }
      _selectedDayKey = null;
    });
    context.read<AnalyticsBloc>().refresh(from: _fromDate, to: _toDate);
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
        color: const Color(0xFF0D5DB8).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0D5DB8).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: Color(0xFF0D5DB8)),
              const SizedBox(width: 6),
              Text(dateLabel,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D5DB8))),
              const Spacer(),
              Text('${dayTotal.toStringAsFixed(0)} EGP',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D5DB8))),
              GestureDetector(
                onTap: () => setState(() => _selectedDayKey = null),
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
          if (sorted.isNotEmpty)
            ...sorted.take(3).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(e.key,
                                style: GoogleFonts.inter(fontSize: 12))),
                        Text('${e.value.toStringAsFixed(0)} EGP',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
          else if (dayTotal == 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('No spending on this day',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF9CA3AF))),
            ),
        ],
      ),
    );
  }
}
