import 'package:flutter/widgets.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/pin.dart';

class NodeVariable<T> with ChangeNotifier {
  String name;
  ValueNode<T>? _valueNode;
  T? defaultValue;
  InputValuePin<T>? inputPin;
  OutputValuePin<T>? outputPin;

  bool get canBindInputPin =>
      outputPin == null; // can bind input pin if no output pin is bound

  T? get valueOrNull {
    if (_valueNode == null) {
      if (defaultValue != null) {
        return defaultValue!;
      }
      return null;
    }
    return _valueNode!.value;
  }

  T get value {
    var value = valueOrNull;
    return value!;
  }

  void setValueNode(ValueNode<T>? value) {
    if (inputPin != null) {
      throw Exception("Cannot set a value on a bounded variable '$name'!");
    }
    _valueNode = value;
    if (outputPin != null) {
      outputPin!.update(getValueNode());
    }
    notifyListeners();
  }

  ValueNode<T>? getValueNode() {
    if (_valueNode == null) {
      if (defaultValue != null) {
        return ConstValueNode(defaultValue as T);
      }
      return null;
    }
    return _valueNode;
  }

  void bindInputPin(InputValuePin<T>? pin) {
    if (inputPin != null) {
      inputPin!.onValueChanged = null;
      if (_valueNode is! ConstValueNode<T>) {
        // make sure we do not listen to the old value
        _valueNode = null;
      }
    }
    inputPin = pin;
    if (inputPin != null) {
      inputPin!.onValueChanged = (value) {
        _valueNode = value;
      };
    }
    notifyListeners();
  }

  void bindOutputPin(OutputValuePin<T>? pin) {
    if (outputPin != null) {
      outputPin!.update(null);
    }
    outputPin = pin;
    if (outputPin != null) {
      outputPin!.update(getValueNode());
    }
    notifyListeners();
  }

  NodeVariable({
    required this.name,
    ValueNode<T>? value,
    this.defaultValue,
  }) : _valueNode = value;
}

abstract class ValueNode<T> {
  T get value;
  const ValueNode();

  bool isConst() {
    return this is ConstValueNode<T>;
  }

  ConstValueNode<T> asConst() {
    if (this is ConstValueNode<T>) {
      return this as ConstValueNode<T>;
    }
    throw Exception("ValueNode is not const");
  }

  ChangeValueNode<T> asChangeNotifier() {
    if (this is ChangeValueNode<T>) {
      return this as ChangeValueNode<T>;
    }
    throw Exception("ValueNode is not ChangeNotifier");
  }
}

class ChangeValueNode<T> extends ValueNode<T> with ChangeNotifier {
  T? _value;
  @override
  T get value {
    if (_value == null) {
      throw Exception("ValueNode is not initialized");
    }
    return _value!;
  }

  ChangeValueNode(this._value);

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }
}

class ConstValueNode<T> extends ValueNode<T> {
  final T _value;
  @override
  T get value => _value;
  const ConstValueNode(this._value);
}
