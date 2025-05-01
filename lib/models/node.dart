import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:unreal_editor/models/nodes/node_data.dart';
import 'package:unreal_editor/models/nodes/node_settigns.dart';
import 'package:unreal_editor/state/blueprint_state.dart';
import 'pin.dart';

enum NodeType {
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
  NodeType type;

  bool get isRenderable => renderData != null;
  RenderData? get renderData => null;
  NodeSettigns? get settings => null;

  Node({
    required this.id,
    required this.title,
    required this.position,
    this.type = NodeType.static,
    this.size = const Size(180, 100), // Default size
    List<Pin>? inputPins,
    List<Pin>? outputPins,
    this.isSelected = false,
  })  : inputPins = inputPins ?? [],
        outputPins = outputPins ?? [] {
    if (isRenderable) {
      // add render pin to input at start of list
      this.inputPins.insert(
          0,
          InputRenderPin(
            nodeId: id,
            label: "Render",
            direction: PinDirection.input,
          ));
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
            (type == NodeType.static ? 0 : 20));
  }

  void addInputPin(Pin pin) {
    inputPins.add(pin);
    calculatePinPositions();
  }

  void addOutputPin(Pin pin) {
    outputPins.add(pin);
    calculatePinPositions();
  }

  Rect get rect =>
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

  double get padding => 8.0;

  T matchType<T>({
    required T Function(Node) static,
    required T Function(MultiOutputNode) multiOutput,
  }) {
    switch (type) {
      case NodeType.static:
        return static(this);
      case NodeType.multiOutput:
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
}

abstract class MultiOutputNode extends Node {
  MultiOutputNode({
    required super.id,
    required super.title,
    required super.position,
    super.size, // Default size
    super.inputPins,
    super.outputPins,
    super.isSelected,
  }) : super(
          type: NodeType.multiOutput,
        );

  void addOutputRenderPin();
}

class ViewportNode extends Node {
  final RenderData _renderData;

  String? childId;

  ViewportNode({required super.id, required super.position})
      : _renderData = ViewportRenderData(),
        super(
          title: "Viewport",
          type: NodeType.static,
        ) {
    addOutputPin(
      OutputRenderPin(
        nodeId: id,
        label: "Render",
        direction: PinDirection.output,
        onRenderTargetChanged: (childId) {
          this.childId = childId;
          notifyListeners();
        },
      ),
    );
  }

  @override
  RenderData get renderData => _renderData;
}

class ColumnNode extends MultiOutputNode {
  final RenderData _renderData;

  @override
  RenderData get renderData => _renderData;

  final List<String?> children = [];

  ValueNode<MainAxisAlignment>? _mainAxisAlignment;

  ValueNode<MainAxisAlignment> get mainAxisAlignment =>
      _mainAxisAlignment ??
      const ConstValueNode<MainAxisAlignment>(MainAxisAlignment.start);

  ColumnNode({required super.id, required super.position})
      : _renderData = ColumnRenderData(),
        super(
          title: "Column",
        ) {
    addInputPin(
      InputValuePin<MainAxisAlignment>(
        nodeId: id,
        label: "MainAxisAlignment",
        onValueChanged: (output) {
          _mainAxisAlignment = output?.value;
          notifyListeners();
        },
      ),
    );
  }

  @override
  void addOutputRenderPin() {
    children.add(null);
    var index = children.length - 1;
    addOutputPin(
      OutputRenderPin(
        nodeId: id,
        label: "Output ${outputPins.length + 1}",
        direction: PinDirection.output,
        onRenderTargetChanged: (nodeId) {
          children[index] = nodeId;
          notifyListeners();
        },
      ),
    );
  }
}

class RowNode extends MultiOutputNode {
  // final RenderData _renderData;

  // @override
  // RenderData get renderData => _renderData;

  final List<Node> children = [];

  ValueNode<MainAxisAlignment> mainAxisAlignment =
      const ConstValueNode<MainAxisAlignment>(MainAxisAlignment.start);

  RowNode({required super.id, required super.position})
      // : _renderData = RowRenderData(),
      : super(
          title: "Row",
        );

  @override
  void addOutputRenderPin() {
    addOutputPin(
      Pin(
        nodeId: id,
        label: "Output ${outputPins.length + 1}",
        type: PinType.render,
        direction: PinDirection.output,
      ),
    );
  }
}

class TextNode extends Node {
  final RenderData _renderData;

  @override
  RenderData get renderData => _renderData;

  ValueNode<String>? text;

  TextNode({required super.id, required super.position})
      : _renderData = TextRenderData(),
        super(
          title: "Text",
          type: NodeType.static,
        ) {
    addInputPin(
      InputValuePin<String>(
        nodeId: id,
        label: "value",
        onValueChanged: (output) {
          text = output?.value;
          notifyListeners();
        },
      ),
    );
  }
}

class StringNode extends Node {
  NodeSettigns _settigns;
  @override
  NodeSettigns get settings => _settigns;

  late OutputValuePin<String> valuePin;

  StringNode({required super.id, required super.position})
      : _settigns = StringNodeSettigns(),
        super(
          title: "String",
          type: NodeType.static,
        ) {
    valuePin = OutputValuePin<String>(
      nodeId: id,
      label: "value",
    );
    addOutputPin(valuePin);
  }
}
