import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import '../models/node.dart';
import 'pin_widget.dart';

class MultiOutputNodeWidget extends StatelessWidget {
  final MultiOutputNode node;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails)? onDragEnd;

  const MultiOutputNodeWidget({
    super.key,
    required this.node,
    required this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    var padding = 8;
    var editorState = context.read<BlueprintEditorState>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          alignment: Alignment.center,
          width: node.size.width + padding * 2,
          height: node.size.height + padding * 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              editorState.selectNode(
                node.id,
                multiSelect: false,
              );
            },
            onPanUpdate: onDragUpdate,
            onPanEnd: onDragEnd,
            onTap: () => editorState.selectNode(node.id, multiSelect: false),
            child: Material(
              elevation: node.isSelected ? 8.0 : 4.0,
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                width: node.size.width,
                height: node.size.height,
                decoration: BoxDecoration(
                  color: node.isSelected
                      ? Colors.blueGrey[700]
                      : Colors.blueGrey[900],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: node.isSelected
                        ? Colors.lightBlueAccent
                        : Colors.grey[700]!,
                    width: node.isSelected ? 2.0 : 1.0,
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
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(7.0),
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
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          node.addOutputRenderPin();
                          editorState.notifyListeners();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent,
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
                  ],
                ),
              ),
            ),
          ),
        ),
        ...node.inputPins.map(
          (pin) => Positioned(
            left: padding + pin.relativePosition.dx - 6,
            top: padding + pin.relativePosition.dy,
            child: PinWidget(pin: pin),
          ),
        ),
        ...node.inputPins.map(
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
        ...node.outputPins.map(
          (pin) => Positioned(
            left: padding + pin.relativePosition.dx - 6,
            top: padding + pin.relativePosition.dy,
            child: PinWidget(pin: pin),
          ),
        ),
        ...node.outputPins.map(
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
      ],
    );
  }
}
