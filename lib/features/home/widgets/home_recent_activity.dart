import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../transactions/bloc/transaction_bloc.dart';
import '../../transactions/bloc/transaction_state.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/widgets/transaction_tile.dart';

class HomeRecentActivity extends StatelessWidget {
  final VoidCallback onViewAll;

  static const _navy = Color(0xFF0D5DB8);

  const HomeRecentActivity({
    super.key,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final recent = _recentTransactions(state.transactions);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onViewAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View all',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, color: _navy, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoading && recent.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (recent.isEmpty)
              _buildEmpty()
            else
              Column(
                children: [
                  for (var i = 0; i < recent.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i < recent.length - 1 ? 10 : 0),
                      child: TransactionTile(transaction: recent[i]),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  List<TransactionModel> _recentTransactions(List<TransactionModel> all) {
    final sorted = List<TransactionModel>.from(all)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(4).toList();
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No activity yet',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
