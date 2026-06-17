import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../home/bloc/expense_bloc.dart';
import '../home/bloc/expense_state.dart';
import '../items/items_page.dart';
import '../../widgets/chart_placeholder.dart';
import '../../widgets/dialogs/add_category_dialog.dart';
import 'bloc/category_bloc.dart';
import 'widgets/category_list_tile.dart';
import 'widgets/category_ui_helpers.dart';

/// Categories Page - عرض الفئات مع Pie Chart
/// يعرض pie chart ديناميك وقائمة الفئات
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoriesPageContent();
  }
}

class _CategoriesPageContent extends StatefulWidget {
  const _CategoriesPageContent();

  @override
  State<_CategoriesPageContent> createState() => _CategoriesPageContentState();
}

class _CategoriesPageContentState extends State<_CategoriesPageContent> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
  }

  void _setDefaultDates() {
    // Start with no filter — show all data by default
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  bool get _isDateFiltered => _fromDate != null || _toDate != null;

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  /// Filter expenses by the selected date range
  List<dynamic> _filterByDate(List<dynamic> expenses) {
    if (!_isDateFiltered) return expenses;
    return expenses.where((e) {
      final date = e.date as DateTime;
      if (_fromDate != null) {
        final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (date.isBefore(from)) return false;
      }
      if (_toDate != null) {
        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (date.isAfter(to)) return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _buildCategoryList(
    List<Map<String, dynamic>> apiCategories,
    List<dynamic> expenses,
  ) {
    final byName = <String, Map<String, dynamic>>{};

    for (final category in apiCategories) {
      final name = category['name'] as String;
      byName[name.toLowerCase()] = category;
    }

    for (final expense in expenses) {
      final name = expense.category as String?;
      if (name == null || name.trim().isEmpty) continue;
      final key = name.toLowerCase();
      if (!byName.containsKey(key)) {
        byName[key] = {
          'name': name,
          'icon': Icons.category_rounded,
          'isDefault': false,
        };
      }
    }

    return byName.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildDateCard(),
                    const SizedBox(height: 16),
                    _buildChartCard(),
                    const SizedBox(height: 20),
                    Text(
                      'All categories',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoriesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D5DB8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'INSIGHTS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D5DB8),
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Categories',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
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

  Widget _buildSummaryCard() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        var total = 0.0;
        var activeCount = 0;
        if (state is ExpenseLoaded && state.hasData) {
          final filtered = _filterByDate(state.expenses);
          final totals = <String, double>{};
          for (final e in filtered) {
            totals[e.category] = (totals[e.category] ?? 0) + e.amount;
          }
          total = totals.values.fold(0.0, (a, b) => a + b);
          activeCount = totals.values.where((v) => v > 0).length;
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D5DB8), Color(0xFF0A4A94)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D5DB8).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total spending',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${total.toStringAsFixed(0)} EGP',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$activeCount',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Active',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.8),
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
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: _buildDateSelectors(),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: _buildPieChart(),
    );
  }

  Widget _buildDateSelectors() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSimpleDateField(
                label: 'From',
                date: _fromDate,
                onTap: () => _selectFromDate(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSimpleDateField(
                label: 'To',
                date: _toDate,
                onTap: () => _selectToDate(),
              ),
            ),
          ],
        ),
        if (_isDateFiltered) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _clearDateFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
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
      ],
    );
  }

  Widget _buildSimpleDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final isActive = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF0D5DB8) : const Color(0xFFE2E8F0),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.event_available_rounded : Icons.calendar_today_outlined,
              color: const Color(0xFF0D5DB8),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? '$label: ${date.day}/${date.month}' : '$label: Any',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? const Color(0xFF0D5DB8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Track selected category for drill-down
  String? _selectedCategory;
  
  Widget _buildPieChart() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        return BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            final allCategories = _buildCategoryList(
              categoryState.customCategories,
              state is ExpenseLoaded ? state.expenses : const [],
            );

            if (state is ExpenseLoaded && state.isEmpty) {
              return const ChartPlaceholder(
                title: 'Spending by Category',
                height: 150,
                type: ChartPlaceholderType.pie,
              );
            }

            Map<String, double> categoryTotals = {};
            double totalAmount = 0;

            if (state is ExpenseLoaded && state.hasData) {
              final filtered = _filterByDate(state.expenses);

              for (var cat in allCategories) {
                final name = cat['name'] as String;
                final total = filtered
                    .where((e) => e.category == name)
                    .fold<double>(0, (sum, e) => sum + e.amount);
                if (total > 0) {
                  categoryTotals[name] = total;
                }
              }

              totalAmount = categoryTotals.values.fold(0, (sum, a) => sum + a);
            }

            if (totalAmount == 0) {
              return const ChartPlaceholder(
                title: 'Spending by Category',
                height: 150,
                type: ChartPlaceholderType.pie,
              );
            }

            if (_selectedCategory != null && state is ExpenseLoaded) {
              return _buildItemsBreakdownChart(state, _selectedCategory!);
            }

            return Column(
              children: [
                Text(
                  'Spending breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a slice to drill down',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTapUp: (details) {
                    final tappedCategory = _getTappedCategory(
                      details.localPosition,
                      const Size(220, 220),
                      categoryTotals,
                      totalAmount,
                    );
                    if (tappedCategory != null) {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedCategory = tappedCategory);
                    }
                  },
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(220, 220),
                          painter: PieChartPainter(categoryTotals, totalAmount),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              totalAmount.toStringAsFixed(0),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'EGP',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildChartLegend(categoryTotals, totalAmount),
              ],
            );
          },
        );
      },
    );
  }

  // Get which category was tapped based on position
  String? _getTappedCategory(
    Offset tapPosition,
    Size size,
    Map<String, double> categoryTotals,
    double totalAmount,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    // Check if tap is within the pie
    final distance = (tapPosition - center).distance;
    if (distance > radius) return null;
    
    // Calculate angle of tap
    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    var tapAngle = math.atan2(dy, dx);
    
    // Normalize angle to start from top (-π/2)
    tapAngle = tapAngle + math.pi / 2;
    if (tapAngle < 0) tapAngle += 2 * math.pi;
    
    // Find which segment was tapped
    double startAngle = 0;
    for (final entry in categoryTotals.entries) {
      if (entry.value > 0) {
        final sweepAngle = (entry.value / totalAmount) * 2 * math.pi;
        if (tapAngle >= startAngle && tapAngle < startAngle + sweepAngle) {
          return entry.key;
        }
        startAngle += sweepAngle;
      }
    }
    return null;
  }

  // Build items breakdown chart for selected category
  Widget _buildItemsBreakdownChart(ExpenseLoaded state, String categoryName) {
    // Apply date filter then filter by category
    final filtered = _filterByDate(state.expenses)
        .where((e) => e.category == categoryName)
        .toList();

    final Map<String, double> itemTotals = {};
    final Map<String, int> itemCounts = {};

    for (final expense in filtered) {
      final itemName = expense.title;
      itemTotals[itemName] = (itemTotals[itemName] ?? 0) + expense.amount;
      itemCounts[itemName] = (itemCounts[itemName] ?? 0) + 1;
    }
    
    if (itemTotals.isEmpty) {
      return Column(
        children: [
          _buildBackButton(),
          const SizedBox(height: 16),
          Text(
            'No items in $categoryName',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      );
    }
    
    // Sort by AMOUNT (highest spending first)
    final sortedItems = itemTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final totalAmount = itemTotals.values.fold(0.0, (sum, v) => sum + v);
    
    return Column(
      children: [
        // Back button and title
        _buildBackButton(),
        const SizedBox(height: 8),
        Text(
          categoryName,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1976D2),
          ),
        ),
        Text(
          'Spending breakdown',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        
        // Items pie chart (based on amount)
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: ItemsPieChartPainter(
              items: sortedItems,
              itemCounts: itemCounts,
              totalCount: totalAmount.toInt(),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Items legend - sorted by amount (EGP percentage)
        ...sortedItems.take(5).map((entry) {
          final percentage = totalAmount > 0 ? ((entry.value / totalAmount) * 100).round() : 0;
          final colorIndex = sortedItems.indexOf(entry);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getItemColor(colorIndex),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.key,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$percentage%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.value.toInt()} EGP',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedCategory = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1976D2).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: Color(0xFF1976D2),
            ),
            const SizedBox(width: 4),
            Text(
              'Back to Categories',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getItemColor(int index) {
    return categoryChartColors[index % categoryChartColors.length];
  }

  List<Widget> _buildChartLegend(Map<String, double> totals, double totalAmount) {
    final sorted = totals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(6).map((entry) {
      final i = sorted.indexOf(entry);
      final pct = totalAmount > 0 ? ((entry.value / totalAmount) * 100).round() : 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: categoryChartColors[i % categoryChartColors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$pct%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D5DB8),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.value.toStringAsFixed(0)} EGP',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildCategoriesList() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        return BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            final allCategories = _buildCategoryList(
              categoryState.customCategories,
              state is ExpenseLoaded ? state.expenses : const [],
            );

            Map<String, double> categoryTotals = {};
            if (state is ExpenseLoaded) {
              final filtered = _filterByDate(state.expenses);
              for (var cat in allCategories) {
                final name = cat['name'] as String;
                categoryTotals[name] = filtered
                    .where((e) => e.category == name)
                    .fold<double>(0, (sum, e) => sum + e.amount);
              }
            }

            final grandTotal = categoryTotals.values.fold(0.0, (a, b) => a + b);

            final sortedCategories = allCategories.toList()
              ..sort((a, b) {
                final am = categoryTotals[a['name']] ?? 0;
                final bm = categoryTotals[b['name']] ?? 0;
                return bm.compareTo(am);
              });

            return Column(
              children: [
                ...sortedCategories.map((category) {
                  final name = category['name'] as String;
                  final amount = categoryTotals[name] ?? 0;
                  final isDefault = category['isDefault'] as bool? ?? false;
                  final share = grandTotal > 0 ? amount / grandTotal : 0.0;

                  final tile = CategoryListTile(
                    name: name,
                    icon: category['icon'] as IconData,
                    amount: amount,
                    share: share,
                    isDefault: isDefault,
                    onTap: () => _openCategoryItems(name, category['icon'] as IconData),
                    onDelete: isDefault ? null : () => _deleteCategory(name),
                  );

                  if (isDefault) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: tile,
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: Key('cat_$name'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        _deleteCategory(name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$name deleted')),
                        );
                      },
                      child: tile,
                    ),
                  );
                }),
                const SizedBox(height: 16),
                _buildAddCategoryButton(),
              ],
            );
          },
        );
      },
    );
  }

  void _openCategoryItems(String name, IconData icon) {
    if (!mounted || !context.mounted) return;
    try {
      final expenseBloc = context.read<ExpenseBloc>();
      final style = categoryUiStyle(name);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: expenseBloc,
            child: ItemsPage(
              categoryName: name,
              categoryIcon: icon,
              categoryColor: style.color,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error navigating to ItemsPage: $e');
    }
  }

  Widget _buildAddCategoryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _addNewCategory();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0D5DB8), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFF0D5DB8), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Add category',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D5DB8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addNewCategory() async {
    debugPrint('=== _addNewCategory START ===');
    HapticFeedback.lightImpact();
    
    final result = await showAddCategoryDialog(context);
    debugPrint('=== Result received: $result ===');
    
    if (result != null && result['name'] != null && result['icon'] != null) {
      // Use CategoryBloc to add category
      context.read<CategoryBloc>().add(AddCategory(
        name: result['name'] as String,
        icon: result['icon'] as IconData,
      ));
      
      debugPrint('=== Category added via BLoC ===');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${result['name']}" added!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } else {
      debugPrint('=== Dialog cancelled or invalid result ===');
    }
  }

  void _deleteCategory(String name) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Category',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Use CategoryBloc to delete category
              context.read<CategoryBloc>().add(DeleteCategory(name));
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "$name" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
    }
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;
  final double totalAmount;

  PieChartPainter(this.categoryTotals, this.totalAmount);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    final colors = categoryChartColors;

    double startAngle = -math.pi / 2;
    int colorIndex = 0;

    categoryTotals.forEach((category, amount) {
      if (amount > 0) {
        final sweepAngle = (amount / totalAmount) * 2 * math.pi;

        final paint = Paint()
          ..color = colors[colorIndex % colors.length]
          ..style = PaintingStyle.fill;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          true,
          paint,
        );

        startAngle += sweepAngle;
        colorIndex++;
      }
    });

    // Donut hole
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}




