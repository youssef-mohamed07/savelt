import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A clean daily spending line chart.
/// X-axis = dates, Y-axis = amount per day (zigzag, NOT cumulative).
/// Supports tap-to-tooltip and real-time updates via analyticsData.
class SpendingLineChart extends StatefulWidget {
  /// Backend analytics data: {"2026-04-17": 100.0, "2026-04-18": 300.0}
  final Map<String, double> analyticsData;

  /// Optional date filter
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Called when user taps a point — passes the date key (e.g. "2026-04-28")
  final void Function(String dateKey)? onDayTapped;

  const SpendingLineChart({
    super.key,
    required this.analyticsData,
    this.fromDate,
    this.toDate,
    this.onDayTapped,
  });

  @override
  State<SpendingLineChart> createState() => _SpendingLineChartState();
}

class _SpendingLineChartState extends State<SpendingLineChart> {
  int? _tappedIndex;

  // ── Data preparation ────────────────────────────────────────────────────────

  List<_ChartPoint> _buildPoints() {
    if (widget.analyticsData.isEmpty) return [];

    // Sort entries by key ascending
    final entries = widget.analyticsData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Apply date filter
    final filtered = entries.where((e) {
      try {
        final parts = e.key.split('-');
        DateTime date;
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else if (parts.length == 2) {
          date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
        } else {
          date = DateTime(int.parse(parts[0]), 1, 1);
        }

        if (widget.fromDate != null) {
          final from = DateTime(widget.fromDate!.year, widget.fromDate!.month, widget.fromDate!.day);
          if (date.isBefore(from)) return false;
        }
        if (widget.toDate != null) {
          final to = DateTime(widget.toDate!.year, widget.toDate!.month, widget.toDate!.day, 23, 59, 59);
          if (date.isAfter(to)) return false;
        }
        return true;
      } catch (_) {
        return true;
      }
    }).toList();

    // If BOTH dates are set and range is ≤ 60 days → fill missing days with 0
    // Also fill gaps when no filter but data is daily and range ≤ 60 days
    final DateTime? effectiveFrom = widget.fromDate;
    final DateTime? effectiveTo = widget.toDate;

    // Determine if we should fill gaps
    bool shouldFillGaps = false;
    DateTime? fillFrom;
    DateTime? fillTo;

    if (effectiveFrom != null && effectiveTo != null &&
        effectiveTo.difference(effectiveFrom).inDays <= 60) {
      // User set a filter ≤ 60 days
      shouldFillGaps = true;
      fillFrom = DateTime(effectiveFrom.year, effectiveFrom.month, effectiveFrom.day);
      fillTo = DateTime(effectiveTo.year, effectiveTo.month, effectiveTo.day);
    } else if (effectiveFrom == null && effectiveTo == null && filtered.isNotEmpty) {
      // No filter — fill gaps between first and last data point if ≤ 60 days
      final isDaily = filtered.first.key.split('-').length == 3;
      if (isDaily) {
        try {
          final firstParts = filtered.first.key.split('-');
          final lastParts = filtered.last.key.split('-');
          final firstDate = DateTime(int.parse(firstParts[0]), int.parse(firstParts[1]), int.parse(firstParts[2]));
          final lastDate = DateTime(int.parse(lastParts[0]), int.parse(lastParts[1]), int.parse(lastParts[2]));
          if (lastDate.difference(firstDate).inDays <= 60) {
            shouldFillGaps = true;
            fillFrom = firstDate;
            fillTo = lastDate;
          }
        } catch (_) {}
      }
    }

    if (shouldFillGaps && fillFrom != null && fillTo != null) {
      final isDaily = filtered.isNotEmpty
          ? filtered.first.key.split('-').length == 3
          : true;
      if (isDaily) {
        final dataMap = {for (final e in filtered) e.key: e.value};
        final allDays = <MapEntry<String, double>>[];
        for (var d = fillFrom; !d.isAfter(fillTo); d = d.add(const Duration(days: 1))) {
          final key =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          allDays.add(MapEntry(key, dataMap[key] ?? 0.0));
        }
        return allDays
            .map((e) => _ChartPoint(
                  dateKey: e.key,
                  label: _formatLabel(e.key),
                  amount: e.value,
                ))
            .toList();
      }
    }

    return filtered.map((e) {
      final label = _formatLabel(e.key);
      return _ChartPoint(dateKey: e.key, label: label, amount: e.value);
    }).toList();
  }

