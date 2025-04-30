import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'pin.dart';

// Represents a connection between two pins
class Connection {
  final PinKey startPinKey;
  final PinKey endPinKey;
  // Store path for hit testing later if needed
  Path? path;
  List<PathMetric>? pathMetrics;

  Connection({required this.startPinKey, required this.endPinKey});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connection &&
          runtimeType == other.runtimeType &&
          startPinKey == other.startPinKey &&
          endPinKey == other.endPinKey;

  @override
  int get hashCode => startPinKey.hashCode ^ endPinKey.hashCode;
}
