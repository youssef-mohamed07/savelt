import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/expense.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/chart_placeholder.dart';
import '../../widgets/spending_line_chart.dart';
import '../home/bloc/analytics_bloc.dart';
import '../home/bloc/analytics_state.dart';
import '../home/bloc/expense_bloc.dart';
import '../home/bloc/expense_state.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  static const _navy = Color(0xFF0D5DB8);
  static const _bg = Color(0xFFF0F4FA);
  static const _border = Color(0xFFE8EDF5);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedDayKey;
  _PeriodPreset _preset = _PeriodPreset.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsBloc>().refresh();
    });
  }

  void _applyPreset(_PeriodPreset preset) {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final today = dateOnly(now);

    setState(() {
      _preset = preset;
      switch (preset) {
        case _PeriodPreset.week:
          _fromDate = today.subtract(const Duration(days: 6));
          _toDate = today;
        case _PeriodPreset.month:
          _fromDate = today.subtract(const Duration(days: 29));
          _toDate = today;
        case _PeriodPreset.quarter:
          _fromDate = today.subtract(const Duration(days: 89));
          _toDate = today;
        case _PeriodPreset.all:
          _fromDate = null;
          _toDate = null;
        case _PeriodPreset.custom:
          break;
      }
      _selectedDayKey = null;
    });
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _fromDate ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: _toDate ?? now,
      title: 'From date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _fromDate = dateOnly(picked);
      _preset = _PeriodPreset.custom;
      _selectedDayKey = null;
      if (_toDate != null && _fromDate!.isAfter(_toDate!)) {
        _toDate = _fromDate;
      }
    });
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _toDate ?? now,
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: now,
      title: 'To date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _toDate = dateOnly(picked);
      _preset = _PeriodPreset.custom;
      _selectedDayKey = null;
    });
  }

  Map<String, double> _analyticsFromExpenses(List<Expense> expenses) {
    final result = <String, double>{};
    for (final e in expenses) {
      if (!_inRange(e.date)) continue;
      final key =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      result[key] = (result[key] ?? 0) + e.amount;
    }
    return result;
  }

  bool _inRange(DateTime date) {
    final d = dateOnly(date);
    if (_fromDate != null && d.isBefore(_fromDate!)) return false;
    if (_toDate != null && d.isAfter(_toDate!)) return false;
    return true;
  }

  double _rangeTotal(List<Expense> expenses) {
    return expenses
        .where((e) => _inRange(e.date))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double _todayTotal(List<Expense> expenses) {
    final today = dateOnly(DateTime.now());
    return expenses
        .where((e) => dateOnly(e.date) == today)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  String _topCategory(List<Expense> expenses) {
    final totals = <String, double>{};
    for (final e in expenses) {
      if (!_inRange(e.date)) continue;
      final cat = e.category.trim().isEmpty ? 'Other' : e.category.trim();
      totals[cat] = (totals[cat] ?? 0) + e.amount;
    }
    if (totals.isEmpty) return '—';
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  int _transactionCount(List<Expense> expenses) {
    return expenses.where((e) => _inRange(e.date)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
                builder: (context, analyticsState) {
                  return BlocBuilder<ExpenseBloc, ExpenseState>(
                    builder: (context, expenseState) {
                      final expenses = expenseState is ExpenseLoaded
                          ? expenseState.expenses
                          : <Expense>[];

                      final hasLocal = expenses.isNotEmpty;
                      final hasAnalytics = analyticsState.hasData &&
                          analyticsState.analysisOverTime.isNotEmpty;

                      Map<String, double> chartSource;
                      if (hasLocal) {
                        chartSource = _analyticsFromExpenses(expenses);
                      } else {
                        chartSource = Map<String, double>.from(
                          analyticsState.analysisOverTime,
                        );
                      }

                      final rangeTotal = hasLocal
                          ? _rangeTotal(expenses)
                          : chartSource.values.fold(0.0, (a, b) => a + b);
                      final todayTotal =
                          hasLocal ? _todayTotal(expenses) : 0.0;
                      final topCategory =
                          hasLocal ? _topCategory(expenses) : '—';
                      final txCount =
                          hasLocal ? _transactionCount(expenses) : 0;

                      return RefreshIndicator(
                        color: _navy,
                        onRefresh: () async {
                          context.read<ExpenseBloc>().refreshExpenses();
                          await context.read<AnalyticsBloc>().refresh(
                                from: _fromDate,
                                to: _toDate,
                              );
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            _buildPeriodChips(),
                            const SizedBox(height: 12),
                            _buildDateRow(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Period total',
                                    value:
                                        '${rangeTotal.toStringAsFixed(0)} EGP',
                                    icon: Icons.payments_outlined,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Today',
                                    value:
                                        '${todayTotal.toStringAsFixed(0)} EGP',
                                    icon: Icons.today_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Top category',
                                    value: topCategory,
                                    icon: Icons.category_outlined,
                                    valueFontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Transactions',
                                    value: '$txCount',
                                    icon: Icons.receipt_long_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildChartCard(
                              chartSource: chartSource,
                              rangeTotal: rangeTotal,
                              hasData: hasLocal || hasAnalytics,
                              expenses: expenses,
                              analyticsState: analyticsState,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: _text),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'INSIGHTS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PeriodPreset.week,
          _PeriodPreset.month,
          _PeriodPreset.quarter,
          _PeriodPreset.all,
        ].map((preset) {
          final selected = _preset == preset;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _applyPreset(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _navy : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _navy : _border,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _navy.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  preset.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(child: _DateTile(label: 'From', date: _fromDate, onTap: _pickFromDate)),
        const SizedBox(width: 10),
        Expanded(child: _DateTile(label: 'To', date: _toDate, onTap: _pickToDate)),
      ],
    );
  }

  Widget _buildChartCard({
    required Map<String, double> chartSource,
    required double rangeTotal,
    required bool hasData,
    required List<Expense> expenses,
    required AnalyticsState analyticsState,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
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
                        color: _text,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rangeTotal.toStringAsFixed(0)} EGP in selected period',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<ExpenseBloc>().refreshExpenses();
                  context.read<AnalyticsBloc>().refresh(
                        from: _fromDate,
                        to: _toDate,
                      );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 18, color: _navy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData || chartSource.isEmpty)
            const ChartPlaceholder(
              title: 'Spending chart',
              height: 245,
              type: ChartPlaceholderType.line,
            )
          else
            SizedBox(
              height: 245,
              child: SpendingLineChart(
                analyticsData: chartSource,
                fromDate: _fromDate,
                toDate: _toDate,
                onDayTapped: (dateKey) {
                  setState(() {
                    _selectedDayKey = dateKey.isEmpty ? null : dateKey;
                  });
                },
              ),
            ),
          if (_selectedDayKey != null)
            _DayDetailCard(
              dateKey: _selectedDayKey!,
              expenses: expenses,
              onClose: () => setState(() => _selectedDayKey = null),
            ),
        ],
      ),
    );
  }
}

enum _PeriodPreset { week, month, quarter, all, custom }

extension on _PeriodPreset {
  String get label => switch (this) {
        _PeriodPreset.week => '7 days',
        _PeriodPreset.month => '30 days',
        _PeriodPreset.quarter => '90 days',
        _PeriodPreset.all => 'All time',
        _PeriodPreset.custom => 'Custom',
      };
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  static const _navy = Color(0xFF0D5DB8);
  static const _border = Color(0xFFE8EDF5);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today_rounded, size: 16, color: _navy),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                    ),
                  ),
                  Text(
                    formatDisplayDate(date),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double valueFontSize;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueFontSize = 18,
  });

  static const _navy = Color(0xFF0D5DB8);
  static const _border = Color(0xFFE8EDF5);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _navy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              color: _text,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DayDetailCard extends StatelessWidget {
  final String dateKey;
  final List<Expense> expenses;
  final VoidCallback onClose;

  const _DayDetailCard({
    required this.dateKey,
    required this.expenses,
    required this.onClose,
  });

  static const _navy = Color(0xFF0D5DB8);

  @override
  Widget build(BuildContext context) {
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

    final byCategory = <String, double>{};
    var dayTotal = 0.0;
    for (final e in expenses) {
      final key =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      if (key != dateKey) continue;
      dayTotal += e.amount;
      final cat = e.category.trim().isEmpty ? 'Other' : e.category.trim();
      byCategory[cat] = (byCategory[cat] ?? 0) + e.amount;
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
                onTap: onClose,
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
                          child: Text(
                            e.key,
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
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
}
