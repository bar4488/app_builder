import 'dart:collection';

import 'package:app_builder/widgets/blueprint_variables_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:app_builder/models/connection.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/nodes/viewport.dart';
import 'package:app_builder/models/pin.dart';

class BlueprintState with ChangeNotifier {
  static const size = 4000.0;
  late final Node viewportNode;

  final List<Node> _nodes = [];
  Iterable<Node> get nodes => _nodes;
  final Map<String, Node> _nodeMap = {};
  final LinkedList<Connection> connections = LinkedList<Connection>();

  final List<BlueprintVariable> variables = [];

  BlueprintState() {
    viewportNode = ViewportNode(
      id: 'viewport',
      position: const Offset(size / 2 + 100, size / 2 + 100),
      blueprint: this,
    );
    addNode(viewportNode);
  }

  // --- Helpers ---
  Node? findNodeById(String id) {
    return _nodeMap[id];
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
      "Adding connection: ${newConn.startPin.id} -> ${newConn.endPin.id}",
    );

    connections.add(newConn);

    newConn.startPin.onConnectionChanged();
    newConn.endPin.onConnectionChanged();
    notifyListeners();
  }

  void removeConnection(Connection connection) {
    connections.remove(connection);
    connection.startPin.onConnectionChanged();
    connection.endPin.onConnectionChanged();
    notifyListeners();
  }

  void removeConnectionsForPin(Pin pin) {
    connections
        .where(
          (conn) => conn.startPin == pin || conn.endPin == pin,
        )
        .toList()
        .forEach((conn) {
      print(
        "Removing connection: ${conn.startPin.id} -> ${conn.endPin.id}",
      );
      conn.unlink();
      conn.startPin.onConnectionChanged();
      conn.endPin.onConnectionChanged();
    });
    notifyListeners();
  }

  void addNode(Node node) {
    _nodes.add(node);
    _nodeMap[node.id] = node;
    notifyListeners();
  }

  void removeNode(String nodeId) {
    var node = findNodeById(nodeId);
    if (node == null) {
      return;
    }
    removeNodes([node]);
  }

  void removeSelectedNodes() {
    var nodesToRemove = _nodes.where((node) => node.isSelected).toList();
    removeNodes(nodesToRemove);
  }

  void removeNodes(Iterable<Node> nodesToRemove) {
    nodesToRemove = nodesToRemove.where((node) => node.id != viewportNode.id);
    if (nodesToRemove.isEmpty) {
      return;
    }
    var idsToRemove = nodesToRemove
        .map(
          (e) => e.id,
        )
        .toSet();

    Set<Pin> changedPins = {};
    connections
        .where((conn) =>
            idsToRemove.contains(conn.startPin.nodeId) ||
            idsToRemove.contains(conn.endPin.nodeId))
        .toList()
        .forEach((conn) {
      conn.unlink();
      changedPins.add(conn.startPin);
      changedPins.add(conn.endPin);
    });

    for (var pin in changedPins) {
      pin.onConnectionChanged();
    }

    for (var node in nodesToRemove) {
      _nodes.remove(node);
      _nodeMap.remove(node.id);
    }
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

  void removeNodeInputPin(Node node, InputValuePin inputValuePin) {
    inputValuePin.connections.toList().forEach((conn) {
      conn.unlink();
      conn.startPin.onConnectionChanged();
    });
    node.removeInputPin(inputValuePin);
    notifyListeners();
  }

  void addVariable(BlueprintVariable blueprintVariable) {
    variables.add(blueprintVariable);
    notifyListeners();
  }

  void removeVariableAt(int index) {
    variables.removeAt(index);
    notifyListeners();
  }

  void setVariableName(BlueprintVariable variable, String name) {
    variable.name = name;
    notifyListeners();
  }

  void setVariableType(BlueprintVariable variable, VariableType newType) {
    variable.setType(newType);
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'nodes': _nodes.map((node) => node.toJson()).toList(),
      'connections': connections.map((conn) => conn.toJson()).toList(),
      'variables': variables.map((variable) => variable.toJson()).toList(),
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    removeNodes(_nodes);

    var newNodes = (json['nodes'] as List<dynamic>)
        .map<Node>((nodeJson) => Node.fromJson(nodeJson, this));
    _nodes.clear();
    _nodes.addAll(newNodes);
    // connections = json['connections']
    //     .map<Connection>((connJson) => Connection.fromJson(connJson, this))
    //     .toList();
    // variables = json['variables']
    //     .map<BlueprintVariable>(
    //         (variableJson) => BlueprintVariable.fromJson(variableJson))
    //     .toList();
    notifyListeners();
  }
}
