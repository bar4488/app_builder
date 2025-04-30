import 'package:flutter/material.dart';
import 'pin.dart';

// Represents a node in the blueprint editor
class Node {
  final String id;
  final String type;
  final List<Pin> pins;
  Offset position;
  Size size;

  Node({
    required this.id,
    required this.type,
    required this.pins,
    this.position = Offset.zero,
    this.size = const Size(150, 100),
  });

  List<Pin> get inputPins =>
      pins.where((p) => p.direction == PinDirection.input).toList();
  List<Pin> get outputPins =>
      pins.where((p) => p.direction == PinDirection.output).toList();

  void updatePinPositions() {
    final inputCount = inputPins.length;
    final outputCount = outputPins.length;
    final maxCount = inputCount > outputCount ? inputCount : outputCount;
    final spacing = maxCount <= 1 ? 0.0 : size.height / (maxCount - 1);

    // Position input pins on the left
    for (var i = 0; i < inputPins.length; i++) {
      inputPins[i].relativePosition = Offset(0, i * spacing);
    }

    // Position output pins on the right
    for (var i = 0; i < outputPins.length; i++) {
      outputPins[i].relativePosition = Offset(size.width, i * spacing);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Node && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
