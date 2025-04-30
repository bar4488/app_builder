import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter/src/gestures/events.dart';

// Enum to define pin direction
enum PinDirection { input, output }

// Add Pin Type enum
enum PinType {
  exec, // Flow control
  value, // Data values
  render, // Visual/render data
}

// Unique key for identifying pins
class PinKey extends ValueKey<String> {
  const PinKey(String value) : super(value);
}

// --- Data Models ---

// Represents a connection between two pins
class Connection {
  final PinKey startPinKey;
  final PinKey endPinKey;
  // Store path for hit testing later if needed
  Path? path;

  Connection({required this.startPinKey, required this.endPinKey});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connection &&
          runtimeType == other.runtimeType &&
          startPinKey == other.startPinKey &&
          endPinKey == other.endPinKey;

  @override
  int get hashCode => startPinKey.hashCode ^ endPinKey.hashCode;
}

// Represents a connection pin on a node
class Pin {
  final PinKey key;
  final String nodeId;
  final String label;
  final PinDirection direction;
  final PinType type; // Add pin type
  Offset relativePosition = Offset.zero;

  Pin({
    required this.nodeId,
    required this.label,
    required this.direction,
    required this.type,
  }) : key = PinKey('${nodeId}_${label}_${direction.name}');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pin && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;
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

  Node({
    required this.id,
    required this.title,
    required this.position,
    this.size = const Size(180, 100), // Default size
    List<Pin>? inputPins,
    List<Pin>? outputPins,
    this.isSelected = false,
  }) : inputPins = inputPins ?? [],
       outputPins = outputPins ?? [];

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
  }

  Rect get rect =>
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

// --- ChangeNotifier for State Management ---

class BlueprintEditorState extends ChangeNotifier {
  final List<Node> _nodes = [];
  final Set<Connection> _connections = {};
  Offset _canvasOffset = Offset.zero; // For panning

  // For drawing temporary connection line
  Offset? _dragStartPinPosition;
  Offset? _dragCurrentPosition;
  PinKey? _dragStartPinKey;
  PinDirection? dragStartPinDirection;

  List<Node> get nodes => _nodes;
  Set<Connection> get connections => _connections;
  Offset get canvasOffset => _canvasOffset;

  Offset? get dragStartPinPosition => _dragStartPinPosition;
  Offset? get dragCurrentPosition => _dragCurrentPosition;
  PinKey? get dragStartPinKey => _dragStartPinKey;

  PinKey? _currentHoverPinKey;
  PinKey? get currentHoverPinKey => _currentHoverPinKey;

