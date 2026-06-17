import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsLogo extends StatelessWidget {
  final double size;

  const AnalyticsLogo({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: LogoPainter(),
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw bars
    final bar1Height = size.height * 0.3;
    final bar2Height = size.height * 0.5;
    final bar3Height = size.height * 0.7;
    final barWidth = size.width * 0.15;
    final spacing = size.width * 0.15;

    // Bar 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(spacing, size.height - bar1Height, barWidth, bar1Height),
        const Radius.circular(6),
      ),
      paint,
    );

    // Bar 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          spacing * 2 + barWidth,
          size.height - bar2Height,
          barWidth,
          bar2Height,
        ),
        const Radius.circular(6),
      ),
      paint,
    );

    // Bar 3
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          spacing * 3 + barWidth * 2,
          size.height - bar3Height,
          barWidth,
          bar3Height,
        ),
        const Radius.circular(6),
      ),
      paint,
    );

    // Draw arrow
    final arrowPath = Path();
    final arrowStartX = spacing + barWidth / 2;
    final arrowStartY = size.height - bar1Height - 10;
    final arrowMidX = spacing * 2 + barWidth * 1.5;
    final arrowMidY = size.height - bar2Height - 10;
    final arrowEndX = spacing * 3 + barWidth * 2.5;
    final arrowEndY = size.height - bar3Height - 10;

    arrowPath.moveTo(arrowStartX, arrowStartY);
    arrowPath.lineTo(arrowMidX, arrowMidY);
    arrowPath.lineTo(arrowEndX, arrowEndY);

    canvas.drawPath(arrowPath, strokePaint);

    // Draw arrow head
    final arrowHeadPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final arrowHeadPath = Path();
    arrowHeadPath.moveTo(arrowEndX + 15, arrowEndY - 15);
    arrowHeadPath.lineTo(arrowEndX, arrowEndY);
    arrowHeadPath.lineTo(arrowEndX + 15, arrowEndY + 5);
    arrowHeadPath.lineTo(arrowEndX + 20, arrowEndY - 5);
    arrowHeadPath.close();

    canvas.drawPath(arrowHeadPath, arrowHeadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



