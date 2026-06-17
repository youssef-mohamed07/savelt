import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Add Options Bottom Sheet - Shows Voice, Manual, Scan options
class AddOptionsBottomSheet extends StatelessWidget {
  final String? categoryName;
  final VoidCallback? onManualTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onScanTap;
  final bool showScan; // Option to hide scan

  const AddOptionsBottomSheet({
    super.key,
    this.categoryName,
    this.onManualTap,
    this.onVoiceTap,
    this.onScanTap,
    this.showScan = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            categoryName != null ? 'Add to $categoryName' : 'Add Expense',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D5DB8),
            ),
          ),
          const SizedBox(height: 24),

          // Options Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                context,
                icon: Icons.edit_rounded,
                label: 'Manual',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  onManualTap?.call();
                },
              ),
              _buildOption(
                context,
                icon: Icons.mic_rounded,
                label: 'Voice',
                color: const Color(0xFFFF9800),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  onVoiceTap?.call();
                },
              ),
              if (showScan)
                _buildOption(
                  context,
                  icon: Icons.camera_alt_rounded,
                  label: 'Scan',
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    onScanTap?.call();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show Add Options Bottom Sheet
void showAddOptionsBottomSheet(
  BuildContext context, {
  String? categoryName,
  VoidCallback? onManualTap,
  VoidCallback? onVoiceTap,
  VoidCallback? onScanTap,
  bool showScan = true,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => AddOptionsBottomSheet(
      categoryName: categoryName,
      onManualTap: onManualTap,
      onVoiceTap: onVoiceTap,
      onScanTap: onScanTap,
      showScan: showScan,
    ),
  );
}


