import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Offset offset; // Canvas pan offset
  final double scale; // Canvas pan offset
  final double majorGridStep = 100.0;
  final double minorGridStep = 20.0;

  GridPainter(this.offset, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final majorPaint = Paint()
      ..color = Colors.grey[800]! // Darker grey for major lines
      ..strokeWidth = 0.8;

    final minorPaint = Paint()
      ..color = Colors.grey[850]! // Even darker/subtler grey for minor lines
      ..strokeWidth = 0.5;

    // Calculate the start and end points based on the canvas size and offset
    // Adjust grid lines based on the canvas offset to create panning effect

    Offset screenZero = _screenToWorld(Offset.zero);
    Offset screenMax = _screenToWorld(Offset(size.width, size.height));

    final double startX =
        (screenZero.dx ~/ majorGridStep).toDouble() * majorGridStep;
    final double startY =
        (screenZero.dy ~/ majorGridStep).toDouble() * majorGridStep;
    final double startXMinor =
        (screenZero.dx ~/ minorGridStep).toDouble() * minorGridStep;
    final double startYMinor =
        (screenZero.dy ~/ minorGridStep).toDouble() * minorGridStep;
    // Draw minor grid lines
    for (double x = startXMinor; x < screenMax.dx; x += minorGridStep) {
      canvas.drawLine(
        Offset(x, screenZero.dy),
        Offset(x, screenMax.dy),
        minorPaint,
      );
    }
    for (double y = startYMinor; y < screenMax.dy; y += minorGridStep) {
      canvas.drawLine(
        Offset(screenZero.dx, y),
        Offset(screenMax.dx, y),
        minorPaint,
      );
    }

    // Draw major grid lines (over minor lines)
    for (double x = startX; x < screenMax.dx; x += majorGridStep) {
      canvas.drawLine(
        Offset(x, screenZero.dy),
        Offset(x, screenMax.dy),
        majorPaint,
      );
    }
    for (double y = startY; y < screenMax.dy; y += majorGridStep) {
      canvas.drawLine(
        Offset(screenZero.dx, y),
        Offset(screenMax.dx, y),
        majorPaint,
      );
    }
  }

  // screen to world
  Offset _screenToWorld(Offset screen) => screen / scale + offset;

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    // Repaint only if the offset changes
    return oldDelegate.offset != offset;
  }
}
