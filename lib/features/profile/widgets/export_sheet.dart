import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/export_api_service.dart';
import '../../../widgets/app_date_picker.dart';
import 'profile_ui.dart';

enum _ExportFormat { pdf, csv }

/// Bottom sheet — export transactions as PDF or CSV with optional date range.
Future<void> showExportSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ExportSheetContent(),
  );
}

class _ExportSheetContent extends StatefulWidget {
  const _ExportSheetContent();

  @override
  State<_ExportSheetContent> createState() => _ExportSheetContentState();
}

class _ExportSheetContentState extends State<_ExportSheetContent> {
  DateTime? _fromDate;
  DateTime? _toDate;
  _ExportFormat _format = _ExportFormat.pdf;
  bool _isExporting = false;
  String? _errorMessage;

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now().subtract(const Duration(days: 30)))
        : (_toDate ?? DateTime.now());
    final picked = await showAppDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
      _errorMessage = null;
    });
  }

  Future<void> _runExport() async {
    if (_fromDate != null &&
        _toDate != null &&
        _fromDate!.isAfter(_toDate!)) {
      setState(() => _errorMessage = 'Start date must be before end date');
      return;
    }

    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      final service = ExportApiService.instance;
      final ExportResult result;
      if (_format == _ExportFormat.pdf) {
        result = await service.exportToPdf(
          startDate: _fromDate,
          endDate: _toDate,
        );
      } else {
        result = await service.exportToCsv(
          startDate: _fromDate,
          endDate: _toDate,
        );
      }

      if (!mounted) return;

      if (!result.isSuccess ||
          result.fileBytes == null ||
          result.fileName == null) {
        setState(() {
          _isExporting = false;
          _errorMessage = result.message ?? 'Export failed';
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${result.fileName}');
      await file.writeAsBytes(result.fileBytes!);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: result.mimeType)],
          subject: 'Savlet expense report',
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_format == _ExportFormat.pdf ? 'PDF' : 'CSV'} exported successfully',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _errorMessage = 'Export failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Export data',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Download your transactions as PDF or CSV',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Format',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _formatChip(
                        label: 'PDF',
                        icon: Icons.picture_as_pdf_outlined,
                        selected: _format == _ExportFormat.pdf,
                        onTap: () => setState(() => _format = _ExportFormat.pdf),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _formatChip(
                        label: 'CSV',
                        icon: Icons.table_chart_outlined,
                        selected: _format == _ExportFormat.csv,
                        onTap: () => setState(() => _format = _ExportFormat.csv),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Date range (optional)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _dateTile(
                        label: 'From',
                        date: _fromDate,
                        onTap: () => _pickDate(isFrom: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateTile(
                        label: 'To',
                        date: _toDate,
                        onTap: () => _pickDate(isFrom: false),
                      ),
                    ),
                  ],
                ),
                if (_fromDate != null || _toDate != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isExporting
                          ? null
                          : () => setState(() {
                                _fromDate = null;
                                _toDate = null;
                              }),
                      child: const Text('Clear dates'),
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFDC2626),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isExporting ? null : _runExport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProfileColors.navy,
                      disabledBackgroundColor:
                          ProfileColors.navy.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isExporting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Export',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formatChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isExporting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? ProfileColors.navy : ProfileColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? ProfileColors.navy : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: selected ? ProfileColors.navy : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final text = date == null
        ? 'Any'
        : '${date.day}/${date.month}/${date.year}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isExporting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ProfileColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: const Color(0xFF94A3B8))),
                    Text(text,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: ProfileColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}
