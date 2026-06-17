import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/ocr_scanner_service.dart';

/// Pick receipt → show scanning UI → return [OcrResult].
Future<OcrResult?> showOcrScanFlow(
  BuildContext context, {
  required bool fromCamera,
}) async {
  final file = await OcrScannerService.instance.pickReceipt(
    fromCamera: fromCamera,
  );
  if (file == null || !context.mounted) return OcrResult.cancelled();

  return showModalBottomSheet<OcrResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => OcrScanningSheet(imageFile: file),
  );
}

class OcrScanningSheet extends StatefulWidget {
  final File imageFile;

  const OcrScanningSheet({super.key, required this.imageFile});

  @override
  State<OcrScanningSheet> createState() => _OcrScanningSheetState();
}

class _OcrScanningSheetState extends State<OcrScanningSheet>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF0D5DB8);
  static const _navyLight = Color(0xFF1478E0);
  static const _bg = Color(0xFFF0F4FA);
  static const _border = Color(0xFFE8EDF5);

  static const _steps = [
    'Preparing receipt image',
    'Uploading to AI server',
    'Reading receipt text',
    'Extracting line items',
    'Matching categories',
  ];

  late final AnimationController _pulseController;
  Timer? _stepTimer;
  int _activeStep = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _stepTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted || _activeStep >= _steps.length - 1) return;
      setState(() => _activeStep++);
    });

    _runScan();
  }

  Future<void> _runScan() async {
    final result = await OcrScannerService.instance.scanReceiptFile(
      widget.imageFile,
    );
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Scanning receipt',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This may take up to a minute',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          _ReceiptPreview(
            imageFile: widget.imageFile,
            pulse: _pulseController,
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              backgroundColor: _bg,
              color: _navy,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: List.generate(_steps.length, (i) {
                final done = i < _activeStep;
                final active = i == _activeStep;
                return Padding(
                  padding: EdgeInsets.only(bottom: i < _steps.length - 1 ? 10 : 0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: done
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 22)
                            : active
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _navy,
                                    ),
                                  )
                                : Icon(Icons.circle_outlined,
                                    color: Colors.grey.shade400, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _steps[i],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active
                                ? const Color(0xFF0F172A)
                                : done
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                  CurvedAnimation(
                    parent: _pulseController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_navyLight, _navy],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _steps[_activeStep],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  final File imageFile;
  final AnimationController pulse;

  const _ReceiptPreview({
    required this.imageFile,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.file(
              imageFile,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              return Positioned(
                top: 12 + pulse.value * 120,
                left: 16,
                right: 16,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1478E0).withValues(alpha: 0.85),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1478E0).withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Receipt preview',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
