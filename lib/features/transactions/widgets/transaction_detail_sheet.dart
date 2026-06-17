import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../utils/transaction_ui_helpers.dart';

Future<void> showTransactionDetailSheet(
  BuildContext context, {
  required TransactionModel transaction,
  required VoidCallback onDelete,
}) {
  final style = categoryStyle(transaction.category);
  final category = displayCategory(transaction.category);
  final isIncome = transaction.isIncome;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(style.icon, color: style.color, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  transaction.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} EGP',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _DetailRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: category,
          ),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: formatFullDate(transaction.date),
          ),
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: formatTime(transaction.date),
          ),
          _DetailRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Type',
            value: isIncome ? 'Income' : 'Expense',
          ),
          if (transaction.description.trim().isNotEmpty)
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Notes',
              value: transaction.description,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: Text(
                  'Delete transaction',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
