import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReminderColors {
  static const navy = Color(0xFF0D5DB8);
  static const navyDark = Color(0xFF0A4A94);
  static const bg = Color(0xFFF0F4FA);
  static const border = Color(0xFFE8EDF5);
  static const green = Color(0xFF10B981);
}

String formatReminderDate(DateTime date) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final dateOnly = DateTime(date.year, date.month, date.day);
  final todayOnly = DateTime(now.year, now.month, now.day);
  final tomorrowOnly = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

  String dayStr;
  if (dateOnly == todayOnly) {
    dayStr = 'Today';
  } else if (dateOnly == tomorrowOnly) {
    dayStr = 'Tomorrow';
  } else {
    dayStr = '${date.day}/${date.month}';
  }

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$dayStr, $hour:$minute';
}

Color reminderIconColor(IconData icon, {required bool enabled}) {
  if (!enabled) return const Color(0xFF94A3B8);
  if (icon == Icons.bolt_rounded) return const Color(0xFFF59E0B);
  if (icon == Icons.home_rounded) return ReminderColors.navy;
  if (icon == Icons.tv_rounded) return const Color(0xFF7C3AED);
  if (icon == Icons.shopping_cart_rounded) return const Color(0xFF059669);
  return ReminderColors.navy;
}

Color reminderIconBg(IconData icon, {required bool enabled}) {
  return reminderIconColor(icon, enabled: enabled).withValues(alpha: enabled ? 0.12 : 0.08);
}

const reminderIconOptions = [
  Icons.notifications_rounded,
  Icons.bolt_rounded,
  Icons.home_rounded,
  Icons.tv_rounded,
  Icons.shopping_cart_rounded,
  Icons.phone_android_rounded,
  Icons.wifi_rounded,
  Icons.water_drop_rounded,
  Icons.local_gas_station_rounded,
  Icons.credit_card_rounded,
  Icons.school_rounded,
  Icons.medical_services_rounded,
];

class ReminderPageHeader extends StatelessWidget {
  final VoidCallback onBack;
  final Widget? trailing;

  const ReminderPageHeader({
    super.key,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ReminderColors.border),
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
                    color: ReminderColors.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'BILL ALERTS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: ReminderColors.navy,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reminders',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class ReminderSummaryCard extends StatelessWidget {
  final int activeCount;
  final int totalCount;
  final int upcomingCount;

  const ReminderSummaryCard({
    super.key,
    required this.activeCount,
    required this.totalCount,
    required this.upcomingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ReminderColors.navy, ReminderColors.navyDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ReminderColors.navy.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _stat('Active', '$activeCount', Icons.notifications_active_rounded),
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
          Expanded(
            child: _stat('Total', '$totalCount', Icons.list_alt_rounded),
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
          Expanded(
            child: _stat('Upcoming', '$upcomingCount', Icons.schedule_rounded),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
