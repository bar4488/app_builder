import 'pin.dart';

class Connection {
  final PinKey startPinKey;
  final PinKey endPinKey;

  Connection({
    required this.startPinKey,
    required this.endPinKey,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connection &&
          runtimeType == other.runtimeType &&
          startPinKey == other.startPinKey &&
          endPinKey == other.endPinKey;

  @override
  int get hashCode => Object.hash(startPinKey, endPinKey);
}
