import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/bloc/expense_bloc.dart';
import '../home/bloc/expense_state.dart';
import '../home/bloc/expense_event.dart';
import '../../core/models/expense.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/dialogs/manual_entry_dialog.dart';
import '../../widgets/dialogs/simple_voice_dialog.dart';
import '../categories/bloc/category_bloc.dart';
import '../categories/widgets/category_ui_helpers.dart';
import '../transactions/utils/transaction_ui_helpers.dart';

/// Category detail — items & spending for one category (Shopping, Bills, …).
class ItemsPage extends StatelessWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;

  const ItemsPage({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return _ItemsPageContent(
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
    );
  }
}

class _ItemsPageContent extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;

  const _ItemsPageContent({
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  State<_ItemsPageContent> createState() => _ItemsPageContentState();
}

class _ItemsPageContentState extends State<_ItemsPageContent>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF0D5DB8);
  static const _navyLight = Color(0xFF1478E0);
  static const _expenseRed = Color(0xFFDC2626);

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedItemName;
  bool _showFloatingOptions = false;

  late final CategoryUiStyle _style;
  late AnimationController _menuController;
  late Animation<double> _menuFade;
  late Animation<double> _menuScale;

  @override
  void initState() {
    super.initState();
    _style = categoryUiStyle(widget.categoryName);
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _menuFade = CurvedAnimation(parent: _menuController, curve: Curves.easeOut);
    _menuScale = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggleAddMenu() {
    HapticFeedback.lightImpact();
    if (_showFloatingOptions) {
      _closeAddMenu();
    } else {
      setState(() => _showFloatingOptions = true);
      _menuController.forward(from: 0);
    }
  }

  void _closeAddMenu() {
    if (!_showFloatingOptions) return;
    _menuController.reverse().then((_) {
      if (mounted) setState(() => _showFloatingOptions = false);
    });
  }

  bool get _isDateFiltered => _fromDate != null || _toDate != null;

  List<Expense> _filterExpenses(List<Expense> raw) {
    var items = raw.where((e) =>
        e.category.toLowerCase() == widget.categoryName.toLowerCase()).toList();

    if (_fromDate != null) {
      final from = dateOnly(_fromDate!);
      items = items.where((e) => !dateOnly(e.date).isBefore(from)).toList();
    }
    if (_toDate != null) {
      final to = dateOnly(_toDate!);
      items = items.where((e) => !dateOnly(e.date).isAfter(to)).toList();
    }
    if (_selectedItemName != null) {
      items = items.where((e) => e.title == _selectedItemName).toList();
    }
    return items;
  }

  void _onBarTap(String itemName) {
    setState(() {
      _selectedItemName = _selectedItemName == itemName ? null : itemName;
    });
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  Future<void> _pickFromDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      title: 'From date',
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime(2100),
      title: 'To date',
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocBuilder<ExpenseBloc, ExpenseState>(
                    builder: (context, state) {
                      final all = state is ExpenseLoaded
                          ? _filterExpenses(state.expenses)
                          : <Expense>[];

                      final total = all.fold(0.0, (s, e) => s + e.amount);
                      final chartData = _chartDataFrom(all);

                      return RefreshIndicator(
                        color: _navy,
                        onRefresh: () async {
                          // ExpenseBloc auto-loads; brief delay for UX
                          await Future.delayed(const Duration(milliseconds: 400));
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          children: [
                            _buildSummaryCard(total, all.length),
                            const SizedBox(height: 14),
                            _buildDateRow(),
                            if (_isDateFiltered) ...[
                              const SizedBox(height: 8),
                              _buildClearFilter(),
                            ],
                            const SizedBox(height: 16),
                            _buildChartSection(chartData),
                            if (_selectedItemName != null) ...[
                              const SizedBox(height: 10),
                              _buildFilterChip(),
                            ],
                            const SizedBox(height: 20),
                            _buildSectionTitle(all.length),
                            const SizedBox(height: 10),
                            if (all.isEmpty)
                              _buildEmpty()
                            else
                              ...all.map(_buildDismissibleItem),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: _buildFab(),
            ),
            if (_showFloatingOptions)
              Positioned.fill(child: _buildAddMenuOverlay()),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _chartDataFrom(List<Expense> expenses) {
    final amounts = <String, double>{};
    final quantities = <String, int>{};
    for (final e in expenses) {
      amounts[e.title] = (amounts[e.title] ?? 0) + e.amount;
      quantities[e.title] = (quantities[e.title] ?? 0) + e.quantity;
    }
    final data = amounts.entries
        .map((e) => {
              'item': e.key,
              'amount': e.value,
              'quantity': quantities[e.key] ?? 1,
            })
        .toList()
      ..sort((a, b) =>
          (b['amount'] as double).compareTo(a['amount'] as double));
    return data.take(5).toList();
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF0F172A),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _style.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _style.color.withValues(alpha: 0.15)),
            ),
            child: Icon(_style.icon, color: _style.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.categoryName,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total spent',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                total.toStringAsFixed(2),
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'EGP',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count transaction${count == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(child: _dateChip('From', _fromDate, _pickFromDate)),
        const SizedBox(width: 10),
        Expanded(child: _dateChip('To', _toDate, _pickToDate)),
      ],
    );
  }

  Widget _dateChip(String label, DateTime? date, VoidCallback onTap) {
    final active = date != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? _navy : const Color(0xFFE8EDF5),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: active ? _navy : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
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
                        ),
                      ),
                      Text(
                        active ? formatDisplayDate(date) : 'Any',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active ? _navy : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearFilter() {
    return GestureDetector(
      onTap: _clearDateFilter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
            const SizedBox(width: 6),
            Text(
              'Clear date filter',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(List<Map<String, dynamic>> chartData) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top items by spend',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a bar to filter the list',
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          if (chartData.isEmpty)
            _buildChartEmpty()
          else
            _VerticalColumnChart(
              data: chartData,
              selectedItem: _selectedItemName,
              onTap: _onBarTap,
            ),
        ],
      ),
    );
  }

  Widget _buildChartEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Spending breakdown appears here',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filtered: $_selectedItemName',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _selectedItemName = null),
            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(int count) {
    return Row(
      children: [
        Text(
          'Transactions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        if (count > 0)
          Text(
            '$count item${count == 1 ? '' : 's'}',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _style.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_style.icon, color: _style.color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            _selectedItemName != null
                ? 'No "$_selectedItemName" items'
                : 'No ${widget.categoryName} items yet',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + below to add your first expense',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleItem(Expense expense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Delete item?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              content: Text(
                'Remove "${expense.title}" from ${widget.categoryName}?',
                style: GoogleFonts.inter(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) {
          context.read<ExpenseBloc>().add(DeleteExpense(expense.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${expense.title}" deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: _buildItemTile(expense),
      ),
    );
  }

  Widget _buildItemTile(Expense expense) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _style.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_style.icon, color: _style.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _style.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.categoryName,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _style.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(expense.date),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${expense.amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _expenseRed,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'EGP',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (dateOnly(date) == dateOnly(now)) return 'Today · ${formatTime(date)}';
    return '${date.day}/${date.month} · ${formatTime(date)}';
  }

  Widget _buildFab() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: GestureDetector(
          onTap: _toggleAddMenu,
          behavior: HitTestBehavior.opaque,
          child: AnimatedRotation(
            turns: _showFloatingOptions ? 0.125 : 0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _showFloatingOptions
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [_navyLight, _navy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_showFloatingOptions ? const Color(0xFFEF4444) : _navy)
                        .withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: _showFloatingOptions ? 30 : 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddMenuOverlay() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return FadeTransition(
      opacity: _menuFade,
      child: GestureDetector(
        onTap: _closeAddMenu,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: Stack(
            children: [
              Positioned(
                bottom: bottomInset + 100,
                left: MediaQuery.of(context).size.width / 2 - 98,
                child: ScaleTransition(
                  scale: _menuScale,
                  child: _FloatingAddOption(
                    icon: Icons.edit_rounded,
                    label: 'Manual',
                    color: _navy,
                    onTap: () async {
                      _closeAddMenu();
                      final result = await showManualEntryDialog(
                        context,
                        initialCategory: widget.categoryName,
                      );
                      if (result != null && mounted) {
                        context.read<ExpenseBloc>().add(AddExpense(Expense(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: result['title'] as String,
                          amount: result['amount'] as double,
                          category: result['category'] as String,
                          date: result['date'] as DateTime,
                          quantity: result['quantity'] as int? ?? 1,
                        )));
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: bottomInset + 100,
                right: MediaQuery.of(context).size.width / 2 - 98,
                child: ScaleTransition(
                  scale: _menuScale,
                  child: _FloatingAddOption(
                    icon: Icons.mic_rounded,
                    label: 'Voice',
                    color: _navyLight,
                    onTap: () {
                      _closeAddMenu();
                      showSimpleVoiceSheet(
                        context,
                        expenseBloc: context.read<ExpenseBloc>(),
                        categoryBloc: context.read<CategoryBloc>(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingAddOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FloatingAddOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalColumnChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String? selectedItem;
  final ValueChanged<String> onTap;

  static const _barAreaHeight = 132.0;
  static const _barWidth = 20.0;
  static const _nameRowHeight = 36.0;
  static const _labelSpace = 18.0;

  const _VerticalColumnChart({
    required this.data,
    required this.selectedItem,
    required this.onTap,
  });

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount >= 10000 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final maxAmount = data.first['amount'] as double;

    return SizedBox(
      height: _barAreaHeight + _nameRowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(data.length, (i) {
          final item = data[i];
          final name = item['item'] as String;
          final amount = item['amount'] as double;
          final qty = item['quantity'] as int? ?? 1;
          final isSelected = selectedItem == name;
          final color = isSelected
              ? const Color(0xFF059669)
              : categoryChartColors[i % categoryChartColors.length];

          final maxBar = _barAreaHeight - _labelSpace;
          final fraction = data.length == 1
              ? 1.0
              : (maxAmount > 0 ? (amount / maxAmount).clamp(0.12, 1.0) : 1.0);
          final barHeight = maxBar * fraction;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(name),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 2,
                  right: i == data.length - 1 ? 0 : 2,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: _barAreaHeight,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            left: 4,
                            right: 4,
                            bottom: 0,
                            child: Container(
                              height: 1,
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              height: barHeight,
                              width: _barWidth,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.7)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5),
                                ),
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xFF059669),
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: barHeight + 4,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${_formatAmount(amount)} EGP · ×$qty',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF475569),
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: _nameRowHeight,
                      child: Center(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF059669)
                                : const Color(0xFF64748B),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
