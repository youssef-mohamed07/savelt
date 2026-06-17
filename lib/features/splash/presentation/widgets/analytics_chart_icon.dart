import 'package:flutter/material.dart';

class AnalyticsChartIcon extends StatelessWidget {
  final double size;
  final Color color;

  const AnalyticsChartIcon({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: ChartPainter(color: color),
    );
  }
}

class ChartPainter extends CustomPainter {
  final Color color;

  ChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final bar1Height = size.height * 0.35;
    final bar2Height = size.height * 0.55;
    final bar3Height = size.height * 0.75;
    final barWidth = size.width * 0.18;
    final spacing = size.width * 0.12;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(spacing, size.height - bar1Height, barWidth, bar1Height),
        const Radius.circular(8),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(spacing, size.height - bar1Height, barWidth, bar1Height),
        const Radius.circular(8),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          spacing * 2 + barWidth,
          size.height - bar2Height,
          barWidth,
          bar2Height,
        ),
        const Radius.circular(8),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          spacing * 2 + barWidth,
          size.height - bar2Height,
          barWidth,
          bar2Height,
        ),
        const Radius.circular(8),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          spacing * 3 + barWidth * 2,
          size.height - bar3Height,
          barWidth,
          bar3Height,
        ),
        const Radius.circular(8),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          spacing * 3 + barWidth * 2,
          size.height - bar3Height,
          barWidth,
          bar3Height,
        ),
        const Radius.circular(8),
      ),
      paint,
    );

    final trendPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(spacing + barWidth / 2, size.height - bar1Height + 15);
    path.lineTo(spacing * 2 + barWidth * 1.5, size.height - bar2Height + 15);
    path.lineTo(spacing * 3 + barWidth * 2.5, size.height - bar3Height + 15);

    canvas.drawPath(path, trendPaint);

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    final arrowX = spacing * 3 + barWidth * 2.5 + 18;
    final arrowY = size.height - bar3Height;

    arrowPath.moveTo(arrowX, arrowY);
    arrowPath.lineTo(arrowX - 15, arrowY + 10);
    arrowPath.lineTo(arrowX - 10, arrowY + 10);
    arrowPath.lineTo(arrowX - 10, arrowY + 25);
    arrowPath.lineTo(arrowX + 10, arrowY + 25);
    arrowPath.lineTo(arrowX + 10, arrowY + 10);
    arrowPath.lineTo(arrowX + 15, arrowY + 10);
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