  /// Format key to readable label based on format
  String _formatLabel(String key) {
    final parts = key.split('-');
    if (parts.length == 3) {
      // Daily: "2026-04-17" → "17/4"
      return '${int.parse(parts[2])}/${int.parse(parts[1])}';
    } else if (parts.length == 2) {
      // Monthly: "2026-04" → "Apr"
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final m = int.tryParse(parts[1]) ?? 1;
      return months[(m - 1).clamp(0, 11)];
    } else {
      // Yearly: "2026" → "2026"
      return key;
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();

    // Need at least 2 points to draw a line
    if (points.isEmpty || points.length < 2) {
      // If only 1 point, show it as a single dot with label
      if (points.length == 1) {
        return _buildSinglePoint(points.first);
      }
      return _buildEmpty();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              _selectNearest(details.localPosition, points, constraints.maxWidth),
          onHorizontalDragStart: (details) =>
              _selectNearest(details.localPosition, points, constraints.maxWidth),
          onHorizontalDragUpdate: (details) =>
              _selectNearest(details.localPosition, points, constraints.maxWidth),
          child: CustomPaint(
            size: Size(constraints.maxWidth, 245),
            painter: _LinePainter(
              points: points,
              tappedIndex: _tappedIndex,
            ),
          ),
        );
      },
    );
  }

  void _selectNearest(Offset pos, List<_ChartPoint> points, double width) {
    if (points.length < 2) return;

    const chartLeft = _LinePainter.leftPad;
    const chartRight = _LinePainter.rightPad;
    final chartWidth = width - chartLeft - chartRight;
    final step = chartWidth / (points.length - 1);

    int? closest;
    double minDist = double.infinity;
    for (int i = 0; i < points.length; i++) {
      final x = chartLeft + step * i;
      final dist = (pos.dx - x).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = i;
      }
    }

    if (closest != null && minDist < 34) {
      if (_tappedIndex != closest) {
        setState(() => _tappedIndex = closest);
        widget.onDayTapped?.call(points[closest].dateKey);
      }
    } else if (_tappedIndex != null) {
      setState(() => _tappedIndex = null);
      widget.onDayTapped?.call('');
    }
  }

  Widget _buildEmpty() {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            'No spending data yet',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePoint(_ChartPoint point) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF1478E0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            point.label,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatAmt(point.amount)} EGP',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1478E0),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmt(double amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toInt().toString();
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _ChartPoint {
  final String dateKey;
  final String label;
  final double amount;
  const _ChartPoint(
      {required this.dateKey, required this.label, required this.amount});
}

// ── Painter ────────────────────────────────────────────────────────────────────

class _LinePainter extends CustomPainter {
  final List<_ChartPoint> points;
  final int? tappedIndex;

  static const double leftPad = 50;
  static const double rightPad = 16;
  static const double _topPad = 30;
  static const double _bottomPad = 40;

