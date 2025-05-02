import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:unreal_editor/models/connection.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/nodes/viewport.dart';
import 'package:unreal_editor/models/pin.dart';

class BlueprintState with ChangeNotifier {
  final Node viewportNode = ViewportNode(
    id: 'viewport',
    position: const Offset(100, 100),
  );

  final List<Node> _nodes = [];
  Iterable<Node> get nodes => _nodes;
  final Map<String, Node> _nodeMap = {};
  final LinkedList<Connection> connections = LinkedList<Connection>();

  BlueprintState() {
    addNode(viewportNode);
  }

  void removeConnection(Connection connection) {
    connections.remove(connection);
    connection.startPin.onConnectionChanged();
    connection.endPin.onConnectionChanged();
    notifyListeners();
  }

  void removeConnectionsForPin(Pin pin) {
    connections.removeWhere(
      (conn) => conn.startPin == pin || conn.endPin == pin,
    );
    notifyListeners();
  }

  // --- Helpers ---
  Node? findNodeById(String id) {
    return _nodeMap[id];
  }

  Pin? findPinByKey(PinKey key) {
    for (var node in _nodes) {
      for (var pin in node.allPins) {
        if (pin.key == key) {
          return pin;
        }
      }
    }
    return null;
  }

  T postOrderWalk<T>(
    Node node, {
    required T Function(Node, List<T> children) action,
    required PinType pinType,
  }) {
    List<T> children = [];
    for (var pin in node.outputPins.where((pin) => pin.type == pinType)) {
      final connectedNodes = pin.connections
          .map((conn) => conn.endPin)
          .map((pin) => findNodeById(pin.nodeId))
          .whereType<Node>();
      for (var connectedNode in connectedNodes) {
        children.add(
          postOrderWalk(
            connectedNode,
            action: action,
            pinType: pinType,
          ),
        );
      }
    }
    return action(node, children);
  }

  void addConnection(Connection newConn) {
    newConn.startPin.addConnection(newConn);
    newConn.endPin.addConnection(newConn);
    print(
      "Adding connection: ${newConn.startPin.key} -> ${newConn.endPin.key}",
    );

    connections.add(newConn);

    newConn.startPin.onConnectionChanged();
    newConn.endPin.onConnectionChanged();
    notifyListeners();
  }

  void addNode(Node node) {
    _nodes.add(node);
    _nodeMap[node.id] = node;
    notifyListeners();
  }

  void removeNode(String nodeId) {
    _nodes.removeWhere((node) => node.id == nodeId);
    // Remove connections associated with the deleted node
    connections.removeWhere((conn) =>
        conn.startPin.nodeId == nodeId || conn.endPin.nodeId == nodeId);
    notifyListeners();
  }

  void removeHighlightColor(Node node) {
    node.removeHighlightColor();
    notifyListeners();
  }

  void switchHighlightColor(Node node) {
    node.nextHighlightColor(); // Toggle selection could be added later
    notifyListeners();
  }
}
