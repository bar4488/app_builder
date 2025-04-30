import 'package:flutter/material.dart';
import '../models/node.dart';
import '../models/pin.dart';
import '../models/connection.dart';

class BlueprintEditorState extends ChangeNotifier {
  final List<Node> nodes = [];
  final List<Connection> connections = [];
  Pin? selectedPin;
  Offset pan = Offset.zero;
  double zoom = 1.0;

  void addNode(Node node) {
    nodes.add(node);
    node.updatePinPositions();
    notifyListeners();
  }

  void updateNodePosition(Node node, Offset position) {
    node.position = position;
    node.updatePinPositions();
    notifyListeners();
  }

  void selectPin(Pin? pin) {
    if (selectedPin != null && pin != null) {
      _tryCreateConnection(selectedPin!, pin);
      selectedPin = null;
    } else {
      selectedPin = pin;
    }
    notifyListeners();
  }

  void _tryCreateConnection(Pin startPin, Pin endPin) {
    if (startPin.nodeId == endPin.nodeId) return;
    if (startPin.direction == endPin.direction) return;

    final connection = Connection(
      startPinKey:
          startPin.direction == PinDirection.output ? startPin.key : endPin.key,
      endPinKey:
          startPin.direction == PinDirection.output ? endPin.key : startPin.key,
    );

    if (!connections.contains(connection)) {
      connections.add(connection);
      notifyListeners();
    }
  }

  void removeConnection(Connection connection) {
    connections.remove(connection);
    notifyListeners();
  }

  void updatePanZoom(Offset newPan, double newZoom) {
    pan = newPan;
    zoom = newZoom;
    notifyListeners();
  }
}
