import 'package:flutter/material.dart';
import 'package:app_builder/models/connection.dart';
import 'package:app_builder/models/variable.dart';

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
  final bool multi;

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
      other is Pin && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;

  void onConnectionChanged() {}

  void addConnection(Connection newConn) {
    // if pin is not multi, remove all other connections
    if (!multi) {
      // remove from linked list
      _connections = _connections.where((conn) => conn.list != null).toList();
      _connections.forEach((conn) {
        conn.unlink();
        conn.startPin.onConnectionChanged();
        conn.endPin.onConnectionChanged();
      });
    }
    _connections.add(newConn);
  }
}

class InputRenderPin extends Pin {
  InputRenderPin({
    required String nodeId,
    required String label,
    required PinDirection direction,
  }) : super(
            nodeId: nodeId,
            label: label,
            direction: direction,
            type: PinType.render,
            multi: true);
}

class OutputRenderPin extends Pin {
  void Function(String? nodeId) onRenderTargetChanged;

  OutputRenderPin({
    required String nodeId,
    required String label,
    required this.onRenderTargetChanged,
  }) : super(
          nodeId: nodeId,
          label: label,
          direction: PinDirection.output,
          type: PinType.render,
        );

  @override
  void onConnectionChanged() {
    // Notify the value node of the new value
    onRenderTargetChanged(connections.firstOrNull?.endPin.nodeId);
  }
}

class OutputValuePin<T> extends Pin {
  // void Function(InputValuePin input)? onValueChanged;

  ValueNode<T>? _value;
  Type get valueType => T;

  OutputValuePin({
    required String nodeId,
    required String label,
  }) : super(
          nodeId: nodeId,
          label: label,
          direction: PinDirection.output,
          multi: true,
          type: PinType.value,
        );

  void update(ValueNode<T>? value) {
    _value = value;
    // Notify the input nodes
    for (var conn in connections) {
      if (conn.endPin is InputValuePin<T>) {
        (conn.endPin as InputValuePin<T>).onValueChanged!(value);
      }
    }
  }

  ValueNode<T>? get value {
    return _value;
  }

  // @override
  // void onConnectionChanged() {
  //   // Notify the value node of the new value
  //   if (onValueChanged != null) {
  //     onValueChanged!(connections.firstOrNull?.endPin as InputValuePin);
  //   }
  // }
}

class InputValuePin<T> extends Pin {
  void Function(ValueNode<T>? newVal)? onValueChanged;
  Type get valueType => T;

  InputValuePin({
    required String nodeId,
    required String label,
    this.onValueChanged,
  }) : super(
          nodeId: nodeId,
          label: label,
          direction: PinDirection.input,
          multi: false,
          type: PinType.value,
        );

  @override
  void onConnectionChanged() {
    // Notify the value node of the new value
    if (onValueChanged != null) {
      onValueChanged!(
          (connections.firstOrNull?.startPin as OutputValuePin<T>?)?.value);
    }
  }

  Stream<String> getValueStream() {
    // Placeholder for actual stream logic

    return Stream<String>.periodic(
      const Duration(seconds: 1),
      (count) => "Value from $label: $count",
    );
  }
}
