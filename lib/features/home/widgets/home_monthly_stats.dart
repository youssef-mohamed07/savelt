import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../transactions/bloc/transaction_bloc.dart';
import '../../transactions/bloc/transaction_state.dart';

class HomeMonthlyStats extends StatelessWidget {
  const HomeMonthlyStats({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final now = DateTime.now();
        final monthTx = state.transactions.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        });

        var income = 0.0;
        var expenses = 0.0;
        for (final t in monthTx) {
          if (t.isIncome) {
            income += t.amount;
          } else {
            expenses += t.amount;
          }
        }
        final saved = income - expenses;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Income',
                value: income,
                icon: Icons.arrow_downward_rounded,
                iconColor: const Color(0xFF059669),
                iconBg: const Color(0xFFECFDF5),
                valueColor: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Expenses',
                value: expenses,
                icon: Icons.arrow_upward_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEF2F2),
                valueColor: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Saved',
                value: saved.abs(),
                icon: Icons.savings_outlined,
                iconColor: const Color(0xFF0D5DB8),
                iconBg: const Color(0xFFEFF6FF),
                valueColor: saved >= 0
                    ? const Color(0xFF0D5DB8)
                    : const Color(0xFFDC2626),
                prefix: saved < 0 ? '-' : '',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color valueColor;
  final String prefix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.valueColor,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D5DB8).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$prefix${_format(value)}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
