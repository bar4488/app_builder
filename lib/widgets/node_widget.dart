import 'package:flutter/material.dart';
import '../models/node.dart';
import '../models/pin.dart';
import 'pin_widget.dart';

class NodeWidget extends StatelessWidget {
  final Node node;
  final Function(Pin) onPinPressed;
  final Set<String> connectedPinIds;

  const NodeWidget({
    super.key,
    required this.node,
    required this.onPinPressed,
    required this.connectedPinIds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: node.size.width,
      height: node.size.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              node.type,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          ...node.pins.map((pin) {
            return Positioned(
              left: pin.relativePosition.dx -
                  (pin.direction == PinDirection.input ? 6 : -6),
              top: pin.relativePosition.dy - 6,
              child: PinWidget(
                key: pin.key,
                pin: pin,
                onPressed: () => onPinPressed(pin),
                isConnected: connectedPinIds.contains(pin.key.value),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
