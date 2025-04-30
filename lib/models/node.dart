import 'dart:math';

import 'package:flutter/material.dart';
import 'pin.dart';

enum NodeType {
  static,
  multiOutput,
}

// Represents a node in the blueprint editor
class Node {
  final String id;
  String title;
  Offset position; // Top-left position on the canvas
  Size size; // Size of the node widget
  final List<Pin> inputPins;
  final List<Pin> outputPins;
  bool isSelected;
  NodeType type;

  final NodeRenderer? _renderer;

  Node({
    required this.id,
    required this.title,
    required this.position,
    this.type = NodeType.static,
    this.size = const Size(180, 100), // Default size
    List<Pin>? inputPins,
    List<Pin>? outputPins,
    this.isSelected = false,
    NodeRenderer? renderer,
  })  : inputPins = inputPins ?? [],
        outputPins = outputPins ?? [],
        _renderer = renderer {
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

  Rect get rect =>
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

  T matchType<T>({
    required T Function() static,
    required T Function() multiOutput,
  }) {
    switch (type) {
      case NodeType.static:
        return static();
      case NodeType.multiOutput:
        return multiOutput();
    }
  }

  NodeRenderer? getRenderer() {
    return _renderer;
  }

  Stream<String> getValueStream({required String inputPinLabel}) {
    return Stream.value("${inputPinLabel} value");
  }
}

abstract class NodeRenderer {
  Widget buildNodeWidget(Node node, List<Widget> children);
}

class ColumnNodeRenderer extends NodeRenderer {
  @override
  Widget buildNodeWidget(Node node, List<Widget> children) {
    return Column(
      children: children,
    );
  }
}

class RowNodeRenderer extends NodeRenderer {
  @override
  Widget buildNodeWidget(Node node, List<Widget> children) {
    return Row(
      children: children,
    );
  }
}

class TextNodeRenderer extends NodeRenderer {
  @override
  Widget buildNodeWidget(Node node, List<Widget> children) {
    return StreamBuilder(
      stream: node.getValueStream(inputPinLabel: "value"),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data!);
        }
        return Text("Invalid value");
      },
    );
    return Text(node.title);
  }
}

class ViewportNodeRenderer extends NodeRenderer {
  @override
  Widget buildNodeWidget(Node node, List<Widget> children) {
    return Center(child: children.firstOrNull ?? Text("No children"));
  }
}
