import 'package:flutter/gestures.dart';
import 'package:unreal_editor/models/connection.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/pin.dart';

class BlueprintState {
  Node? viewportNode = Node(
    id: 'viewport',
    title: 'Viewport',
    position: Offset(100, 100),
    inputPins: List.empty(),
    outputPins: [
      Pin(
        nodeId: 'viewport',
        label: "Render",
        direction: PinDirection.output,
        type: PinType.render,
      ),
    ],
  );

  final List<Node> nodes = [];
  final List<Connection> connections = [];

  BlueprintState() {
    nodes.add(viewportNode!);
  }
}
