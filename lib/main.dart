import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/painters/connection_painter.dart';
import 'package:unreal_editor/painters/grid_painter.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import 'package:unreal_editor/widgets/node_widget.dart';

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
      home: ChangeNotifierProvider(
        create: (context) => BlueprintEditorState(),
        child: const BlueprintEditorPage(),
      ),
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
  Offset _lastPanPosition = Offset.zero;
  Timer? _autoScrollTimer;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _handleNodeDrag(
    BuildContext context,
    DragUpdateDetails details,
    String nodeId,
  ) {
    final editorState = context.read<BlueprintEditorState>();
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;
    final Offset position = details.globalPosition;
    const scrollArea = 60.0; // pixels from edge that triggers scrolling
    const scrollSpeed = 15.0; // pixels per scroll

    Offset scrollDelta = Offset.zero;

    // Check edges and calculate scroll delta
    if (position.dx < scrollArea) {
      scrollDelta += const Offset(scrollSpeed, 0);
    } else if (position.dx > size.width - scrollArea) {
      scrollDelta += const Offset(-scrollSpeed, 0);
    }

    if (position.dy < scrollArea) {
      scrollDelta += const Offset(0, scrollSpeed);
    } else if (position.dy > size.height - scrollArea) {
      scrollDelta += const Offset(0, -scrollSpeed);
    }

    // If we're near an edge, start auto-scrolling
    if (scrollDelta != Offset.zero) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
        timer,
      ) {
        editorState.panCanvas(scrollDelta);
        // Also move the node to maintain relative position
        editorState.moveNode(nodeId, -scrollDelta);
        print(
          "Auto-scrolling: $scrollDelta, new node position: ${editorState.findNodeById(nodeId)?.position}",
        );
      });
    } else {
      _autoScrollTimer?.cancel();
    }

    // Move the node with the drag
    editorState.moveNode(nodeId, details.delta);
    print(
      "moving, new node position: ${editorState.findNodeById(nodeId)?.position}",
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = context.watch<BlueprintEditorState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint Editor'),
        actions: [],
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
                  child: MouseRegion(
                    onHover: (event) {
                      // check if we hover over a connection
                      final painter = ConnectionPainter(
                        editorState: editorState,
                      );
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPosition = event.localPosition;
                      final hitConnection = painter.getConnectionAtPoint(
                        editorState.screenToWorld(localPosition),
                        reversed: true,
                      );

                      if (hitConnection != null) {
                        editorState.setHoveredConnection(hitConnection);
                        return;
                      }
                      editorState.setHoveredConnection(null);
                    },
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
                        editorState.deselectAllNodes();
                      },
                      onTap: () => editorState.deselectAllNodes(),
                      onTapUp: (details) {
                        // Check for connection hits first
                        final painter = ConnectionPainter(
                          editorState: editorState,
                        );
                        final RenderBox box =
                            context.findRenderObject() as RenderBox;
                        final localPosition = box.globalToLocal(
                          details.globalPosition,
                        );
                        final hitConnection = painter.getConnectionAtPoint(
                          editorState.screenToWorld(localPosition),
                        );

                        if (hitConnection != null) {
                          editorState.removeConnection(hitConnection);
                          return;
                        }

                        editorState.deselectAllNodes();
                        editorState.hideContextMenu();
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
                                transform: Matrix4.identity()
                                  ..scale(editorState.scale)
                                  ..translate(
                                    -editorState.canvasOffset.dx,
                                    -editorState.canvasOffset.dy,
                                  ),
                                child: Container(
                                  width: 4000,
                                  height: 4000,
                                  // decoration a highlighted border magestic
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.blueGrey,
                                      width: 3,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Background Grid (Optional)
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: GridPainter(
                                            editorState.canvasOffset,
                                            editorState.scale,
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
                                            onDragUpdate: (details) =>
                                                _handleNodeDrag(
                                              context,
                                              details,
                                              node.id,
                                            ),
                                            onDragEnd: (details) =>
                                                _autoScrollTimer?.cancel(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "${editorState.canvasOffset}\nScale: ${editorState.scale}",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 40,
                              ),
                            ),
                          ],
                        ),
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
                          final worldPos = editorState.screenToWorld(
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
                                  type: PinType.exec,
                                ),
                                Pin(
                                  nodeId: newNodeId,
                                  label: 'In2',
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
                                Pin(
                                  nodeId: newNodeId,
                                  label: 'Out2',
                                  direction: PinDirection.output,
                                  type: PinType.value,
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
    final editorState = context.read<BlueprintEditorState>();
    editorState.handleScrollZoom(mousePos, e.scrollDelta.dy);
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
