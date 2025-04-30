import 'package:flutter/material.dart';
import 'pin.dart';

// Represents a node in the blueprint editor
class Node {
  final String id;
  String title;
  Offset position; // Top-left position on the canvas
  Size size; // Size of the node widget
  final List<Pin> inputPins;
  final List<Pin> outputPins;
  bool isSelected;

  Node({
    required this.id,
    required this.title,
    required this.position,
    this.size = const Size(180, 100), // Default size
    List<Pin>? inputPins,
    List<Pin>? outputPins,
    this.isSelected = false,
  })  : inputPins = inputPins ?? [],
        outputPins = outputPins ?? [] {
    // Initialize pin positions
    calculatePinPositions();
  }

  // Helper to get all pins
  List<Pin> get allPins => [...inputPins, ...outputPins];

  // Calculate pin positions based on node size (simple vertical layout)
  void calculatePinPositions() {
    const double pinSpacing = 30.0;
    const double initialOffset = 40.0; // Offset from top
    const double pinRadius = 6.0; // To center the pin vertically

    for (int i = 0; i < inputPins.length; i++) {
      inputPins[i].relativePosition = Offset(
        0,
        initialOffset + i * pinSpacing - pinRadius,
      );
    }
    for (int i = 0; i < outputPins.length; i++) {
      outputPins[i].relativePosition = Offset(
        size.width,
        initialOffset + i * pinSpacing - pinRadius,
      );
    }
  }

  Rect get rect =>
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}
