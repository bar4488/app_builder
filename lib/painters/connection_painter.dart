import 'package:flutter/material.dart';
import 'package:unreal_editor/models/connection.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import 'dart:math' as math;

class ConnectionPainter extends CustomPainter {
  final BlueprintEditorState editorState;

  ConnectionPainter({required this.editorState}) : super(repaint: editorState);

  bool isPointNearConnection(Offset point, Connection connection) {
    // Quick check to avoid unnecessary calculations
    var path = connection.path!;
    const double hitTestPrecision = 10;
    if (!path.getBounds().inflate(hitTestPrecision).contains(point)) {
      return false;
    }

    // Cache path metrics for performance
    connection.pathMetrics ??= path.computeMetrics().toList();
    return path.contains(point) ||
        connection.pathMetrics!.any((metric) {
          // probe different x along metric.length
          for (double i = 0; i < metric.length; i += hitTestPrecision) {
            var tangent = metric.getTangentForOffset(i);
            if (tangent == null) continue;
            var delta = tangent.position - point;
            if (delta.distanceSquared < hitTestPrecision * hitTestPrecision) {
              return true;
            }
          }
          return false;
        });
  }

  Connection? getConnectionAtPoint(Offset point, {bool reversed = false}) {
    Iterable<Connection> connections;
    if (reversed) {
      connections = editorState.reversedConnections;
    } else {
      connections = editorState.connections;
    }
    for (final connection in connections) {
      if (connection.path != null && isPointNearConnection(point, connection)) {
        return connection;
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha((0.3 * 255).toInt())
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Draw existing connections
    for (final connection in editorState.connections) {
      final startPin = connection.startPin;

      final startPinPos = editorState.getPinGlobalPosition(
        connection.startPin,
      );
      final endPinPos = editorState.getPinGlobalPosition(connection.endPin);

      if (startPinPos != null && endPinPos != null) {
        final path = _buildPath(startPinPos, endPinPos);
        connection.path = path;

        // Get color based on pin type
        Color lineColor;
        switch (startPin.type) {
          case PinType.exec:
            lineColor = Colors.green;
            break;
          case PinType.value:
            lineColor = Colors.cyan;
            break;
          case PinType.render:
            lineColor = Colors.purple;
            break;
        }
        // if connection is hovered, make color brighter
        if (editorState.hoveredConnection == connection) {
          lineColor = Color.lerp(lineColor, Colors.white, 0.3)!;
        }

        final paint = Paint()
          ..color = lineColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        // Draw shadow first
        canvas.drawPath(path, shadowPaint);
        // Draw connection line
        canvas.drawPath(path, paint);
      }
    }

    // Draw temporary connection line while dragging
    if (editorState.dragStartPinPosition != null &&
        editorState.dragCurrentPosition != null) {
      final startPos = editorState.dragStartPinPosition!;
      final endPos = editorState.dragCurrentPosition!;
      final tempPath = _buildPath(
        startPos,
        endPos,
        editorState.dragStartPinDirection,
      );

      // Draw shadow first
      canvas.drawPath(tempPath, shadowPaint);
      // Draw temp line
      canvas.drawPath(
        tempPath,
        Paint()
          ..color = Colors.yellowAccent
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      ); // Use a distinct color
    }
  }

  Path _buildPath(Offset start, Offset end, [PinDirection? startDirection]) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Calculate control points for a Bezier curve
    // Adjust curve based on pin direction if known (makes output curves go out first)
    double dx =
        (end.dx - start.dx).abs() * 0.6; // Horizontal distance influence
    double dy = (end.dy - start.dy).abs() *
        0.1; // Vertical distance influence (less impact)

    Offset ctrl1, ctrl2;

    if (startDirection == PinDirection.output ||
        (startDirection == null && start.dx < end.dx)) {
      // Primarily dragging rightwards or from an output pin
      ctrl1 = Offset(start.dx + dx, start.dy + dy);
      ctrl2 = Offset(end.dx - dx, end.dy - dy);
    } else {
      // Primarily dragging leftwards or from an input pin
      ctrl1 = Offset(start.dx - dx, start.dy - dy);
      ctrl2 = Offset(end.dx + dx, end.dy + dy);
    }

    // Clamp control points to prevent extreme curves if start/end are very close vertically
    ctrl1 = Offset(
      ctrl1.dx,
      ctrl1.dy.clamp(
        math.min(start.dy, end.dy) - 50,
        math.max(start.dy, end.dy) + 50,
      ),
    );
    ctrl2 = Offset(
      ctrl2.dx,
      ctrl2.dy.clamp(
        math.min(start.dy, end.dy) - 50,
        math.max(start.dy, end.dy) + 50,
      ),
    );

    path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    // Repaint whenever the editor state changes (nodes move, connections change, etc.)
    return true; // Simplest approach for now
  }
}
