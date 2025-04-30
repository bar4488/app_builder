import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:unreal_editor/models/connection.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/pin.dart';

class BlueprintState with ChangeNotifier {
  Node viewportNode = Node(
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
      renderer: ViewportNodeRenderer());

  final List<Node> nodes = [];
  final LinkedList<Connection> connections = LinkedList<Connection>();

  BlueprintState() {
    nodes.add(viewportNode!);
  }

  void removeConnection(Connection connection) {
    connections.remove(connection);
    notifyListeners();
  }

  void removeConnectionsForPin(PinKey pinKey) {
    connections.removeWhere(
      (conn) => conn.startPinKey == pinKey || conn.endPinKey == pinKey,
    );
    notifyListeners();
  }

  // --- Helpers ---
  Node? findNodeById(String id) {
    try {
      return nodes.firstWhere((node) => node.id == id);
    } catch (e) {
      return null;
    }
  }

  Pin? findPinByKey(PinKey key) {
    for (var node in nodes) {
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
          .map((conn) => findPinByKey(conn.endPinKey))
          .nonNulls
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
    connections.add(newConn);
    notifyListeners();
  }

  void addNode(Node node) {
    nodes.add(node);
    notifyListeners();
  }

  void removeNode(String nodeId) {
    nodes.removeWhere((node) => node.id == nodeId);
    // Remove connections associated with the deleted node
    connections.removeWhere((conn) =>
        conn.startPinKey.value.startsWith(nodeId) ||
        conn.endPinKey.value.startsWith(nodeId));
    notifyListeners();
  }
}
