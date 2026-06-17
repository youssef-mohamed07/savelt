import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import 'bloc/transaction_bloc.dart';
import 'bloc/transaction_event.dart';
import 'bloc/transaction_state.dart';
import 'models/transaction_model.dart';
import 'utils/transaction_ui_helpers.dart';
import 'widgets/transaction_detail_sheet.dart';
import 'widgets/transaction_tile.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const _navy = Color(0xFF0D5DB8);
  static const _navyDark = Color(0xFF0A4A94);

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionBloc>().add(const LoadTransactions());
      }
    });
  }

  List<TransactionModel> _filter(List<TransactionModel> items) {
    if (_searchQuery.trim().isEmpty) return items;
    final q = _searchQuery.trim().toLowerCase();
    return items.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q);
    }).toList();
  }

  void _deleteTransaction(TransactionModel t) {
    context.read<TransactionBloc>().add(DeleteTransaction(t.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${t.title}"'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            if (state.isLoading) return _buildLoadingState();

            final all = _filter(state.transactions);
            if (state.transactions.isEmpty) return _buildEmptyState();

            final totalSpent = sumExpenses(all);
            final groups = groupTransactionsByDay(all);
            final now = DateTime.now();
            final thisMonth = all.where((t) =>
                t.date.year == now.year && t.date.month == now.month).length;

            return RefreshIndicator(
              color: _navy,
              onRefresh: () async {
                context.read<TransactionBloc>().add(const LoadTransactions());
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(all.length)),
                  SliverToBoxAdapter(
                    child: _buildSummaryCard(
                      totalSpent: totalSpent,
                      count: all.length,
                      monthCount: thisMonth,
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  if (all.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildNoResults(),
                    )
                  else
                    ...groups.expand((group) => [
                          SliverToBoxAdapter(child: _buildSectionHeader(group.key, group.value)),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final t = group.value[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Dismissible(
                                      key: Key('tx_${t.id}_${group.key}_$index'),
                                      direction: DismissDirection.endToStart,
                                      background: _buildDismissBackground(),
                                      onDismissed: (_) => _deleteTransaction(t),
                                      child: TransactionTile(
                                        transaction: t,
                                        onTap: () => showTransactionDetailSheet(
                                          context,
                                          transaction: t,
                                          onDelete: () => _deleteTransaction(t),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: group.value.length,
                              ),
                            ),
                          ),
                        ]),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ACTIVITY',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transactions',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count recorded · ${monthYearLabel(DateTime.now())}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.receipt_long_rounded, color: _navy, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required double totalSpent,
    required int count,
    required int monthCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_navy, _navyDark],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.35),
              blurRadius: 20,
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
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalSpent.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'EGP',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _SummaryStat(
                  label: 'Transactions',
                  value: count.toString(),
                ),
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                _SummaryStat(
                  label: 'This month',
                  value: monthCount.toString(),
                ),
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                _SummaryStat(
                  label: 'Average',
                  value: count > 0
                      ? (totalSpent / count).toStringAsFixed(0)
                      : '0',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by name or category…',
            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, List<TransactionModel> items) {
    final dayTotal = sumExpenses(items);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Text(
            '-${dayTotal.toStringAsFixed(2)} EGP',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No matches found',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => EmptyStates.noTransactions(onAddTransaction: () {});

  Widget _buildLoadingState() => CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 180,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: SkeletonLoaders.transactionList(itemCount: 6),
            ),
          ),
        ],
      );
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
