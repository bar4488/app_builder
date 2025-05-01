import 'package:flutter/widgets.dart';
import 'package:unreal_editor/models/node.dart';
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

  Widget buildNodeWidget(
    BlueprintState state,
    T node,
  );
}

class StringValueNode extends NodeData {
  String value;
  StringValueNode(this.value);
}

class TextNodeData extends NodeData {
  String text;
  TextNodeData(this.text);
}

class ViewportNodeData extends NodeData {
  ViewportNodeData();
}

abstract class ValueNode<T> {
  T get value;
  const ValueNode();

  bool isConst() {
    return this is ConstValueNode<T> || this is InvalidValueNode<T>;
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
  T get value => _value;
  const ConstValueNode(this._value);
}

class InvalidValueNode<T> extends ValueNode<T> {
  String nodeId;
  String errorMessage;

  InvalidValueNode(this.nodeId, this.errorMessage);
  @override
  T get value {
    throw NodeValueException(nodeId, errorMessage);
  }
}

class ViewportRenderData extends RenderData<ViewportNode> {
  ViewportRenderData();

  @override
  Widget buildNodeWidget(
    BlueprintState state,
    ViewportNode node,
  ) {
    var childId = node.childId;
    if (childId == null) {
      throw NodeRenderException(node.id, "child is null");
    }
    var child = state.findNodeById(childId)!;

    Widget childWidget = child.renderData!.buildNodeWidget(state, child);
    return Center(child: childWidget);
  }
}

class ColumnRenderData extends RenderData<ColumnNode> {
  ColumnRenderData();

  @override
  Widget buildNodeWidget(
    BlueprintState state,
    ColumnNode node,
  ) {
    List<Widget> children = node.children.nonNulls
        .map(
          (e) => state.findNodeById(e)!,
        )
        .map((child) => child.renderData!.buildNodeWidget(state, child))
        .toList()
        .cast<Widget>();

    ValueNode<MainAxisAlignment> mainAxisAlignment = node.mainAxisAlignment;

    Widget builder(state, {required MainAxisAlignment mainAxisAlignment}) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        children: children,
      );
    }

    List<ChangeNotifier> listeners = [];
    if (!mainAxisAlignment.isConst()) {
      listeners.add(mainAxisAlignment.asChangeNotifier());
    }

    if (listeners.isEmpty) {
      return builder(state, mainAxisAlignment: mainAxisAlignment.value);
    }

    return ChangeValueWidget(
      listeners: listeners,
      builder: (context) {
        return builder(
          state,
          mainAxisAlignment: mainAxisAlignment.value,
        );
      },
    );
  }
}

class TextRenderData extends RenderData<TextNode> {
  TextRenderData();

  @override
  Widget buildNodeWidget(
    BlueprintState state,
    TextNode node,
  ) {
    ValueNode<String> textValue = node.text ?? const ConstValueNode("no text");

    Widget builder(state, {required String text}) {
      return Text(text);
    }

    List<ChangeNotifier> listeners = [];
    if (!textValue.isConst()) {
      listeners.add(textValue.asChangeNotifier());
    }

    if (listeners.isEmpty) {
      return builder(state, text: textValue.value);
    }

    return ChangeValueWidget(
      listeners: listeners,
      builder: (context) {
        return builder(
          state,
          text: textValue.value,
        );
      },
    );
  }
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
