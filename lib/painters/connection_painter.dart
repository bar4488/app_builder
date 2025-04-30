import 'package:flutter/material.dart';

class ConnectionPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final bool isPreview;

  ConnectionPainter({
    required this.startPoint,
    required this.endPoint,
    this.color = Colors.white,
    this.isPreview = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = _createConnectionPath();
    canvas.drawPath(path, paint);
  }

  Path _createConnectionPath() {
    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    final deltaX = (endPoint.dx - startPoint.dx);
    final controlPointX = deltaX / 2;

    path.cubicTo(
      startPoint.dx + controlPointX,
      startPoint.dy,
      endPoint.dx - controlPointX,
      endPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    return path;
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint ||
        oldDelegate.color != color ||
        oldDelegate.isPreview != isPreview;
  }
}
