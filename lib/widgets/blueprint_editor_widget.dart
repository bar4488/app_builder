import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/models/nodes.dart';
import 'package:unreal_editor/state/blueprint_state.dart';
import 'package:unreal_editor/widgets/context_menu_overlay.dart';
import 'dart:async';

import '../models/node.dart';
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
    _focusNode.dispose();
    super.dispose();
  }

  void _handleNodeDrag(
      BuildContext context, DragUpdateDetails details, String nodeId) {
    final editorState = context.read<BlueprintEditorState>();
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;
    final node = editorState.findNodeById(nodeId)!;
    final Offset position = editorState.worldToScreen(node.position +
        Offset(node.padding + 4, node.padding + 4) +
        details.localPosition);
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
        editorState.moveSelectedNodes(-scrollDelta / editorState.scale);
      });
    } else {
      _autoScrollTimer?.cancel();
    }

    // Move the node with the drag
    editorState.moveSelectedNodes(details.delta);
  }

  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final editorState = context.watch<BlueprintEditorState>();
    final blueprintState = context.watch<BlueprintState>();
    return ListenableBuilder(
      listenable: editorState,
      builder: (context, child) {
        return KeyboardListener(
          focusNode: editorState.focusNode,
          autofocus: true,
          onKeyEvent: (keyEvent) {
            if (keyEvent is KeyDownEvent &&
                keyEvent.logicalKey == LogicalKeyboardKey.escape) {
              editorState.deselectAllNodes();
              editorState.hideContextMenu();
            }
            // delete
            if (keyEvent is KeyDownEvent &&
                keyEvent.logicalKey == LogicalKeyboardKey.delete) {
              editorState.deleteSelectedNodes();
            }
          },
          child: GestureDetector(
            onTapDown: (details) => _focusNode.requestFocus(),
            child: Stack(
              children: [
                Listener(
                  onPointerSignal: _handleScrollZoom,
                  child: MouseRegion(
                    onHover: (event) {
                      final painter = ConnectionPainter(
                        editorState: editorState,
                      );
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
                    child: RawGestureDetector(
                      gestures: {
                        PanGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                                PanGestureRecognizer>(
                          () => PanGestureRecognizer(
                            debugOwner: this,
                            // This recognizer accepts any button press made with a secondary button.
                            allowedButtonsFilter: (int buttons) =>
                                buttons & kSecondaryButton != 0,
                          ),
                          (PanGestureRecognizer instance) {
                            instance
                              ..dragStartBehavior = DragStartBehavior.down
                              ..onStart = (details) {
                                _lastPanPosition = details.globalPosition;
                                // editorState.deselectAllNodes();
                                editorState.hideContextMenu();
                              }
                              ..onUpdate = (details) {
                                final delta =
                                    details.globalPosition - _lastPanPosition;
                                editorState.panCanvas(delta);
                                _lastPanPosition = details.globalPosition;
                              };
                          },
                        ),
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
                        onTapDown: (_) => editorState.hideContextMenu(),
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
                        onPanStart: (details) {
                          editorState.startSelection(
                            details.localPosition,
                          );
                        },
                        onPanUpdate: (details) {
                          print(
                              "pan update position: ${details.globalPosition}, local: ${details.localPosition}");
                          editorState.updateSelection(
                            details.localPosition,
                          );
                        },
                        onPanCancel: () {
                          // editorState.deselectAllNodes();
                        },
                        onPanEnd: (details) {
                          editorState.endSelection();
                        },
                        child: Container(
                          constraints: const BoxConstraints.expand(),
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
                                        if (editorState.selectionRect != null)
                                          Positioned.fromRect(
                                            rect: editorState.selectionRect!,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.blue,
                                                  width: 2,
                                                ),
                                                color: Colors.blue
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: Text(
                                  "${editorState.canvasOffset}\nScale: ${editorState.scale}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                      // onTapDown: (details) {
                      //   editorState.disableContextMenuHide();
                      // },
                      // onTapUp: (details) {
                      //   editorState.enableContextMenuHide();
                      // },
                      // onTapCancel: () => editorState.enableContextMenuHide(),
                      child: ContextMenuOverlay(
                        onDismiss: () => editorState.hideContextMenu(),
                        onAddColumnNode: () => addNode(
                          node: (id, position) => ColumnNode(
                            id: id,
                            position: position,
                          ),
                        ),
                        onAddRowNode: () => addNode(
                          node: (id, position) => RowNode(
                            id: id,
                            position: position,
                          ),
                        ),
                        onAddTextNode: () => addNode(
                          node: (id, position) => TextNode(
                            id: id,
                            position: position,
                          ),
                        ),
                        onAddStringNode: () => addNode(
                          node: (id, position) => StringNode(
                            id: id,
                            position: position,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void addNode({
    required Node Function(String id, Offset position) node,
  }) {
    var editorState = context.read<BlueprintEditorState>();
    if (editorState.contextMenuPosition == null) return;

    final newNodeId = 'node${editorState.nodes.length + 1}';
    final worldPos = editorState.screenToWorld(
      editorState.contextMenuPosition!,
    );
    editorState.addNode(
      node(newNodeId, worldPos),
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
