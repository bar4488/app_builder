import 'package:flutter/material.dart';
import '../models/pin.dart';

class PinWidget extends StatelessWidget {
  final Pin pin;
  final VoidCallback? onPressed;
  final bool isConnected;

  const PinWidget({
    super.key,
    required this.pin,
    this.onPressed,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPinColor();

    return GestureDetector(
      onTapDown: (_) => onPressed?.call(),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: isConnected ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Color _getPinColor() {
    switch (pin.type) {
      case PinType.exec:
        return Colors.white;
      case PinType.value:
        return Colors.blue;
      case PinType.render:
        return Colors.green;
    }
  }
}
