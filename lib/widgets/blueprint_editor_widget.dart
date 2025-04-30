import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/state/blueprint_state.dart';
import 'package:unreal_editor/widgets/context_menu_overlay.dart';
import 'package:unreal_editor/widgets/multi_child_node_widget.dart';
import 'dart:async';

import '../models/node.dart';
import '../models/pin.dart';
import '../painters/connection_painter.dart';
import '../painters/grid_painter.dart';
import '../state/blueprint_editor_state.dart';
import 'node_widget.dart';

class BlueprintEditorWidget extends StatefulWidget {
  const BlueprintEditorWidget({super.key});

  @override
  State<BlueprintEditorWidget> createState() => _BlueprintEditorWidgetState();
}

class _BlueprintEditorWidgetState extends State<BlueprintEditorWidget> {
  Offset _lastPanPosition = Offset.zero;
  Timer? _autoScrollTimer;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _handleNodeDrag(
      BuildContext context, DragUpdateDetails details, String nodeId) {
    final editorState = context.read<BlueprintEditorState>();
    final blueprintState = context.read<BlueprintState>();
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
    final blueprintState = context.watch<BlueprintState>();
    return ListenableBuilder(
      listenable: editorState,
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => editorState.hideContextMenu(),
          onPanStart: (_) => editorState.hideContextMenu(),
          child: Stack(
            children: [
              Listener(
                onPointerSignal: _handleScrollZoom,
                child: MouseRegion(
                  onHover: (event) {
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
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(
                        details.globalPosition,
                      );
                      editorState.deselectAllNodes();
                    },
                    onTap: () => editorState.deselectAllNodes(),
                    onTapUp: (details) {
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
                        reversed: true,
                      );

                      if (hitConnection != null) {
                        blueprintState.removeConnection(hitConnection);
                        return;
                      }

                      editorState.deselectAllNodes();
                      editorState.hideContextMenu();
                    },
                    onPanUpdate: (details) {
                      final delta = details.globalPosition - _lastPanPosition;
                      if (editorState.nodes
                              .where((n) => n.isSelected)
                              .isEmpty &&
                          editorState.dragStartPinKey == null) {
                        editorState.panCanvas(delta);
                      }
                      _lastPanPosition = details.globalPosition;
                    },
                    onPanEnd: (details) {
                      if (editorState.dragStartPinKey != null) {
                        editorState.endDraggingConnection();
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints.expand(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
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
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blueGrey,
                                    width: 3,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: GridPainter(
                                          editorState.canvasOffset,
                                          editorState.scale,
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: ConnectionPainter(
                                          editorState: editorState,
                                        ),
                                      ),
                                    ),
                                    ...editorState.nodes.map(
                                      (node) => Positioned(
                                        key: ValueKey(
                                          node.id,
                                        ),
                                        left: node.position.dx,
                                        top: node.position.dy,
                                        child: node.matchType(
                                          static: () => NodeWidget(
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
                                          multiOutput: () =>
                                              MultiOutputNodeWidget(
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
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "${editorState.canvasOffset}\nScale: ${editorState.scale}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (editorState.contextMenuPosition != null)
                Positioned(
                  left: editorState.contextMenuPosition!.dx,
                  top: editorState.contextMenuPosition!.dy,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: ContextMenuOverlay(
                      onDismiss: () => editorState.hideContextMenu(),
                      onAddNode: () => addNode(
                        name: "New Node",
                        type: NodeType.static,
                        inputPins: (id) => [
                          Pin(
                            nodeId: id,
                            label: 'In',
                            direction: PinDirection.input,
                            type: PinType.exec,
                          ),
                          Pin(
                            nodeId: id,
                            label: 'In2',
                            direction: PinDirection.input,
                            type: PinType.value,
                          ),
                        ],
                        outputPins: (id) => [
                          Pin(
                            nodeId: id,
                            label: 'Out',
                            direction: PinDirection.output,
                            type: PinType.exec,
                          ),
                          Pin(
                            nodeId: id,
                            label: 'Out2',
                            direction: PinDirection.output,
                            type: PinType.value,
                          ),
                        ],
                      ),
                      onAddColumnNode: () => addNode(
                          name: "Column",
                          type: NodeType.multiOutput,
                          inputPins: (id) => [
                                Pin(
                                  nodeId: id,
                                  label: 'In',
                                  direction: PinDirection.input,
                                  type: PinType.render,
                                ),
                              ],
                          outputPins: (id) => [
                                Pin(
                                  nodeId: id,
                                  label: 'child1',
                                  direction: PinDirection.output,
                                  type: PinType.render,
                                ),
                                Pin(
                                  nodeId: id,
                                  label: 'child2',
                                  direction: PinDirection.output,
                                  type: PinType.render,
                                ),
                              ],
                          renderer: ColumnNodeRenderer()),
                      onAddRowNode: () => addNode(
                          name: "Row",
                          type: NodeType.multiOutput,
                          inputPins: (id) => [
                                Pin(
                                  nodeId: id,
                                  label: 'In',
                                  direction: PinDirection.input,
                                  type: PinType.render,
                                ),
                              ],
                          outputPins: (id) => [
                                Pin(
                                  nodeId: id,
                                  label: 'child1',
                                  direction: PinDirection.output,
                                  type: PinType.render,
                                ),
                                Pin(
                                  nodeId: id,
                                  label: 'child2',
                                  direction: PinDirection.output,
                                  type: PinType.render,
                                ),
                              ],
                          renderer: RowNodeRenderer()),
                      onAddTextNode: () => addNode(
                        name: "Text",
                        type: NodeType.static,
                        inputPins: (id) => [
                          Pin(
                            nodeId: id,
                            label: 'In',
                            direction: PinDirection.input,
                            type: PinType.render,
                          ),
                          Pin(
                            nodeId: id,
                            label: 'Text',
                            direction: PinDirection.input,
                            type: PinType.value,
                          ),
                        ],
                        outputPins: (id) => [],
                        renderer: TextNodeRenderer(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void addNode({
    required String name,
    required NodeType type,
    required List<Pin> Function(String id) inputPins,
    required List<Pin> Function(String id) outputPins,
    NodeRenderer? renderer,
  }) {
    var editorState = context.read<BlueprintEditorState>();
    if (editorState.contextMenuPosition == null) return;

    final newNodeId = 'node${editorState.nodes.length + 1}';
    final worldPos = editorState.screenToWorld(
      editorState.contextMenuPosition!,
    );
    editorState.addNode(
      Node(
        id: newNodeId,
        type: type,
        renderer: renderer,
        title: '$name ${editorState.nodes.length + 1}',
        position: worldPos,
        inputPins: inputPins(newNodeId),
        outputPins: outputPins(newNodeId),
      ),
    );
    editorState.hideContextMenu();
  }

  void _handleScrollZoom(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final mousePos = e.localPosition;
    final editorState = context.read<BlueprintEditorState>();
    editorState.handleScrollZoom(mousePos, e.scrollDelta.dy);
  }
}
