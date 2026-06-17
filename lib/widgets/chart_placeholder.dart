import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Chart Placeholder Widget
/// Shows when no data exists - indicates charts will appear after adding items
class ChartPlaceholder extends StatelessWidget {
  final String title;
  final double height;
  final ChartPlaceholderType type;

  const ChartPlaceholder({
    super.key,
    this.title = 'Your Spending Overview',
    this.height = 240,
    this.type = ChartPlaceholderType.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D5DB8).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 24),
          _buildPlaceholderContent(),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    // For pie chart, show simpler content
    if (type == ChartPlaceholderType.pie) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPiePlaceholder(),
            const SizedBox(height: 16),
            Text(
              'Category breakdown will appear here',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    // For bar chart - show real chart style with days
    if (type == ChartPlaceholderType.bar) {
      return _buildRealBarChartPlaceholder();
    }
    
    // For line charts
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLinePlaceholder(),
        const SizedBox(height: 16),
        Text(
          'No data yet',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRealBarChartPlaceholder() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Column(
      children: [
        // Y-axis labels and chart area
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Y-axis labels
              SizedBox(
                width: 35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('500', style: _axisLabelStyle()),
                    Text('400', style: _axisLabelStyle()),
                    Text('300', style: _axisLabelStyle()),
                    Text('200', style: _axisLabelStyle()),
                    Text('100', style: _axisLabelStyle()),
                    Text('0', style: _axisLabelStyle()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chart area with grid and bars
              Expanded(
                child: Stack(
                  children: [
                    // Grid lines
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) => 
                        Container(
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                    // Bars
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (index) => 
                          _buildEmptyBar(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // X-axis labels (days)
        Padding(
          padding: const EdgeInsets.only(left: 43),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: days.map((day) => 
              SizedBox(
                width: 32,
                child: Text(
                  day,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ).toList(),
          ),
        ),
        const SizedBox(height: 20),
        // Message
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 10),
              Text(
                'No expenses recorded yet',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  TextStyle _axisLabelStyle() {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF9CA3AF),
    );
  }
  
  Widget _buildEmptyBar() {
    return Container(
      width: 24,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF0D5DB8).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPlaceholderIllustration() {
    switch (type) {
      case ChartPlaceholderType.line:
        return _buildLinePlaceholder();
      case ChartPlaceholderType.pie:
        return _buildPiePlaceholder();
      case ChartPlaceholderType.bar:
        return _buildBarPlaceholder();
    }
  }

  Widget _buildLinePlaceholder() {
    return SizedBox(
      height: 80,
      child: CustomPaint(
        size: const Size(double.infinity, 80),
        painter: _LinePlaceholderPainter(),
      ),
    );
  }

  Widget _buildPiePlaceholder() {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(painter: _PiePlaceholderPainter()),
    );
  }

  Widget _buildBarPlaceholder() {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPlaceholderBar(35),
          const SizedBox(width: 12),
          _buildPlaceholderBar(55),
          const SizedBox(width: 12),
          _buildPlaceholderBar(40),
          const SizedBox(width: 12),
          _buildPlaceholderBar(70),
          const SizedBox(width: 12),
          _buildPlaceholderBar(50),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBar(double height) {
    return Container(
      width: 28,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0D5DB8).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _LinePlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D5DB8).withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0D5DB8).withValues(alpha: 0.15),
          const Color(0xFF0D5DB8).withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create smooth curve points
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.6),
      Offset(size.width * 0.45, size.height * 0.3),
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.75, size.height * 0.25),
      Offset(size.width * 0.9, size.height * 0.4),
      Offset(size.width, size.height * 0.35),
    ];

    // Draw filled area
    final fillPath = Path()..moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      } else {
        final cp1 = Offset(
          points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2,
          points[i - 1].dy,
        );
        final cp2 = Offset(
          points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2,
          points[i].dy,
        );
        fillPath.cubicTo(
          cp1.dx,
          cp1.dy,
          cp2.dx,
          cp2.dy,
          points[i].dx,
          points[i].dy,
        );
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset(
        points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2,
        points[i - 1].dy,
      );
      final cp2 = Offset(
        points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2,
        points[i].dy,
      );
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i].dx,
        points[i].dy,
      );
    }
    canvas.drawPath(linePath, paint);

    // Draw dots at each point
    final dotPaint = Paint()
      ..color = const Color(0xFF0D5DB8).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    for (var point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PiePlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Colors for pie segments
    final colors = [
      const Color(0xFF0D5DB8),
      const Color(0xFF1478E0),
      const Color(0xFF64B5F6),
      const Color(0xFFBBDEFB),
    ];

    // Draw pie segments
    double startAngle = -1.57; // Start from top
    final sweeps = [0.35, 0.25, 0.22, 0.18]; // Percentages

    for (int i = 0; i < colors.length; i++) {
      final sweepAngle = sweeps[i] * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i].withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // Draw center hole for donut effect
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, holePaint);

    // Draw percentage text in center
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '0%',
        style: TextStyle(
          color: Color(0xFF0D5DB8),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum ChartPlaceholderType { line, pie, bar }


