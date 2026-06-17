import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_api_service.dart';
import '../../profile/bloc/user_bloc.dart';
import '../../profile/bloc/user_state.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_state.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_state.dart';

class HomeDashboardHeader extends StatefulWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onReminders;
  final VoidCallback onCategories;
  final int unreadCount;

  static const _navy = Color(0xFF0D5DB8);
  static const _navyDark = Color(0xFF0A4A94);

  const HomeDashboardHeader({
    super.key,
    required this.onNotificationsTap,
    required this.onReminders,
    required this.onCategories,
    this.unreadCount = 0,
  });

  @override
  State<HomeDashboardHeader> createState() => _HomeDashboardHeaderState();
}

class _HomeDashboardHeaderState extends State<HomeDashboardHeader> {
  bool _hideBalance = false;

  String _greetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        return BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, analytics) {
            return BlocBuilder<ExpenseBloc, ExpenseState>(
              builder: (context, expenseState) {
                final auth = AuthApiService.instance;
                final displayName =
                    auth.currentUser?.displayName ?? userState.name;
                final firstName =
                    (displayName.isEmpty ? 'User' : displayName).split(' ').first;

                var total = analytics.totalAmount;
                if (total <= 0 && expenseState is ExpenseLoaded) {
                  total = expenseState.totalExpenses;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $firstName 👋',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _greetingSubtitle(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _NotificationButton(
                          unreadCount: widget.unreadCount,
                          onTap: widget.onNotificationsTap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _BalanceCard(
                      total: total,
                      hidden: _hideBalance,
                      onToggleVisibility: () {
                        setState(() => _hideBalance = !_hideBalance);
                      },
                      onCategories: widget.onCategories,
                      onReminders: widget.onReminders,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double total;
  final bool hidden;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCategories;
  final VoidCallback onReminders;

  const _BalanceCard({
    required this.total,
    required this.hidden,
    required this.onToggleVisibility,
    required this.onCategories,
    required this.onReminders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeDashboardHeader._navy, HomeDashboardHeader._navyDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: HomeDashboardHeader._navy.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total Spending',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggleVisibility();
                },
                child: Icon(
                  hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hidden ? '••••••' : _formatAmount(total),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          if (!hidden) ...[
            const SizedBox(height: 2),
            Text(
              'EGP',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _BalanceShortcut(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Categories',
                  subtitle: 'Track spending',
                  onTap: onCategories,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceShortcut(
                  icon: Icons.notifications_active_rounded,
                  label: 'Reminders',
                  subtitle: 'Bills & alerts',
                  onTap: onReminders,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double v) {
    final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    final parts = s.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    if (parts.length > 1 && parts[1] != '0' && parts[1] != '00') {
      return '$buf.${parts[1]}';
    }
    return buf.toString();
  }
}

class _BalanceShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _BalanceShortcut({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationButton({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 20),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
