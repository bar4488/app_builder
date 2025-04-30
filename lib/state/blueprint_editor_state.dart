import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:unreal_editor/state/blueprint_state.dart';
import '../models/node.dart';
import '../models/pin.dart';
import '../models/connection.dart';

// --- ChangeNotifier for State Management ---

class BlueprintEditorState extends ChangeNotifier {
  final BlueprintState _blueprintState;
  Offset _canvasOffset = Offset.zero; // For panning
  double _scale = 1.0; // For zooming

  // For drawing temporary connection line
  Offset? _dragStartPinPosition;
  Offset? _dragCurrentPosition;
  PinKey? _dragStartPinKey;
  PinDirection? dragStartPinDirection;

  Iterable<Node> get nodes => _blueprintState.nodes;
  Iterable<Connection> get connections => _blueprintState.connections;
  Iterable<Connection> get reversedConnections =>
      _blueprintState.connections.reversed;
  Node get viewportNode => _blueprintState.viewportNode;
  Offset get canvasOffset => _canvasOffset;
  double get scale => _scale;

  Offset? get dragStartPinPosition => _dragStartPinPosition;
  Offset? get dragCurrentPosition => _dragCurrentPosition;
  PinKey? get dragStartPinKey => _dragStartPinKey;

  PinKey? _currentHoverPinKey;
  PinKey? get currentHoverPinKey => _currentHoverPinKey;

  // Add these properties for context menu
  Offset? _contextMenuPosition;
  Offset? get contextMenuPosition => _contextMenuPosition;

  static const double stackWidth = 4000.0;
  static const double stackHeight = 4000.0;

  Connection? _hoveredConnection;
  Connection? get hoveredConnection => _hoveredConnection;

  BlueprintEditorState(this._blueprintState);

  void setHoveredConnection(Connection? connection) {
    if (_hoveredConnection == connection) return; // No change
    _hoveredConnection = connection;
    notifyListeners();
  }

  void showContextMenu(Offset position) {
    _contextMenuPosition = position;
    notifyListeners();
  }

  void hideContextMenu() {
    _contextMenuPosition = null;
    notifyListeners();
  }

  // --- Node Management ---
  void addNode(Node node) {
    node.calculatePinPositions(); // Calculate pin positions when adding
    _blueprintState.addNode(node);
  }

  void deleteNode(String nodeId) {
    _blueprintState.removeNode(nodeId);
  }

  void setHoverPinKey(PinKey? pinKey) {
    _currentHoverPinKey = pinKey;
    notifyListeners();
  }

  // Add helper method to constrain position
  Offset _constrainPosition(Offset position, Size nodeSize) {
    return Offset(
      position.dx.clamp(0, stackWidth - nodeSize.width),
      position.dy.clamp(0, stackHeight - nodeSize.height),
    );
  }

  void moveNode(String nodeId, Offset delta) {
    final node = nodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => throw Exception("Node not found"),
    );

    // Calculate new position and constrain it
    final newPosition = _constrainPosition(node.position + delta, node.size);
    if (newPosition != node.position) {
      node.position = newPosition;
      notifyListeners();
    }
  }

  void selectNode(String nodeId, {bool multiSelect = false}) {
    if (!multiSelect) {
      for (var node in nodes) {
        node.isSelected = false;
      }
    }
    final node = nodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => throw Exception("Node not found"),
    );
    node.isSelected = true; // Toggle selection could be added later
    notifyListeners();
  }

  void deselectAllNodes() {
    bool changed = false;
    for (var node in nodes) {
      if (node.isSelected) {
        node.isSelected = false;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // --- Canvas Management ---
  void panCanvas(Offset delta) {
    _canvasOffset -= delta / _scale;
    notifyListeners();
  }

  // --- Connection Management ---
  void startDraggingConnection(
    PinKey pinKey,
    Offset startPosition,
    Offset mousePosition,
    PinDirection direction,
  ) {
    _dragStartPinKey = pinKey;
    _dragStartPinPosition = startPosition;
    _dragCurrentPosition = mousePosition; // Initialize current pos
    dragStartPinDirection = direction;
    notifyListeners();
  }

  void updateDraggingConnection({Offset? currentPosition, Offset? delta}) {
    if (_dragCurrentPosition != null) {
      if (currentPosition != null) {
        _dragCurrentPosition = currentPosition;
      } else if (delta != null) {
        _dragCurrentPosition = _dragCurrentPosition! + delta;
      } else {
        // Throw error
        throw Exception("No current position or delta provided");
      }
      notifyListeners();
    }
  }

  void endDraggingConnection() {
    var endPinKey = currentHoverPinKey;
    if (_dragStartPinKey != null &&
        endPinKey != null &&
        _dragStartPinKey != endPinKey) {
      // Get both pins
      var startPin = _blueprintState.findPinByKey(_dragStartPinKey!);
      var endPin = _blueprintState.findPinByKey(endPinKey);

      if (startPin != null &&
          endPin != null &&
          startPin.direction != endPin.direction &&
          startPin.type == endPin.type) {
        // Add type check
        // Determine correct start/end based on direction
        final outputPinKey = (startPin.direction == PinDirection.output)
            ? _dragStartPinKey!
            : endPinKey;
        final inputPinKey = (startPin.direction == PinDirection.input)
            ? _dragStartPinKey!
            : endPinKey;

        var newConn =
            Connection(startPinKey: outputPinKey, endPinKey: inputPinKey);
        startPin.addConnection(newConn);
        endPin.addConnection(newConn);
        print("Adding connection: $outputPinKey -> $inputPinKey");

        _blueprintState.addConnection(newConn);
      }
    }
    // Reset dragging state
    _dragStartPinKey = null;
    _dragStartPinPosition = null;
    _dragCurrentPosition = null;
    dragStartPinDirection = null;
    notifyListeners();
  }

  // Get the global position of a pin
  Offset? getPinGlobalPosition(PinKey pinKey) {
    final pin = _blueprintState.findPinByKey(pinKey);
    if (pin != null) {
      final node = _blueprintState.findNodeById(pin.nodeId);
      if (node != null) {
        // Pin position is relative to node's top-left + node position + canvas offset
        return node.position +
            const Offset(8, 8) + // padding TODO: remove
            pin.relativePosition +
            const Offset(6, 6); // center location
      }
    }
    return null;
  }

  void handleScrollZoom(Offset mousePos, double scrollDelta) {
    final worldPos = screenToWorld(mousePos);
    final factor = scrollDelta < 0 ? 1.1 : 0.9;
    final newScale = (scale * factor).clamp(0.25, 4.0);
    _scale = newScale;
    _canvasOffset = worldPos - mousePos / scale;
    notifyListeners();
  }

  Offset screenToWorld(Offset screen) => screen / scale + canvasOffset;

  Offset worldToScreen(Offset world) => (world - canvasOffset) * scale;

  Pin? findPinByKey(PinKey key) {
    return _blueprintState.findPinByKey(key);
  }

  Node? findNodeById(String id) {
    return _blueprintState.findNodeById(id);
  }
}