  // Add these properties for context menu
  Offset? _contextMenuPosition;
  Offset? get contextMenuPosition => _contextMenuPosition;

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
    _nodes.add(node);
    notifyListeners();
  }

  void deleteNode(String nodeId) {
    _nodes.removeWhere((node) => node.id == nodeId);
    // Remove connections associated with the deleted node
    _connections.removeWhere(
      (conn) =>
          conn.startPinKey.value.startsWith(nodeId) ||
          conn.endPinKey.value.startsWith(nodeId),
    );
    notifyListeners();
  }

  void setHoverPinKey(PinKey? pinKey) {
    _currentHoverPinKey = pinKey;
    notifyListeners();
  }

  static const double stackWidth = 4000.0;
  static const double stackHeight = 4000.0;

  // Add helper method to constrain position
  Offset _constrainPosition(Offset position, Size nodeSize) {
    return Offset(
      position.dx.clamp(0, stackWidth - nodeSize.width),
      position.dy.clamp(0, stackHeight - nodeSize.height),
    );
  }

  void moveNode(String nodeId, Offset delta) {
    final node = _nodes.firstWhere(
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
      for (var node in _nodes) {
        node.isSelected = false;
      }
    }
    final node = _nodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => throw Exception("Node not found"),
    );
    node.isSelected = true; // Toggle selection could be added later
    notifyListeners();
  }

  void deselectAllNodes() {
    bool changed = false;
    for (var node in _nodes) {
      if (node.isSelected) {
        node.isSelected = false;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // --- Canvas Management ---
  void panCanvas(Offset delta) {
    _canvasOffset += delta;
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
      var startPin = findPinByKey(_dragStartPinKey!);
      var endPin = findPinByKey(endPinKey);

      if (startPin != null &&
          endPin != null &&
          startPin.direction != endPin.direction &&
          startPin.type == endPin.type) {
        // Add type check
        // Determine correct start/end based on direction
        final outputPinKey =
            (startPin.direction == PinDirection.output)
                ? _dragStartPinKey!
                : endPinKey;
        final inputPinKey =
            (startPin.direction == PinDirection.input)
                ? _dragStartPinKey!
                : endPinKey;

        _connections.removeWhere((conn) => conn.endPinKey == inputPinKey);
        _connections.add(
          Connection(startPinKey: outputPinKey, endPinKey: inputPinKey),
        );
      }
    }
    // Reset dragging state
    _dragStartPinKey = null;
    _dragStartPinPosition = null;
    _dragCurrentPosition = null;
    dragStartPinDirection = null;
    notifyListeners();
  }

  void removeConnection(Connection connection) {
    _connections.remove(connection);
    notifyListeners();
  }

  void removeConnectionsForPin(PinKey pinKey) {
    _connections.removeWhere(
      (conn) => conn.startPinKey == pinKey || conn.endPinKey == pinKey,
    );
    notifyListeners();
  }

  // --- Helpers ---
  Node? findNodeById(String id) {
    try {
      return _nodes.firstWhere((node) => node.id == id);
    } catch (e) {
      return null;
    }
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

  // Get the global position of a pin
  Offset? getPinGlobalPosition(PinKey pinKey) {
    final pin = findPinByKey(pinKey);
    if (pin != null) {
      final node = findNodeById(pin.nodeId);
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
}

// --- Main Application Widget ---

void main() {
  runApp(const BlueprintEditorApp());
}

class BlueprintEditorApp extends StatelessWidget {
  const BlueprintEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Blueprint Editor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
      ),
      home: const BlueprintEditorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Editor Page Widget ---

class BlueprintEditorPage extends StatefulWidget {
  const BlueprintEditorPage({super.key});

  @override
  State<BlueprintEditorPage> createState() => _BlueprintEditorPageState();
}

class _BlueprintEditorPageState extends State<BlueprintEditorPage> {
  final BlueprintEditorState editorState = BlueprintEditorState();
  Offset _lastPanPosition = Offset.zero;

  double _scale = 1.0; // For calculating pan delta

  @override
  void initState() {
    super.initState();
    // Add some initial nodes for demonstration
    editorState.addNode(
      Node(
        id: 'node1',
        title: 'Start Event',
        position: const Offset(100, 100),
        outputPins: [
          Pin(
            nodeId: 'node1',
            label: 'Exec Out',
            direction: PinDirection.output,
            type: PinType.exec,
          ),
        ],
      ),
    );
    editorState.addNode(
      Node(
        id: 'node2',
        title: 'Do Something',
        position: const Offset(400, 150),
        size: const Size(180, 120), // Different size
        inputPins: [
          Pin(
            nodeId: 'node2',
            label: 'Exec In',
            direction: PinDirection.input,
            type: PinType.exec,
          ),
        ],
        outputPins: [
          Pin(
            nodeId: 'node2',
            label: 'Exec Out',
            direction: PinDirection.output,
            type: PinType.exec,
          ),
          Pin(
            nodeId: 'node2',
            label: 'Value',
            direction: PinDirection.output,
            type: PinType.value,
          ),
        ],
      ),
    );
    editorState.addNode(
      Node(
        id: 'node3',
        title: 'Branch',
        position: const Offset(700, 100),
        size: const Size(180, 150), // Different size
        inputPins: [
          Pin(
            nodeId: 'node3',
            label: 'Exec In',
            direction: PinDirection.input,
            type: PinType.exec,
          ),
          Pin(
            nodeId: 'node3',
            label: 'Condition',
            direction: PinDirection.input,
            type: PinType.value,
          ),
        ],
        outputPins: [
          Pin(
            nodeId: 'node3',
            label: 'True',
            direction: PinDirection.output,
            type: PinType.exec,
          ),
          Pin(
            nodeId: 'node3',
            label: 'False',
            direction: PinDirection.output,
            type: PinType.exec,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Node (Example)',
            onPressed: () {
              final newNodeId = 'node${editorState.nodes.length + 1}';
              editorState.addNode(
                Node(
                  id: newNodeId,
                  title: 'New Node ${editorState.nodes.length + 1}',
                  // Place near center of viewport, accounting for pan
                  position: -editorState.canvasOffset + const Offset(200, 200),
                  inputPins: [
                    Pin(
                      nodeId: newNodeId,
                      label: 'In',
                      direction: PinDirection.input,
                      type: PinType.value,
                    ),
                  ],
                  outputPins: [
                    Pin(
                      nodeId: newNodeId,
                      label: 'Out',
                      direction: PinDirection.output,
                      type: PinType.exec,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: editorState,
        builder: (context, child) {
          return GestureDetector(
            // Add outer GestureDetector
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => editorState.hideContextMenu(),
            onPanStart: (_) => editorState.hideContextMenu(),
            child: Stack(
              children: [
                Listener(
                  onPointerSignal: _handleScrollZoom,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // Add right click handler
                    onSecondaryTapUp: (details) {
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(
                        details.globalPosition,
                      );
                      editorState.showContextMenu(localPosition);
                    },
                    onPanStart: (details) {
                      _lastPanPosition = details.globalPosition;
                      // Deselect nodes if clicking on background
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(
                        details.globalPosition,
                      );
                      bool hitNode = false;
                      // Check if click hit any node
                      for (final node in editorState.nodes) {
                        final nodeRect = node.rect.translate(
                          editorState.canvasOffset.dx,
                          editorState.canvasOffset.dy,
                        );
                        if (nodeRect.contains(localPosition)) {
                          hitNode = true;
                          break;
                        }
                      }
                      if (!hitNode) {
                        editorState.deselectAllNodes();
                      }
                    },
                    onPanUpdate: (details) {
                      final delta = details.globalPosition - _lastPanPosition;
                      // Only pan if not dragging a node (node drag handled separately)
                      // A bit simplified: Assumes if a node is selected, we might be dragging it.
                      // A more robust check would involve tracking which element received the onPanStart.
                      if (editorState.nodes
                              .where((n) => n.isSelected)
                              .isEmpty &&
                          editorState.dragStartPinKey == null) {
                        editorState.panCanvas(delta);
                      }
                      // Update connection drag position if active
                      // else if (editorState.dragStartPinKey != null) {
                      //   final RenderBox box = context.findRenderObject() as RenderBox;
                      //   final localPosition = box.globalToLocal(
                      //     details.globalPosition,
                      //   );
                      //   editorState.updateDraggingConnection(
                      //     localPosition,
                      //   ); // Use local position for drawing
                      // }
                      _lastPanPosition = details.globalPosition;
                    },
                    onPanEnd: (details) {
                      // Finalize connection drag if active
                      if (editorState.dragStartPinKey != null) {
                        // We need to check if the pan ended over a valid pin
                        // This requires hit-testing pins based on the final position.
                        // For simplicity now, we just end the drag. A real implementation
                        // needs to find the pin under the cursor here.
                        editorState
                            .endDraggingConnection(); // No end pin provided yet
                      }
                    },
                    child: Container(
                      color: Colors.amber,
                      constraints: BoxConstraints.expand(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            // clipBehavior: Clip.hardEdge,
                            top: 0,
                            left: 0,
                            width: 4000,
                            height: 4000,
                            child: Transform(
                              alignment: Alignment.topLeft,
                              transformHitTests: true,
                              transform:
                                  Matrix4.identity()
                                    ..translate(
                                      editorState.canvasOffset.dx,
                                      editorState.canvasOffset.dy,
                                    )
                                    ..scale(_scale),
                              child: SizedBox(
                                width: 4000,
                                height: 4000,
                                child: Stack(
                                  clipBehavior:
                                      Clip.none, // Allow nodes to be dragged partially off-screen
                                  children: [
                                    // Background Grid (Optional)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: GridPainter(
                                          editorState.canvasOffset,
                                          _scale,
                                        ),
                                      ),
                                    ),

                                    // Connection Lines Painter
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: ConnectionPainter(
                                          editorState: editorState,
                                        ),
                                      ),
                                    ),

                                    // Nodes
                                    ...editorState.nodes.map(
                                      (node) => Positioned(
                                        key: ValueKey(
                                          node.id,
                                        ), // Important for stable updates
                                        left: node.position.dx,
                                        top: node.position.dy,
                                        child: NodeWidget(
                                          node: node,
                                          editorState: editorState,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "${editorState.canvasOffset}\nScale: ${_scale}",
                            style: TextStyle(color: Colors.black, fontSize: 40),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Add context menu overlay
                if (editorState.contextMenuPosition != null)
                  Positioned(
                    left: editorState.contextMenuPosition!.dx,
                    top: editorState.contextMenuPosition!.dy,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap:
                          () {}, // Prevent click from reaching outer GestureDetector
                      child: ContextMenuOverlay(
                        onDismiss: () => editorState.hideContextMenu(),
                        onAddNode: () {
                          final newNodeId =
                              'node${editorState.nodes.length + 1}';
                          // Convert screen position to world position
                          final worldPos = _screenToWorld(
                            editorState.contextMenuPosition!,
                          );
                          editorState.addNode(
                            Node(
                              id: newNodeId,
                              title: 'New Node ${editorState.nodes.length + 1}',
                              position: worldPos,
                              inputPins: [
                                Pin(
                                  nodeId: newNodeId,
                                  label: 'In',
                                  direction: PinDirection.input,
                                  type: PinType.value,
                                ),
                              ],
                              outputPins: [
                                Pin(
                                  nodeId: newNodeId,
                                  label: 'Out',
                                  direction: PinDirection.output,
                                  type: PinType.exec,
                                ),
                              ],
                            ),
                          );
                          editorState.hideContextMenu();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleScrollZoom(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final mousePos = e.localPosition;
    final worldPos = _screenToWorld(mousePos);
    final factor = e.scrollDelta.dy < 0 ? 1.1 : 0.9;
    final newScale = (_scale * factor).clamp(0.25, 4.0);
    setState(() {
      _scale = newScale;
      editorState._canvasOffset = mousePos - worldPos * _scale;
    });
  }

  Offset _screenToWorld(Offset screen) =>
      (screen - editorState._canvasOffset) / _scale;

  Offset _worldToScreen(Offset world) =>
      (world * _scale) + editorState._canvasOffset;
}

// --- Node Widget ---

class NodeWidget extends StatelessWidget {
  final Node node;
  final BlueprintEditorState editorState;

  const NodeWidget({super.key, required this.node, required this.editorState});

  @override
  Widget build(BuildContext context) {
    // Recalculate pin positions if needed (e.g., if size changes, though fixed for now)
    // node.calculatePinPositions(); // Usually called when node created/resized
    var padding = 8;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          alignment: Alignment.center,
          width: node.size.width + padding * 2,
          height: node.size.height + padding * 2,
          color: Colors.white54,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              // Select node on drag start
              editorState.selectNode(
                node.id,
                multiSelect: false,
              ); // Basic single selection
            },
            onPanUpdate: (details) {
              // Move the selected node
              editorState.moveNode(node.id, details.delta);
            },
            child: Material(
              elevation: node.isSelected ? 8.0 : 4.0,
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                width: node.size.width,
                height: node.size.height,
                decoration: BoxDecoration(
                  color:
                      node.isSelected
                          ? Colors.blueGrey[700]
                          : Colors.blueGrey[900],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color:
                        node.isSelected
                            ? Colors.lightBlueAccent
                            : Colors.grey[700]!,
                    width: node.isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Stack(
                  clipBehavior:
                      Clip.none, // Allow pins to draw outside bounds slightly
                  children: [
                    // Node Title
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(
                              7.0,
                            ), // Match container radius
                            topRight: Radius.circular(7.0),
                          ),
                        ),
                        child: Text(
                          node.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Input Pins
        ...node.inputPins.map(
          (pin) => Positioned(
            left:
                padding +
                pin.relativePosition.dx -
                6, // Center the pin visually
            top: padding + pin.relativePosition.dy,
            child: PinWidget(pin: pin, editorState: editorState),
          ),
        ),
        // Output Pins
        ...node.outputPins.map(
          (pin) => Positioned(
            left:
                padding +
                pin.relativePosition.dx -
                6, // Center the pin visually
            top: padding + pin.relativePosition.dy,
            child: PinWidget(pin: pin, editorState: editorState),
          ),
        ),
      ],
    );
  }
}

// --- Pin Widget ---

class PinWidget extends StatelessWidget {
  final Pin pin;
  final BlueprintEditorState editorState;

  const PinWidget({
    required this.pin,
    required this.editorState,
    // Use the PinKey for the widget key for stable identification
    super.key, // Key is derived from pin.key in NodeWidget map
  });

  Color _getPinColor(PinType type, bool isConnected, bool isPotentialTarget) {
    if (isPotentialTarget) return Colors.yellow;

    switch (type) {
      case PinType.exec:
        return isConnected ? Colors.green : Colors.green.withOpacity(0.3);
      case PinType.value:
        return isConnected ? Colors.cyan : Colors.cyan.withOpacity(0.3);
      case PinType.render:
        return isConnected ? Colors.purple : Colors.purple.withOpacity(0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double pinSize = 12.0;
    const double interactionPadding = 8.0; // Increase tappable area

    // Check if this pin is connected
    bool isConnected = editorState.connections.any(
      (conn) => conn.startPinKey == pin.key || conn.endPinKey == pin.key,
    );

    // Check if this pin is the potential end target of a drag
    bool isPotentialTarget = false;
    if (editorState.dragStartPinKey != null &&
        editorState.dragStartPinKey != pin.key) {
      final startPin = editorState.findPinByKey(editorState.dragStartPinKey!);
      // Can only connect output to input or vice-versa
      if (startPin != null && startPin.direction != pin.direction) {
        // Check if mouse is over this pin during drag
        final RenderBox? pinRenderBox =
            context.findRenderObject() as RenderBox?;
        if (pinRenderBox != null && editorState.dragCurrentPosition != null) {
          final pinGlobalPos = pinRenderBox.localToGlobal(Offset.zero);
          final pinRect = Rect.fromLTWH(
            pinGlobalPos.dx - interactionPadding,
            pinGlobalPos.dy - interactionPadding,
            pinSize + interactionPadding * 2,
            pinSize + interactionPadding * 2,
          );
          // Convert dragCurrentPosition (local to stack) to global
          final RenderBox stackRenderBox =
              editorState
                      .findNodeById(pin.nodeId)!
                      .isSelected // Hacky way to get stack context, improve this
                  ? context.findAncestorRenderObjectOfType<RenderBox>()!
                  : context
                      .findAncestorRenderObjectOfType<
                        RenderBox
                      >()!; // Find the main Stack's RenderBox

          // Need global position of the drag point for accurate hit test
          // This part is tricky without a global coordinate system readily available for the drag point
          // For now, we'll skip precise hover detection and rely on onPanEnd logic later.
          // A better approach involves using global coordinates consistently or a dedicated hit-testing mechanism.

          // Placeholder: Assume hover if close enough (needs refinement)
          // final dragGlobalPos = stackRenderBox.localToGlobal(editorState.dragCurrentPosition!);
          // isPotentialTarget = pinRect.contains(dragGlobalPos);
        }
      }
    }

    return GestureDetector(
      // Add right click handler
      onSecondaryTapUp: (details) {
        editorState.removeConnectionsForPin(pin.key);
      },
      // --- Connection Drag Handling ---
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        // Get the global position of the center of the pin widget
        var pinPosition = editorState.getPinGlobalPosition(pin.key)!;
        var mousePosition =
            pinPosition + details.localPosition - Offset(pinSize, pinSize / 2);

        editorState.startDraggingConnection(
          pin.key,
          pinPosition,
          mousePosition,
          pin.direction,
        );
      },
      onPanUpdate: (details) {
        editorState.updateDraggingConnection(delta: details.delta);
      },
      onPanEnd: (details) {
        print("Pin drag ended");
        editorState.endDraggingConnection();
      },
      child: Tooltip(
        message: "${pin.label} (${pin.direction.name}, ${pin.type.name})",
        child: MouseRegion(
          onEnter: (event) {
            print("Entering pin: ${pin.label}");
            editorState.setHoverPinKey(pin.key);
          },
          onHover: (event) {
            print("Hovering over pin: ${pin.label}");
            editorState.setHoverPinKey(pin.key);
          },
          onExit: (event) {
            print("Exiting pin: ${pin.label}");
            editorState.setHoverPinKey(null);
          },
          child: Container(
            width: pinSize,
            height: pinSize,
            decoration: BoxDecoration(
              color: _getPinColor(pin.type, isConnected, isPotentialTarget),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  // Need access to the last global position from the main gesture detector
  // This should be passed down or accessed via the state.
  // For simplicity, accessing a hypothetical global variable or passing through state.
  // Let's assume _lastPanPosition from _BlueprintEditorPageState is accessible here (it's not directly).
  // This highlights the need for better state management or passing callbacks/data down.
  // We'll use the editorState's drag position for now, assuming it's updated globally.
  Offset get _lastPanPosition =>
      editorState.dragCurrentPosition ?? Offset.zero; // Approximation
}

// --- Custom Painter for Connections ---

class ConnectionPainter extends CustomPainter {
  final BlueprintEditorState editorState;

  ConnectionPainter({required this.editorState}) : super(repaint: editorState);

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Draw existing connections
    for (final connection in editorState.connections) {
      final startPin = editorState.findPinByKey(connection.startPinKey);
      final endPin = editorState.findPinByKey(connection.endPinKey);

      if (startPin == null || endPin == null) continue;

      final startPinPos = editorState.getPinGlobalPosition(
        connection.startPinKey,
      );
      final endPinPos = editorState.getPinGlobalPosition(connection.endPinKey);

      if (startPinPos != null && endPinPos != null) {
        final path = _buildPath(startPinPos, endPinPos);
        connection.path = path;

        // Get color based on pin type
        Color lineColor;
        switch (startPin.type) {
          case PinType.exec:
            lineColor = Colors.green;
            break;
          case PinType.value:
            lineColor = Colors.cyan;
            break;
          case PinType.render:
            lineColor = Colors.purple;
            break;
        }

        final paint =
            Paint()
              ..color = lineColor
              ..strokeWidth = 2.5
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;

        // Draw shadow first
        canvas.drawPath(path, shadowPaint);
        // Draw connection line
        canvas.drawPath(path, paint);
      }
    }

    // Draw temporary connection line while dragging
    if (editorState.dragStartPinPosition != null &&
        editorState.dragCurrentPosition != null) {
      final startPos = editorState.dragStartPinPosition!;
      final endPos = editorState.dragCurrentPosition!;
      final tempPath = _buildPath(
        startPos,
        endPos,
        editorState.dragStartPinDirection,
      );

      // Draw shadow first
      canvas.drawPath(tempPath, shadowPaint);
      // Draw temp line
      canvas.drawPath(
        tempPath,
        Paint()
          ..color = Colors.yellowAccent
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      ); // Use a distinct color
    }
  }

  Path _buildPath(Offset start, Offset end, [PinDirection? startDirection]) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Calculate control points for a Bezier curve
    // Adjust curve based on pin direction if known (makes output curves go out first)
    double dx =
        (end.dx - start.dx).abs() * 0.6; // Horizontal distance influence
    double dy =
        (end.dy - start.dy).abs() *
        0.1; // Vertical distance influence (less impact)

    Offset ctrl1, ctrl2;

    if (startDirection == PinDirection.output ||
        (startDirection == null && start.dx < end.dx)) {
      // Primarily dragging rightwards or from an output pin
      ctrl1 = Offset(start.dx + dx, start.dy + dy);
      ctrl2 = Offset(end.dx - dx, end.dy - dy);
    } else {
      // Primarily dragging leftwards or from an input pin
      ctrl1 = Offset(start.dx - dx, start.dy - dy);
      ctrl2 = Offset(end.dx + dx, end.dy + dy);
    }

    // Clamp control points to prevent extreme curves if start/end are very close vertically
    ctrl1 = Offset(
      ctrl1.dx,
      ctrl1.dy.clamp(
        math.min(start.dy, end.dy) - 50,
        math.max(start.dy, end.dy) + 50,
      ),
    );
    ctrl2 = Offset(
      ctrl2.dx,
      ctrl2.dy.clamp(
        math.min(start.dy, end.dy) - 50,
        math.max(start.dy, end.dy) + 50,
      ),
    );

    path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    // Repaint whenever the editor state changes (nodes move, connections change, etc.)
    return true; // Simplest approach for now
  }
}

// --- Custom Painter for Background Grid ---

class GridPainter extends CustomPainter {
  final Offset offset; // Canvas pan offset
  final double scale; // Canvas pan offset
  final double majorGridStep = 100.0;
  final double minorGridStep = 20.0;

  GridPainter(this.offset, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final majorPaint =
        Paint()
          ..color =
              Colors.grey[800]! // Darker grey for major lines
          ..strokeWidth = 0.8;

    final minorPaint =
        Paint()
          ..color =
              Colors.grey[850]! // Even darker/subtler grey for minor lines
          ..strokeWidth = 0.5;

    // Calculate the start and end points based on the canvas size and offset
    // Adjust grid lines based on the canvas offset to create panning effect

    Offset screenZero = _screenToWorld(Offset.zero);
    Offset screenMax = _screenToWorld(Offset(size.width, size.height));

    final double startX =
        (screenZero.dx ~/ majorGridStep).toDouble() * majorGridStep;
    final double startY =
        (screenZero.dy ~/ majorGridStep).toDouble() * majorGridStep;
    final double startXMinor =
        (screenZero.dx ~/ minorGridStep).toDouble() * minorGridStep;
    final double startYMinor =
        (screenZero.dy ~/ minorGridStep).toDouble() * minorGridStep;
    // Draw minor grid lines
    for (double x = startXMinor; x < screenMax.dx; x += minorGridStep) {
      canvas.drawLine(
        Offset(x, screenZero.dy),
        Offset(x, screenMax.dy),
        minorPaint,
      );
    }
    for (double y = startYMinor; y < screenMax.dy; y += minorGridStep) {
      canvas.drawLine(
        Offset(screenZero.dx, y),
        Offset(screenMax.dx, y),
        minorPaint,
      );
    }

    // Draw major grid lines (over minor lines)
    for (double x = startX; x < screenMax.dx; x += majorGridStep) {
      canvas.drawLine(
        Offset(x, screenZero.dy),
        Offset(x, screenMax.dy),
        majorPaint,
      );
    }
    for (double y = startY; y < screenMax.dy; y += majorGridStep) {
      canvas.drawLine(
        Offset(screenZero.dx, y),
        Offset(screenMax.dx, y),
        majorPaint,
      );
    }
  }

  // screen to world
  Offset _screenToWorld(Offset screen) => (screen - offset) / scale;

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    // Repaint only if the offset changes
    return oldDelegate.offset != offset;
  }
}

class ContextMenuOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onAddNode;

  const ContextMenuOverlay({
    super.key,
    required this.onDismiss,
    required this.onAddNode,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(4),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Node'),
              onTap: onAddNode,
            ),
          ],
        ),
      ),
    );
  }
}
