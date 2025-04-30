import 'package:flutter/material.dart';
import 'package:unreal_editor/models/connection.dart';

// Enum to define pin direction
enum PinDirection { input, output }

// Add Pin Type enum
enum PinType {
  exec, // Flow control
  value, // Data values
  render, // Visual/render data
}

// Unique key for identifying pins
class PinKey extends ValueKey<String> {
  const PinKey(String value) : super(value);
}

// Represents a connection pin on a node
class Pin {
  final PinKey key;
  final String nodeId;
  final String label;
  final PinDirection direction;
  final PinType type;
  final multi;

  // this is a lazy list, may contain connections that are not in the linked list
  List<Connection> _connections = [];
  Iterable<Connection> get connections =>
      _connections.where((conn) => conn.list != null);
  Offset relativePosition = Offset.zero;

  Pin({
    required this.nodeId,
    required this.label,
    required this.direction,
    required this.type,
    this.multi = false,
  }) : key = PinKey('${nodeId}_${label}_${direction.name}');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pin && runtimeType == other.runtimeType && key == key;

  @override
  int get hashCode => key.hashCode;

  void addConnection(Connection newConn) {
    // if pin is not multi, remove all other connections
    if (!multi) {
      // remove from linked list
      _connections = _connections.where((conn) => conn.list != null).toList();
      _connections.forEach((conn) {
        conn.unlink();
      });
    }
    _connections.add(newConn);
  }
}
