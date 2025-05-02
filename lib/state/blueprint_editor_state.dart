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
  Pin? _dragStartPin;
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
  Pin? get dragStartPin => _dragStartPin;

  Pin? _currentHoverPin;
  Pin? get currentHoverPin => _currentHoverPin;

  // Add these properties for context menu
  Offset? _contextMenuPosition;
  bool _disableContextMenuHide = false;
  Offset? get contextMenuPosition => _contextMenuPosition;

  static const double stackWidth = 4000.0;
  static const double stackHeight = 4000.0;

  Connection? _hoveredConnection;
  Connection? get hoveredConnection => _hoveredConnection;

  // errors map
  final Map<String, String?> _nodeErrors = {};

  Node? selectedNode;

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

  void disableContextMenuHide() {
    _disableContextMenuHide = true;
  }

  void enableContextMenuHide() {
    _disableContextMenuHide = false;
  }

  void hideContextMenu() {
    if (_disableContextMenuHide) return;
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

  void setHoverPinKey(Pin? pin) {
    _currentHoverPin = pin;
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

  void deselectNode(String nodeId) {
    final node = findNodeById(nodeId)!;
    node.isSelected = false;
    selectedNode = null;
    notifyListeners();
  }

  void selectNode(String nodeId, {bool multiSelect = false}) {
    final node = findNodeById(nodeId)!;
    if (!multiSelect) {
      for (var node in nodes) {
        node.isSelected = false;
      }
      selectedNode = node; // only save selected node in case of single select
    } else {
      selectedNode = null; // Deselect if already selected
    }
    node.isSelected = true; // Toggle selection could be added later
    notifyListeners();
  }

  void deselectAllNodes() {
    bool changed = false;
    selectedNode = null;
    for (var node in nodes) {
      if (node.isSelected) {
        node.isSelected = false;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  String? getNodeError(String nodeId) {
    return _nodeErrors[nodeId];
  }

  void setNodeError(String nodeId, String? error) {
    _nodeErrors[nodeId] = error;
    notifyListeners();
  }

  void clearNodeErrors() {
    _nodeErrors.clear();
    notifyListeners();
  }

  // --- Canvas Management ---
  void panCanvas(Offset delta) {
    _canvasOffset -= delta / _scale;
    notifyListeners();
  }

  // --- Connection Management ---
  void startDraggingConnection(
    Pin pin,
    Offset startPosition,
    Offset mousePosition,
    PinDirection direction,
  ) {
    _dragStartPin = pin;
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
    var endPinKey = currentHoverPin;
    if (_dragStartPin != null &&
        endPinKey != null &&
        _dragStartPin != endPinKey) {
      // Get both pins
      var startPin = _dragStartPin!;
      var endPin = endPinKey;

      if (startPin.direction != endPin.direction &&
          startPin.type == endPin.type) {
        // Add type check
        // Determine correct start/end based on direction
        final outputPin = (startPin.direction == PinDirection.output)
            ? _dragStartPin!
            : endPinKey;
        final inputPin = (startPin.direction == PinDirection.input)
            ? _dragStartPin!
            : endPinKey;

        var newConn = Connection(startPin: outputPin, endPin: inputPin);
        _blueprintState.addConnection(newConn);
      }
    }
    // Reset dragging state
    _dragStartPin = null;
    _dragStartPinPosition = null;
    _dragCurrentPosition = null;
    dragStartPinDirection = null;
    notifyListeners();
  }

  // Get the global position of a pin
  Offset? getPinGlobalPosition(Pin pin) {
    final node = _blueprintState.findNodeById(pin.nodeId);
    if (node != null) {
      // Pin position is relative to node's top-left + node position + canvas offset
      return node.position +
          const Offset(8, 8) + // padding TODO: remove
          pin.relativePosition +
          const Offset(6, 6); // center location
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
