import 'package:flutter/material.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/render_data.dart';
import 'package:unreal_editor/models/pin.dart';
import 'package:unreal_editor/models/variable.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

class TextNode extends Node {
  final RenderData _renderData;

  @override
  RenderData get renderData => _renderData;

  NodeVariable<String> text = NodeVariable<String>(name: "Text");

  TextNode({required super.id, required super.position})
      : _renderData = TextRenderData(),
        super(
          title: "Text",
          type: NodeType.static,
        ) {
    addInputPin(
      InputValuePin<String>(
        nodeId: id,
        label: "value",
        onValueChanged: (value) {
          text.setValueNode(value);
          notifyListeners();
        },
      ),
    );
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
