import 'dart:collection';
import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'pin.dart';

// extension for linked list for removeWhere
extension LinkedListExtension<T extends LinkedListEntry<T>> on LinkedList<T> {
  void removeWhere(bool Function(T) test) {
    if (isEmpty) return;
    for (T? node = first, next = node.next; node != null; node = next?.next) {
      if (test(node)) {
        remove(node);
      }
    }
  }

  // reversed iterator, generated on the fly
  Iterable<T> get reversed sync* {
    if (isEmpty) return;
    for (T? node = last; node != null; node = node.previous) {
      yield node;
    }
  }
}

// Represents a connection between two pins
final class Connection extends LinkedListEntry<Connection> {
  final PinKey startPinKey;
  final PinKey endPinKey;
  // Store path for hit testing later if needed
  Path? path;
  List<PathMetric>? pathMetrics;

  Connection({required this.startPinKey, required this.endPinKey});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connection &&
          runtimeType == other.runtimeType &&
          startPinKey == other.startPinKey &&
          endPinKey == other.endPinKey;

  @override
  int get hashCode => startPinKey.hashCode ^ endPinKey.hashCode;
}
