import 'package:flutter/widgets.dart';
import 'package:app_builder/models/pin.dart';
import 'package:runtime_type/runtime_type.dart';

class NodeVariable<T> with ChangeNotifier {
  String name;
  ValueNode<T>? _valueNode;
  T? defaultValue;
  InputValuePin<T>? inputPin;
  void Function(ValueNode<T>? value)? _onChanged;

  final bool _canBindInput;
  bool get canBindInput => _canBindInput;

  RuntimeType<T> get type => RuntimeType<T>();

  T? get constValueOrNull {
    if (_valueNode?.isConst() == true) {
      return _valueNode!.value;
    }
    return defaultValue;
  }

  T? get valueOrNull {
    if (_valueNode == null) {
      if (defaultValue is T) {
        return defaultValue as T;
      }
      return null;
    }
    return _valueNode!.value;
  }

  T get value {
    var value = valueOrNull;
    return value as T;
  }

  void setValueNode(ValueNode<T>? value) {
    if (inputPin != null) {
      throw Exception("Cannot set a value on a bounded variable '$name'!");
    }
    _valueNode = value;
    _onChanged?.call(getValueNode());
    notifyListeners();
  }

  ValueNode<T>? getValueNode() {
    if (_valueNode == null) {
      if (defaultValue is T) {
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

  void setOnChanged(void Function(ValueNode<T>? value)? newOnChanged) {
    _onChanged?.call(null);
    _onChanged = newOnChanged;
    _onChanged?.call(getValueNode());
    notifyListeners();
  }

  NodeVariable({
    required this.name,
    bool canBindInput = true,
    ValueNode<T>? value,
    this.defaultValue,
  })  : _valueNode = value,
        _canBindInput = canBindInput;
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

  ValueNode<R> cast<R>();
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

  @override
  ValueNode<R> cast<R>() {
    ChangeValueNode<R> result = CastChangeValueNode.from(this);
    return result;
  }
}

class CastChangeValueNode<T> extends ChangeValueNode<T> {
  ChangeValueNode _other;
  void listener() {
    value = _other._value as T;
  }

  CastChangeValueNode.from(ChangeValueNode other)
      : _other = other,
        super(other.value) {
    _other.addListener(listener);
  }

  @override
  void dispose() {
    _other.removeListener(listener);
    super.dispose();
  }
}

class ConstValueNode<T> extends ValueNode<T> {
  final T _value;
  @override
  T get value => _value;
  const ConstValueNode(this._value);

  @override
  ValueNode<R> cast<R>() {
    return ConstValueNode(_value as R);
  }
}
