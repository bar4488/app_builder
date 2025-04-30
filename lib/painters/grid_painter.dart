import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Offset pan;
  final double zoom;
  final double gridSpacing;
  final Color gridColor;

  GridPainter({
    required this.pan,
    required this.zoom,
    this.gridSpacing = 20.0,
    this.gridColor = const Color(0xFF2A2A2A),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    final effectiveSpacing = gridSpacing * zoom;
    final startX = (pan.dx % effectiveSpacing) - effectiveSpacing;
    final startY = (pan.dy % effectiveSpacing) - effectiveSpacing;

    for (var x = startX;
        x <= size.width + effectiveSpacing;
        x += effectiveSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var y = startY;
        y <= size.height + effectiveSpacing;
        y += effectiveSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.pan != pan ||
        oldDelegate.zoom != zoom ||
        oldDelegate.gridSpacing != gridSpacing ||
        oldDelegate.gridColor != gridColor;
  }
}
