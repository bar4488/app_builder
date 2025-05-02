import 'package:flutter/material.dart';
import 'package:unreal_editor/models/node.dart';
import 'package:unreal_editor/models/node_settigns.dart';
import 'package:unreal_editor/models/render_data.dart';
import 'package:unreal_editor/models/variable.dart';
import 'package:unreal_editor/state/blueprint_state.dart';

class TextNode extends Node {
  @override
  final RenderData renderData = TextRenderData();

  @override
  final NodeSettigns settings = TextNodeSettigns();

  NodeVariable<String> text = NodeVariable<String>(name: "Text");

  TextNode({required super.id, required super.position})
      : super(
          title: "Text",
          hasRenderInput: true,
          type: NodeKind.static,
        );

  @override
  Iterable<NodeVariable> getVariables() => [
        text,
      ];
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
}

class TextNodeSettigns extends NodeSettigns<TextNode> {
  @override
  Widget buildSettingsWidget(BuildContext context, TextNode node) {
    return ListView(
      children: [
        StringValueEditor(
          node: node,
          variable: node.text,
        ),
      ],
    );
  }
}
