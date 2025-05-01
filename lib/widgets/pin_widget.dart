import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unreal_editor/state/blueprint_editor_state.dart';
import 'package:unreal_editor/state/blueprint_state.dart';
import '../models/pin.dart';

class PinWidget extends StatelessWidget {
  final Pin pin;

  const PinWidget({
    required this.pin,
    // Use the PinKey for the widget key for stable identification
    super.key, // Key is derived from pin.key in NodeWidget map
  });

  Color _getPinColor(PinType type, bool isConnected, bool isPotentialTarget,
      bool isInvalidTarget) {
    if (isInvalidTarget) return Colors.red;
    if (isPotentialTarget) return Colors.yellow;

    switch (type) {
      case PinType.exec:
        return isConnected ? Colors.green : Colors.green.withValues(alpha: 0.3);
      case PinType.value:
        return isConnected ? Colors.cyan : Colors.cyan.withValues(alpha: 0.3);
      case PinType.render:
        return isConnected
            ? Colors.purple
            : Colors.purple.withValues(alpha: 0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double pinSize = 12.0;
    var editorState = context.read<BlueprintEditorState>();
    var blueprintState = context.read<BlueprintState>();

    // Check if this pin is connected
    bool isConnected = editorState.connections.any(
      (conn) => conn.startPin == pin || conn.endPin == pin,
    );

    // Check if this pin is the potential end target of a drag
    bool isPotentialTarget = editorState.currentHoverPin == pin &&
        editorState.dragStartPin != null &&
        editorState.dragStartPin != pin;
    bool isInvalidTarget = false;
    if (isPotentialTarget) {
      isInvalidTarget = editorState.dragStartPin!.direction == pin.direction ||
          editorState.dragStartPin!.type != pin.type;
    }

    return GestureDetector(
      // Add right click handler
      onSecondaryTapUp: (details) {
        blueprintState.removeConnectionsForPin(pin);
      },
      // --- Connection Drag Handling ---
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        // Get the global position of the center of the pin widget
        var pinPosition = editorState.getPinGlobalPosition(pin)!;
        var mousePosition = pinPosition +
            details.localPosition -
            const Offset(pinSize, pinSize / 2);

        editorState.startDraggingConnection(
          pin,
          pinPosition,
          mousePosition,
          pin.direction,
        );
      },
      onPanUpdate: (details) {
        editorState.updateDraggingConnection(delta: details.delta);
      },
      onPanEnd: (details) {
        editorState.endDraggingConnection();
      },
      child: Tooltip(
        message: "${pin.label} (${pin.direction.name}, ${pin.type.name})",
        child: MouseRegion(
          onEnter: (event) {
            editorState.setHoverPinKey(pin);
          },
          onHover: (event) {
            editorState.setHoverPinKey(pin);
          },
          onExit: (event) {
            editorState.setHoverPinKey(null);
          },
          child: Container(
            width: pinSize,
            height: pinSize,
            decoration: BoxDecoration(
              color: _getPinColor(
                  pin.type, isConnected, isPotentialTarget, isInvalidTarget),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
