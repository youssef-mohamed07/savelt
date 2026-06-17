import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_ui_helpers.dart';

class CategoryListTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final double amount;
  final double share; // 0..1
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAnalysisTap;
  final Color? accentColor;

  const CategoryListTile({
    super.key,
    required this.name,
    required this.icon,
    required this.amount,
    required this.share,
    required this.isDefault,
    required this.onTap,
    this.onDelete,
    this.onAnalysisTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = categoryUiStyle(name);
    final pct = (share * 100).round();
    final barColor = accentColor ?? style.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: BorderRadius.circular(13),
                      border: accentColor != null
                          ? Border.all(
                              color: accentColor!.withValues(alpha: 0.35),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(style.icon, color: style.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pct > 0 ? '$pct% of spending' : 'No spending yet',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amount.toStringAsFixed(0),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
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
                    if (onAnalysisTap != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onAnalysisTap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.insights_outlined,
                              size: 18, color: barColor),
                        ),
                      ),
                    ],
                    if (!isDefault && onDelete != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade400, size: 22),
                  ],
                ),
                if (share > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: share.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF1F5F9),
                      color: barColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
