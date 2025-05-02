import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

class NodeData {}

class NodeRenderException implements Exception {
  final String nodeId;
  final String errorMessage;
  NodeRenderException(this.nodeId, this.errorMessage);

  @override
  String toString() {
    return "NodeRenderException: id: $nodeId, error: $errorMessage";
  }
}

class NodeValueException implements Exception {
  final String nodeId;
  final String errorMessage;
  NodeValueException(this.nodeId, this.errorMessage);

  @override
  String toString() {
    return "NodeValueException: id: $nodeId, error: $errorMessage";
  }
}

abstract class RenderData<T extends Node> {
  RenderData();

  Widget Function() getBuilder(
    BlueprintState state,
    T node,
  );

  Iterable<NodeVariable> getVariables(T node);

  Widget build(BlueprintState state, T node) {
    var variables = getVariables(node);

    // if null, throw exception
    for (var e in variables) {
      if (e.getValueNode() == null) {
        throw NodeValueException(
            node.id, "Variable ${e.name} is not initialized");
      }
    }
    // get all change notifiers
    var listeners = variables
        .map((e) => e.getValueNode()!)
        .whereType<ChangeValueNode>()
        .toList();

    var builder = getBuilder(state, node);
    if (listeners.isEmpty) {
      return builder();
    }

    return ChangeValueWidget(
      listeners: listeners,
      builder: (context) {
        return builder();
      },
    );
  }
}

class NodeVariable<T> with ChangeNotifier {
  String name;
  ValueNode<T>? _valueNode;
  T? defaultValue;
  InputValuePin<T>? inputPin;
  OutputValuePin<T>? outputPin;

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
    if (value == null) {
      throw NodeValueException("something", "NodeVariable is not initialized");
    }
    return value;
  }

  void setValueNode(ValueNode<T>? value) {
    if (inputPin != null) {
      throw Exception("Cannot set a value on a bounded variable '$name'!");
    }
    _valueNode = value;
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

class ViewportRenderData extends RenderData<ViewportNode> {
  ViewportRenderData();

  @override
  Widget Function() getBuilder(
    BlueprintState state,
    ViewportNode node,
  ) {
    var childId = node.childId;
    if (childId == null) {
      throw NodeRenderException(node.id, "child is null");
    }
    var child = state.findNodeById(childId)!;

    Widget childWidget = child.renderData!.build(state, child);
    return () => Center(child: childWidget);
  }

  @override
  Iterable<NodeVariable> getVariables(ViewportNode node) => [];
}

class ColumnRenderData extends RenderData<ColumnNode> {
  ColumnRenderData();

  @override
  Iterable<NodeVariable> getVariables(ColumnNode node) => [
        node.mainAxisAlignment,
        node.crossAxisAlignment,
      ];

  @override
  Widget Function() getBuilder(
    BlueprintState state,
    ColumnNode node,
  ) {
    List<Widget> children = node.children.nonNulls
        .map(
          (e) => state.findNodeById(e)!,
        )
        .map((child) => child.renderData!.build(state, child))
        .toList()
        .cast<Widget>();

    Widget builder() {
      return Builder(builder: (context) {
        return SizedBox.expand(
          child: Column(
            mainAxisAlignment: node.mainAxisAlignment.value,
            crossAxisAlignment: node.crossAxisAlignment.value,
            children: children,
          ),
        );
      });
    }

    return builder;
  }
}

class TextRenderData extends RenderData<TextNode> {
  TextRenderData();

  @override
  Widget Function() getBuilder(
    BlueprintState state,
    TextNode node,
  ) {
    NodeVariable<String> textValue = node.text;

    Widget builder() {
      return Text(textValue.value);
    }

    return builder;
  }

  @override
  Iterable<NodeVariable> getVariables(TextNode node) => [
        node.text,
      ];
}

class ChangeValueWidget extends StatefulWidget {
  final List<ChangeNotifier> listeners;
  final Widget Function(BuildContext) _builder;
  const ChangeValueWidget({
    super.key,
    this.listeners = const [],
    required Widget Function(BuildContext) builder,
  }) : _builder = builder;

  @override
  State<ChangeValueWidget> createState() => _ChangeValueWidgetState();
}

class _ChangeValueWidgetState extends State<ChangeValueWidget> {
  void onChange() {
    setState(() {});
  }

  @override
  void initState() {
    for (var listener in widget.listeners) {
      listener.addListener(onChange);
    }
    super.initState();
  }

  @override
  void dispose() {
    for (var listener in widget.listeners) {
      listener.removeListener(onChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget._builder(context);
  }
}
