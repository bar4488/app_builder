import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/node.dart';
import 'models/pin.dart';
import 'painters/grid_painter.dart';
import 'painters/connection_painter.dart';
import 'widgets/node_widget.dart';
import 'state/blueprint_editor_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unreal Editor',
      theme: ThemeData.dark(),
      home: ChangeNotifierProvider(
        create: (_) => BlueprintEditorState(),
        child: const BlueprintEditor(),
      ),
    );
  }
}

class BlueprintEditor extends StatelessWidget {
  const BlueprintEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onSecondaryTapDown: (details) =>
                  _showContextMenu(context, details),
              child: const EditorCanvas(),
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final state = context.read<BlueprintEditorState>();
    final screenPosition = details.globalPosition;
    final canvasPosition = details.localPosition - state.pan;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        screenPosition.dx,
        screenPosition.dy,
        screenPosition.dx + 1,
        screenPosition.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: const Text('Add Print Node'),
          onTap: () {
            final node = Node(
              id: DateTime.now().toString(),
              type: 'Print String',
              position: canvasPosition,
              pins: [
                Pin(
                  nodeId: 'print',
                  label: 'Exec',
                  direction: PinDirection.input,
                  type: PinType.exec,
                ),
                Pin(
                  nodeId: 'print',
                  label: 'String',
                  direction: PinDirection.input,
                  type: PinType.value,
                ),
                Pin(
                  nodeId: 'print',
                  label: 'Exec',
                  direction: PinDirection.output,
                  type: PinType.exec,
                ),
              ],
            );
            state.addNode(node);
          },
        ),
      ],
    );
  }
}

class EditorCanvas extends StatelessWidget {
  const EditorCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BlueprintEditorState>(
      builder: (context, state, _) {
        final connectedPinIds = state.connections
            .expand((c) => [c.startPinKey.value, c.endPinKey.value])
            .toSet();

        return GestureDetector(
          onPanUpdate: (details) {
            state.updatePanZoom(state.pan + details.delta, state.zoom);
          },
          child: CustomPaint(
            painter: GridPainter(pan: state.pan, zoom: state.zoom),
            child: Stack(
              children: [
                ...state.nodes.map((node) {
                  return Positioned(
                    left: node.position.dx + state.pan.dx,
                    top: node.position.dy + state.pan.dy,
                    child: Draggable(
                      feedback: NodeWidget(
                        node: node,
                        onPinPressed: (_) {},
                        connectedPinIds: connectedPinIds,
                      ),
                      childWhenDragging: Container(),
                      onDragEnd: (details) {
                        final newPosition = node.position +
                            (details.offset - node.position - state.pan);
                        state.updateNodePosition(node, newPosition);
                      },
                      child: NodeWidget(
                        node: node,
                        onPinPressed: state.selectPin,
                        connectedPinIds: connectedPinIds,
                      ),
                    ),
                  );
                }),
                ...state.connections.map((connection) {
                  final startPin = state.nodes
                      .expand((n) => n.pins)
                      .firstWhere((p) => p.key == connection.startPinKey);
                  final endPin = state.nodes
                      .expand((n) => n.pins)
                      .firstWhere((p) => p.key == connection.endPinKey);

                  final startNode =
                      state.nodes.firstWhere((n) => n.pins.contains(startPin));
                  final endNode =
                      state.nodes.firstWhere((n) => n.pins.contains(endPin));

                  final startPoint = startNode.position +
                      startPin.relativePosition +
                      state.pan;
                  final endPoint =
                      endNode.position + endPin.relativePosition + state.pan;

                  return CustomPaint(
                    painter: ConnectionPainter(
                      startPoint: startPoint,
                      endPoint: endPoint,
                    ),
                  );
                }),
                if (state.selectedPin != null)
                  Consumer<BlueprintEditorState>(
                    builder: (context, state, _) {
                      final selectedPin = state.selectedPin!;
                      final node = state.nodes
                          .firstWhere((n) => n.pins.contains(selectedPin));
                      final startPoint = node.position +
                          selectedPin.relativePosition +
                          state.pan;

                      return CustomPaint(
                        painter: ConnectionPainter(
                          startPoint: startPoint,
                          endPoint: state.pan,
                          isPreview: true,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
