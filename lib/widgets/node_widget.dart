import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import '../models/node.dart';
import 'pin_widget.dart';

class NodeWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Recalculate pin positions if needed (e.g., if size changes, though fixed for now)
    // node.calculatePinPositions(); // Usually called when node created/resized
    var padding = 8;
    var editorState = context.read<BlueprintEditorState>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          alignment: Alignment.center,
          width: node.size.width + padding * 2,
          height: node.size.height + padding * 2,
          // color: Colors.white54,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              // Select node on drag start
              editorState.selectNode(
                node.id,
                multiSelect: false,
              ); // Basic single selection
            },
            onPanUpdate: onDragUpdate,
            onPanEnd: onDragEnd,
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
            left: padding +
                pin.relativePosition.dx -
                6, // Center the pin visually
            top: padding + pin.relativePosition.dy,
            child: PinWidget(pin: pin),
          ),
        ),
        // Input Pins labels:
        ...node.inputPins.map(
          (pin) => Positioned(
            left: padding + 6 + 2, // Center the pin visually
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
        // Output Pins
        ...node.outputPins.map(
          (pin) => Positioned(
            left: padding +
                pin.relativePosition.dx -
                6, // Center the pin visually
            top: padding + pin.relativePosition.dy,
            child: PinWidget(pin: pin),
          ),
        ),
        // Output Pins labels:
        ...node.outputPins.map(
          (pin) => Positioned(
            right: padding + 6 + 2, // Center the pin visually
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
