import 'dart:math';

import 'package:flutter/material.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/node_settigns.dart';
import 'package:app_builder/models/variable.dart';
import 'pin.dart';

enum NodeKind {
  static,
  multiOutput,
}

// Represents a node in the blueprint editor
class Node with ChangeNotifier {
  final String id;
  String title;

  Offset position; // Top-left position on the canvas
  Size size; // Size of the node widget
  String? error;

  final List<Pin> inputPins;
  final List<Pin> outputPins;
  bool isSelected;
  NodeKind type;

  static const List<Color?> highlightColors = [
    null,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
  ];
  int highlightColorIndex = 0;

  Color? get highlightColor =>
      highlightColors[highlightColorIndex % highlightColors.length];

  RenderData? get renderData => null;
  NodeSettigns? get settings => null;

  InputRenderPin? get inputRenderPin =>
      inputPins.whereType<InputRenderPin>().firstOrNull;

  Node({
    required this.id,
    required this.title,
    required this.position,
    bool hasRenderInput = false,
    this.type = NodeKind.static,
    this.size = const Size(180, 100), // Default size
    List<Pin>? inputPins,
    List<Pin>? outputPins,
    this.isSelected = false,
  })  : inputPins = inputPins ?? [],
        outputPins = outputPins ?? [] {
    if (hasRenderInput) {
      // add render pin to input at start of list
      this.inputPins.insert(
          0,
          InputRenderPin(
            nodeId: id,
            label: "Render",
            direction: PinDirection.input,
          ));
    }
    for (var target in getRenderTargets()) {
      // add render pin to output at end of list
      addOutputPin(
        OutputRenderPin(
          nodeId: id,
          label: target.name,
          onRenderTargetChanged: (childId) {
            target.targetNodeId = childId;
            notifyListeners();
          },
        ),
      );
    }
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
    size = Size(
        size.width,
        initialOffset +
            (max(inputPins.length, outputPins.length)) * pinSpacing +
            (type == NodeKind.static ? 0 : 20));
  }

  void removeInputPin(Pin pin) {
    inputPins.remove(pin);
    calculatePinPositions();
    notifyListeners();
  }

  void addInputPin(Pin pin) {
    inputPins.add(pin);
    calculatePinPositions();
    notifyListeners();
  }

  void addOutputPin(Pin pin) {
    outputPins.add(pin);
    calculatePinPositions();
    notifyListeners();
  }

  Rect get rect =>
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

  double get padding => 8.0;

  T matchType<T>({
    required T Function(Node) static,
    required T Function(MultiOutputNode) multiOutput,
  }) {
    switch (type) {
      case NodeKind.static:
        return static(this);
      case NodeKind.multiOutput:
        return multiOutput(this as MultiOutputNode);
    }
  }

  Stream<String> getValueStream({required String inputPinLabel}) {
    var pin = inputPins.firstWhere(
      (pin) => pin.label == inputPinLabel,
      orElse: () => throw Exception("Pin not found"),
    );
    if (pin.type != PinType.value) {
      throw Exception("Pin is not a value pin");
    }

    return getStreamFromValuePin(pin);
  }

  Stream<String> getStreamFromValuePin(Pin pin) {
    // This is a placeholder implementation. Replace with actual logic.
    return Stream<String>.periodic(
      const Duration(seconds: 1),
      (count) => "Value from ${pin.label}: $count",
    );
  }

  void nextHighlightColor() {
    highlightColorIndex++;
    notifyListeners();
  }

  void removeHighlightColor() {
    highlightColorIndex = 0;
    notifyListeners();
  }

  Iterable<NodeVariable> getVariables() {
    return [];
  }

  Iterable<RenderTarget> getRenderTargets() {
    return [];
  }
}

abstract class MultiOutputNode extends Node {
  MultiOutputNode({
    required super.id,
    required super.title,
    required super.position,
    super.hasRenderInput,
    super.size,
    super.inputPins,
    super.outputPins,
    super.isSelected,
  }) : super(
          type: NodeKind.multiOutput,
        );

  OutputRenderPin addOutputRenderPin();
}
