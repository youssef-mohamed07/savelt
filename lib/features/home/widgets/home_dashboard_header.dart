import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_api_service.dart';
import '../../profile/bloc/user_bloc.dart';
import '../../profile/bloc/user_state.dart';

class HomeDashboardHeader extends StatelessWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onReminders;
  final VoidCallback onCategories;
  final int unreadCount;

  static const _navy = Color(0xFF0D5DB8);
  static const _navyLight = Color(0xFF1478E0);

  const HomeDashboardHeader({
    super.key,
    required this.onNotificationsTap,
    required this.onReminders,
    required this.onCategories,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        final auth = AuthApiService.instance;
        final displayName = auth.currentUser?.displayName ?? userState.name;
        final firstName =
            (displayName.isEmpty ? 'User' : displayName).split(' ').first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingCard(
              firstName: firstName,
              unreadCount: unreadCount,
              onNotificationsTap: onNotificationsTap,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.notifications_active_outlined,
                    label: 'Reminders',
                    subtitle: 'Bills & alerts',
                    color: _navy,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onReminders();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.grid_view_rounded,
                    label: 'Categories',
                    subtitle: 'Track spending',
                    color: _navyLight,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onCategories();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String firstName;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  const _GreetingCard({
    required this.firstName,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: HomeDashboardHeader._navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HomeDashboardHeader._navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DASHBOARD',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: HomeDashboardHeader._navy,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              _NotificationButton(
                unreadCount: unreadCount,
                onTap: onNotificationsTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hi, $firstName 👋',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Smart spending leads to bright savings',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDF5)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: HomeDashboardHeader._navy,
              size: 21,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
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
