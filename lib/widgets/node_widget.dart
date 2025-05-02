import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/models/connection.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import 'package:unreal_editor/state/blueprint_state.dart';
import 'package:unreal_editor/state/editor_window_state.dart';
import '../models/node.dart';
import 'pin_widget.dart';

class NodeWidget extends StatefulWidget {
  final Node node;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails)? onDragEnd;

  const NodeWidget({
    super.key,
    required this.node,
    required this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  FocusNode focusNode = FocusNode();

  int? tapMilliseconds;
  OutputRenderPin? hoveredPin;

  @override
  void initState() {
    if (widget.node is MultiOutputNode) {
      var node = widget.node as MultiOutputNode;
      hoveredPin = OutputRenderPin(
        nodeId: widget.node.id,
        label: "hover_render_pin",
        onRenderTargetChanged: (nodeId) {
          print("hovered pin changed to $nodeId");
          if (nodeId == null) {
            return;
          }
          var state = context.read<BlueprintState>();
          var pin = node.addOutputRenderPin();
          var other = state.findNodeById(nodeId)!;

          state.removeConnectionsForPin(hoveredPin!);
          state.addConnection(
            Connection(startPin: pin, endPin: other.inputRenderPin!),
          );
        },
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var padding = widget.node.padding;
    var editorState = context.read<BlueprintEditorState>();

    var nodeError = editorState.getNodeError(widget.node.id);

    return ListenableBuilder(
        listenable: widget.node,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                alignment: Alignment.center,
                width: widget.node.size.width + padding * 2,
                height: widget.node.size.height + padding * 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    editorState.selectNode(
                      widget.node.id,
                      multiSelect: false,
                    );
                  },
                  onPanUpdate: widget.onDragUpdate,
                  onPanEnd: widget.onDragEnd,
                  onTap: () {
                    var newTapMilli = DateTime.now().millisecondsSinceEpoch;
                    if (tapMilliseconds != null &&
                        newTapMilli - tapMilliseconds! < 300) {
                      context.read<EditorWindowState>().toggleRightDrawer();
                      editorState.selectNode(widget.node.id,
                          multiSelect: false);
                      tapMilliseconds = null;
                    } else {
                      tapMilliseconds = newTapMilli;
                      if (HardwareKeyboard.instance.isControlPressed) {
                        context
                            .read<BlueprintState>()
                            .switchHighlightColor(widget.node);
                      } else {
                        editorState.selectNode(widget.node.id,
                            multiSelect: false);
                      }
                    }
                  },
                  onSecondaryTap: () {
                    // remove highlight
                    if (HardwareKeyboard.instance.isControlPressed) {
                      context
                          .read<BlueprintState>()
                          .removeHighlightColor(widget.node);
                    } else {
                      editorState.deselectNode(widget.node.id);
                    }
                  },
                  child: Material(
                    elevation: widget.node.isSelected ||
                            widget.node.highlightColor != null
                        ? 8.0
                        : 4.0,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: widget.node.size.width,
                      height: widget.node.size.height,
                      decoration: BoxDecoration(
                        color: widget.node.isSelected
                            ? Colors.blueGrey[700]
                            : Colors.blueGrey[900],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: widget.node.isSelected
                              ? Colors.lightBlueAccent
                              : (widget.node.highlightColor ??
                                  Colors.grey[700]!),
                          width: widget.node.isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
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
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7.0),
                                  topRight: Radius.circular(7.0),
                                ),
                              ),
                              child: Text(
                                widget.node.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (widget.node is MultiOutputNode)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: MouseRegion(
                                onEnter: (event) {
                                  editorState.setHoverPin(hoveredPin);
                                },
                                onHover: (event) {
                                  editorState.setHoverPin(hoveredPin);
                                },
                                onExit: (event) {
                                  editorState.setHoverPin(null);
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    (widget.node as MultiOutputNode)
                                        .addOutputRenderPin();
                                    editorState.notifyListeners();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: editorState.currentHoverPin ==
                                              hoveredPin
                                          ? Colors.lightBlueAccent
                                          : Colors.blueGrey,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 16.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ...widget.node.inputPins.map(
                (pin) => Positioned(
                  left: padding + pin.relativePosition.dx - 6,
                  top: padding + pin.relativePosition.dy,
                  child: PinWidget(pin: pin),
                ),
              ),
              ...widget.node.inputPins.map(
                (pin) => Positioned(
                  left: padding + 6 + 2,
                  top: padding + pin.relativePosition.dy - 2,
                  child: Text(
                    pin.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ...widget.node.outputPins.map(
                (pin) => Positioned(
                  left: padding + pin.relativePosition.dx - 6,
                  top: padding + pin.relativePosition.dy,
                  child: PinWidget(pin: pin),
                ),
              ),
              ...widget.node.outputPins.map(
                (pin) => Positioned(
                  right: padding + 6 + 2,
                  top: padding + pin.relativePosition.dy - 2,
                  child: Text(
                    pin.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                ),
              ),
              // error text
              if (nodeError != null)
                Positioned(
                  left: padding + 6 + 2,
                  right: padding + 6 + 2,
                  child: Text(
                    nodeError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          );
        });
  }
}
