import 'dart:math';

import 'package:app_builder/models/nodes.dart';
import 'package:app_builder/state/blueprint_state.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/variable.dart';
import 'package:runtime_type/runtime_type.dart';
import 'pin.dart';

enum NodeKind {
  static,
  multiOutput,
}

abstract class Node with ChangeNotifier {
  final String id;

  String get typeName;
  String? get description => null;

  Offset position; // Top-left position on the canvas
  Size size; // Size of the node widget
  String? error;

  final List<Pin> inputPins;
  final List<Pin> outputPins;
  bool isSelected;
  NodeKind get kind => NodeKind.static;

  final BlueprintState _blueprint;
  BlueprintState get blueprint => _blueprint;

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

  bool deletable = true;

  Color? get highlightColor =>
      highlightColors[highlightColorIndex % highlightColors.length];

  RenderData? get renderData => null;
  NodeSettigns? get settings => null;

  InputRenderPin? get inputRenderPin =>
      inputPins.whereType<InputRenderPin>().firstOrNull;

  Node({
    required this.id,
    required this.position,
    required BlueprintState blueprint,
    bool hasRenderInput = false,
    this.size = const Size(180, 100), // Default size
    List<Pin>? inputPins,
    List<Pin>? outputPins,
    this.isSelected = false,
  })  : inputPins = inputPins ?? [],
        outputPins = outputPins ?? [],
        _blueprint = blueprint {
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
            (kind == NodeKind.static ? 0 : 20));
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

  InputValuePin? getInputValuePin(RuntimeType type) {
    return inputPins
        .whereType<InputValuePin>()
        .where((e) => e.valueType == type)
        .single;
  }

  OutputValuePin? getOutputValuePin(RuntimeType type) {
    return outputPins
        .whereType<OutputValuePin>()
        .where((e) => e.valueType == type)
        .single;
  }

  InputRenderPin? getInputRenderPin() {
    return inputRenderPin!;
  }

  OutputRenderPin? getOutputRenderPin() {
    return outputPins.whereType<OutputRenderPin>().single;
  }

  Pin? getPinFor(Pin other) {
    return switch (other) {
      InputValuePin() => getOutputValuePin(other.valueType),
      OutputValuePin() => getInputValuePin(other.valueType),
      InputRenderPin() => getOutputRenderPin(),
      OutputRenderPin() => getInputRenderPin(),
      _ => throw TypeError(),
    };
  }

  InputValuePin<T> bindInputVariable<T>(NodeVariable<T> variable) {
    var inputPin = InputValuePin<T>(
      nodeId: id,
      label: variable.name,
      onValueChanged: (value) {
        variable.setValueNode(value);
      },
    );
    addInputPin(inputPin);
    variable.bindInputPin(inputPin);
    return inputPin;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': typeName,
      'position': [position.dx, position.dy],
      'size': [size.width, size.height],
      'inputPins': inputPins.map((pin) => pin.toJson()).toList(),
      'outputPins': outputPins.map((pin) => pin.toJson()).toList(),
    };
  }

  static Node fromJson(
      Map<String, dynamic> nodeJson, BlueprintState blueprintState) {
    var type = nodeTypes.firstWhere(
      (element) => element.name == nodeJson['type'],
    );
    return type.nodeBuilder(
      nodeJson["id"],
      Offset(nodeJson["position"][0], nodeJson["position"][1]),
      blueprintState,
    );
  }
}

abstract class MultiOutputNode extends Node {
  @override
  NodeKind get kind => NodeKind.multiOutput;

  MultiOutputNode({
    required super.id,
    required super.position,
    required super.blueprint,
    super.hasRenderInput,
    super.size,
    super.inputPins,
    super.outputPins,
    super.isSelected,
  });

  OutputRenderPin addOutputRenderPin();

  @override
  OutputRenderPin? getOutputRenderPin() {
    var pins = outputPins.whereType<OutputRenderPin>();
    if (pins.length > 1) throw Exception("ambiguous output render pin");
    return pins.firstOrNull ?? addOutputRenderPin();
  }
}