// Pie chart painter for items breakdown (based on amount)
class ItemsPieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> items;
  final Map<String, int> itemCounts;
  final int totalCount;

  ItemsPieChartPainter({
    required this.items,
    required this.itemCounts,
    required this.totalCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final colors = [
      const Color(0xFF1976D2),
      const Color(0xFF42A5F5),
      const Color(0xFF64B5F6),
      const Color(0xFF90CAF9),
      const Color(0xFFBBDEFB),
    ];

    // Use amounts for pie slices
    final totalAmount = items.fold(0.0, (sum, e) => sum + e.value);
    if (totalAmount == 0) return;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < items.length && i < 5; i++) {
      final item = items[i];
      final sweepAngle = (item.value / totalAmount) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw percentage text for large segments
      final percentage = ((item.value / totalAmount) * 100).round();
      if (percentage >= 15) {
        final textAngle = startAngle + sweepAngle / 2;
        final textRadius = radius * 0.65;
        final textX = center.dx + textRadius * math.cos(textAngle);
        final textY = center.dy + textRadius * math.sin(textAngle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$percentage%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            textX - textPainter.width / 2,
            textY - textPainter.height / 2,
          ),
        );
      }

      startAngle += sweepAngle;
    }

    // Draw center circle (donut style)
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, centerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
