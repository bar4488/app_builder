import 'package:app_builder/utils/let.dart';
import 'package:flutter/material.dart';
import 'package:app_builder/models/node.dart';
import 'package:app_builder/models/node_settings.dart';
import 'package:app_builder/models/pin.dart';
import 'package:app_builder/models/variable.dart';

class StringNode extends Node {
  NodeSettigns _settigns;
  @override
  NodeSettigns get settings => _settigns;

  NodeVariable<String> text = NodeVariable<String>(name: "Value");
  late OutputValuePin<String> valuePin;

  StringNode(
      {required super.id, required super.position, required super.blueprint})
      : _settigns = StringNodeSettigns(),
        super(
          title: "String",
          type: NodeKind.static,
        ) {
    valuePin = OutputValuePin<String>(
      nodeId: id,
      label: "value",
    );
    addOutputPin(valuePin);
    text.setOnChanged((value) => valuePin.update(value));
  }

  @override
  String? get description => text.valueOrNull?.let(
        (it) => "String - '$it'",
      );
}

class StringNodeSettigns extends NodeSettigns<StringNode> {
  String? value;
  StringNodeSettigns();

  @override
  Widget buildSettingsWidget(BuildContext context, StringNode node) {
    // build a widget to edit the string value
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
