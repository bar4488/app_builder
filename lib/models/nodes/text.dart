import 'package:app_builder/models/pin.dart';
import 'package:app_builder/state/preview_state.dart';
import 'package:app_builder/utils/let.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/render_data.dart';
import 'package:app_builder/models/variable.dart';
import 'package:runtime_type/runtime_type.dart';

class TextNode extends Node {
  @override
  final RenderData renderData = TextRenderData();

  @override
  final NodeSettigns settings = TextNodeSettigns();

  NodeVariable<String> text = NodeVariable<String>(name: "Text");

  TextNode(
      {required super.id, required super.position, required super.blueprint})
      : super(
          title: "Text",
          hasRenderInput: true,
          type: NodeKind.static,
        );

  @override
  InputValuePin? getInputValuePin(RuntimeType type) {
    if (type == String) {
      return bindInputVariable<String>(text);
    }
    return super.getInputValuePin(type);
  }

  @override
  Iterable<NodeVariable> getVariables() => [
        text,
      ];

  @override
  String? get description =>
      text.constValueOrNull.let((text) => "Text - '$text'");
}

class TextRenderData extends RenderData<TextNode> {
  TextRenderData();

  @override
  Widget Function() getBuilder(
    PreviewState state,
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