  _LinePainter({required this.points, this.tappedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - _topPad - _bottomPad;

    final maxAmt = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);

    // ── Grid lines ────────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = _topPad + chartH * i / gridLines;
      canvas.drawLine(
          Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      // Y-axis label
      final labelAmt = maxAmt * (1 - i / gridLines);
      _drawText(
        canvas,
        _formatAmount(labelAmt),
        Offset(0, y - 7),
        const Color(0xFF9CA3AF),
        10,
        width: leftPad - 4,
        align: TextAlign.right,
      );
    }

    // ── Calculate pixel positions ─────────────────────────────────────────────
    final step = points.length > 1 ? chartW / (points.length - 1) : chartW;

    List<Offset> offsets = [];
    for (int i = 0; i < points.length; i++) {
      final x = leftPad + step * i;
      final normalized = maxAmt > 0 ? points[i].amount / maxAmt : 0.0;
      final y = _topPad + chartH * (1 - normalized);
      offsets.add(Offset(x, y));
    }

    // ── Fill area under line ──────────────────────────────────────────────────
    final fillPath = Path()..moveTo(offsets.first.dx, _topPad + chartH);
    for (int i = 0; i < offsets.length; i++) {
      if (i == 0) {
        fillPath.lineTo(offsets[i].dx, offsets[i].dy);
      } else {
        final cp1 = Offset(
          offsets[i - 1].dx + (offsets[i].dx - offsets[i - 1].dx) * 0.5,
          offsets[i - 1].dy,
        );
        final cp2 = Offset(
          offsets[i].dx - (offsets[i].dx - offsets[i - 1].dx) * 0.5,
          offsets[i].dy,
        );
        fillPath.cubicTo(
            cp1.dx, cp1.dy, cp2.dx, cp2.dy, offsets[i].dx, offsets[i].dy);
      }
    }
    fillPath.lineTo(offsets.last.dx, _topPad + chartH);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF1478E0).withValues(alpha: 0.2),
            const Color(0xFF1478E0).withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, _topPad, size.width, chartH)),
    );

    // ── Line ──────────────────────────────────────────────────────────────────
    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      final cp1 = Offset(
        offsets[i - 1].dx + (offsets[i].dx - offsets[i - 1].dx) * 0.5,
        offsets[i - 1].dy,
      );
      final cp2 = Offset(
        offsets[i].dx - (offsets[i].dx - offsets[i - 1].dx) * 0.5,
        offsets[i].dy,
      );
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, offsets[i].dx, offsets[i].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF1478E0)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── Dots + X labels ───────────────────────────────────────────────────────
    for (int i = 0; i < offsets.length; i++) {
      final o = offsets[i];
      final isSelected = tappedIndex == i;

      if (isSelected) {
        canvas.drawCircle(
          o,
          14,
          Paint()..color = const Color(0xFF1478E0).withValues(alpha: 0.14),
        );
      }
      canvas.drawCircle(o, isSelected ? 8 : 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        o,
        isSelected ? 5.5 : 3.5,
        Paint()..color = const Color(0xFF1478E0),
      );

      // X-axis label — smart spacing to avoid crowding
      final bool showLabel;
      if (points.length <= 5) {
        showLabel = true; // show all if few points
      } else if (points.length <= 10) {
        showLabel = i == 0 || i == points.length - 1 || i % 2 == 0;
      } else {
        // show first, last, and evenly spaced labels (max ~5 labels)
        final step2 = (points.length / 4).ceil();
        showLabel = i == 0 || i == points.length - 1 || i % step2 == 0;
      }
      if (showLabel) {
        _drawText(
          canvas,
          points[i].label,
          Offset(o.dx - 20, size.height - _bottomPad + 8),
          const Color(0xFF6B7280),
          10,
          width: 40,
          align: TextAlign.center,
        );
      }

      // Tooltip for tapped point
      if (isSelected) {
        _drawTooltip(canvas, o, points[i], size);
      }
    }
  }

  void _drawTooltip(Canvas canvas, Offset point, _ChartPoint p, Size size) {
    const tooltipW = 90.0;
    const tooltipH = 44.0;
    const radius = 8.0;

    // Position tooltip above the dot, keep within bounds
    double tx = point.dx - tooltipW / 2;
    tx = tx.clamp(leftPad, (size.width - rightPad - tooltipW).clamp(leftPad, double.infinity));
    
    // Ensure min <= max for vertical clamp
    final tyMin = _topPad - 10.0;
    final tyMax = (point.dy - 50.0).clamp(tyMin, double.infinity);
    final ty = (point.dy - tooltipH - 12).clamp(tyMin, tyMax);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tx, ty, tooltipW, tooltipH),
      const Radius.circular(radius),
    );

    // Shadow
    canvas.drawRRect(
      rect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Background
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF1E3A5F));

    // Arrow
    final arrowPath = Path()
      ..moveTo(point.dx - 6, ty + tooltipH)
      ..lineTo(point.dx, ty + tooltipH + 8)
      ..lineTo(point.dx + 6, ty + tooltipH)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xFF1E3A5F));

    // Date text
    _drawText(
      canvas,
      p.label,
      Offset(tx + 8, ty + 6),
      Colors.white.withValues(alpha: 0.75),
      10,
      width: tooltipW - 16,
    );

    // Amount text
    _drawText(
      canvas,
      '${_formatAmount(p.amount)} EGP',
      Offset(tx + 8, ty + 22),
      Colors.white,
      13,
      width: tooltipW - 16,
      bold: true,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize, {
    double width = 100,
    TextAlign align = TextAlign.left,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    tp.paint(canvas, offset);
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toInt().toString();
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points.length != points.length ||
      old.tappedIndex != tappedIndex ||
      (points.isNotEmpty &&
          old.points.isNotEmpty &&
          old.points.last.amount != points.last.amount);
}
