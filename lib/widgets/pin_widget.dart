import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import '../models/pin.dart';

class PinWidget extends StatelessWidget {
  final Pin pin;

  const PinWidget({
    required this.pin,
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
    var editorState = context.read<BlueprintEditorState>();

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
          final RenderBox stackRenderBox = editorState
                  .findNodeById(pin.nodeId)!
                  .isSelected // Hacky way to get stack context, improve this
              ? context.findAncestorRenderObjectOfType<RenderBox>()!
              : context.findAncestorRenderObjectOfType<
                  RenderBox>()!; // Find the main Stack's RenderBox

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
}
